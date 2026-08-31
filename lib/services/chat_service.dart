import 'dart:async';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'server_service.dart';

class ChatService {
  static IO.Socket? _socket;
  static String? _currentRoom;
  static String? _encryptionKey;
  static String? _pendingJoinRoom;
  static bool _connecting = false;
  static Timer? _retryTimer;
  static int _retryCount = 0;
  static const int _maxRetries = 10;
  static final List<void Function(Map<String, dynamic>)> _onMessageCallbacks = [];
  static final List<void Function(Map<String, dynamic>)> _onHistoryCallbacks = [];
  static final List<void Function(Map<String, dynamic>)> _onDeleteCallbacks = [];
  static final List<void Function(String)> _onErrorCallbacks = [];
  static void Function()? _onDecryptionFailure;

  static void onMessage(void Function(Map<String, dynamic>) cb) => _onMessageCallbacks.add(cb);
  static void onHistory(void Function(Map<String, dynamic>) cb) => _onHistoryCallbacks.add(cb);
  static void onDeleteMessage(void Function(Map<String, dynamic>) cb) => _onDeleteCallbacks.add(cb);
  static void onChatError(void Function(String) cb) => _onErrorCallbacks.add(cb);
  static void onDecryptionFailure(void Function() cb) => _onDecryptionFailure = cb;

  static void _cleanupSocket() {
    debugPrint('ChatService: cleaning up socket');
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  static void _scheduleReconnect() {
    if (_retryCount >= _maxRetries) {
      debugPrint('ChatService: max retries ($_maxRetries) reached, giving up');
      return;
    }
    _retryTimer?.cancel();
    _retryCount++;
    final delay = Duration(seconds: (2 * _retryCount).clamp(2, 30));
    debugPrint('ChatService: scheduling reconnect attempt $_retryCount/$_maxRetries in ${delay.inSeconds}s');
    _retryTimer = Timer(delay, () {
      connect();
    });
  }

  static Future<void> connect() async {
    if (_socket?.connected == true) {
      debugPrint('ChatService: already connected');
      return;
    }
    if (_connecting) {
      debugPrint('ChatService: connection already in progress');
      return;
    }
    _connecting = true;
    _retryCount = 0;

    final deviceId = await ServerService.ensureDeviceId();
    final url = '${ServerService.baseUrl}?device_id=$deviceId';
    debugPrint('ChatService: connecting to $url');

    _cleanupSocket();
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) {
      _connecting = false;
      _retryCount = 0;
      _retryTimer?.cancel();
      _retryTimer = null;
      debugPrint('ChatService: connected, pendingJoinRoom=$_pendingJoinRoom');
      if (_pendingJoinRoom != null) {
        debugPrint('ChatService: emitting join for $_pendingJoinRoom');
        _socket!.emit('join', {'room': _pendingJoinRoom});
        _pendingJoinRoom = null;
      } else {
        debugPrint('ChatService: no pending join room');
      }
    });
    _socket!.onDisconnect((_) {
      debugPrint('ChatService: disconnected');
      if (_currentRoom != null) {
        _pendingJoinRoom = _currentRoom;
      }
      _scheduleReconnect();
    });
    _socket!.onConnectError((_) {
      _connecting = false;
      debugPrint('ChatService: connection error');
      if (_currentRoom != null) {
        _pendingJoinRoom = _currentRoom;
      }
      _scheduleReconnect();
    });

    _socket!.on('message', (data) {
      debugPrint('ChatService: onMessage received, data type: ${data.runtimeType}');
      if (data is Map) {
        final msg = Map<String, dynamic>.from(data);
        final room = msg['room'] as String?;
        debugPrint('ChatService: message room=$room, currentRoom=$_currentRoom, hasEncryptionKey=${_encryptionKey != null}');
        if (_currentRoom != null && _currentRoom == room && _encryptionKey != null && msg['content'] is String) {
          final content = msg['content'] as String;
          if (content.startsWith('enc:v1:')) {
            final decrypted = decryptMessage(content.substring(7), _encryptionKey!);
            // Detect decryption failure (returns original encrypted string)
            if (decrypted == content.substring(7)) {
              debugPrint('ChatService: decryption failed, triggering key refresh');
              _onDecryptionFailure?.call();
            }
            msg['content'] = decrypted;
            debugPrint('ChatService: message decrypted');
          }
        } else if (_currentRoom != null && _currentRoom == room && msg['content'] is String && (msg['content'] as String).startsWith('enc:v1:') && _encryptionKey == null) {
          debugPrint('ChatService: WARNING - encrypted message received but _encryptionKey is null, cannot decrypt');
        }
        for (final cb in _onMessageCallbacks) {
          try { cb(msg); } catch (e) { debugPrint('ChatService: onMessage callback error: $e'); }
        }
      }
    });

    _socket!.on('history', (data) {
      debugPrint('ChatService: onHistory received, data type: ${data.runtimeType}, isList: ${data is List}');
      if (data is List) {
        final decrypted = <Map<String, dynamic>>[];
        for (final item in data) {
          if (item is Map) {
            final msg = Map<String, dynamic>.from(item);
            final room = msg['room'] as String?;
            if (_currentRoom == room && _encryptionKey != null && msg['content'] is String) {
              final content = msg['content'] as String;
              if (content.startsWith('enc:v1:')) {
                final dec = decryptMessage(content.substring(7), _encryptionKey!);
                if (dec == content.substring(7)) {
                  debugPrint('ChatService: history decryption failed, triggering key refresh');
                  _onDecryptionFailure?.call();
                }
                msg['content'] = dec;
              }
            } else if (_currentRoom == room && msg['content'] is String && (msg['content'] as String).startsWith('enc:v1:') && _encryptionKey == null) {
              debugPrint('ChatService: WARNING - encrypted message in history but _encryptionKey is null, cannot decrypt');
            }
            decrypted.add(msg);
          }
        }
        debugPrint('ChatService: history decrypted ${decrypted.length} messages');
        for (final cb in _onHistoryCallbacks) {
          try { cb({'messages': decrypted}); } catch (e) { debugPrint('ChatService: onHistory callback error: $e'); }
        }
      }
    });

    _socket!.on('message_deleted', (data) {
      if (data is Map) {
        for (final cb in _onDeleteCallbacks) {
          try { cb(Map<String, dynamic>.from(data)); } catch (e) { debugPrint('ChatService: onDelete callback error: $e'); }
        }
      }
    });

    _socket!.on('chat_error', (data) {
      if (data is Map && data['message'] != null) {
        for (final cb in _onErrorCallbacks) {
          try { cb(data['message']); } catch (e) { debugPrint('ChatService: onError callback error: $e'); }
        }
      }
    });

    _socket!.connect();
  }

  static Future<void> joinGuildRoom(String guildId, {String? encryptionKey}) async {
    debugPrint('ChatService.joinGuildRoom: guildId=$guildId, isConnected=$isConnected, connecting=$_connecting, hasEncryptionKey=${encryptionKey != null}');
    if (!isConnected) await connect();
    _encryptionKey = encryptionKey;
    _currentRoom = 'guild_$guildId';
    // If already connected, emit join immediately
    if (_socket?.connected == true) {
      debugPrint('ChatService.joinGuildRoom: socket connected, emitting join for $_currentRoom');
      _socket!.emit('join', {'room': _currentRoom});
    } else {
      // Otherwise, join will be emitted in the onConnect handler
      debugPrint('ChatService.joinGuildRoom: socket not connected, setting _pendingJoinRoom=$_currentRoom');
      _pendingJoinRoom = _currentRoom;
    }
  }

  static void leaveCurrentRoom() {
    _currentRoom = null;
    _encryptionKey = null;
  }

  static bool get isConnected => _socket?.connected == true;

  static bool sendMessage(String content) {
    if (_currentRoom == null) {
      debugPrint('ChatService.sendMessage: failed - _currentRoom is null');
      return false;
    }
    if (!isConnected) {
      debugPrint('ChatService.sendMessage: failed - socket not connected (isConnected=false)');
      return false;
    }
    if (_socket == null) {
      debugPrint('ChatService.sendMessage: failed - _socket is null');
      return false;
    }
    // Race condition guard: don't send if join is still pending
    if (_pendingJoinRoom != null) {
      debugPrint('ChatService.sendMessage: failed - join still pending for $_pendingJoinRoom');
      return false;
    }
    String toSend = content;
    if (_encryptionKey != null && _currentRoom!.startsWith('guild_')) {
      toSend = 'enc:v1:${encryptMessage(content, _encryptionKey!)}';
    }
    debugPrint('ChatService.sendMessage: sending to $_currentRoom: ${toSend.substring(0, toSend.length > 50 ? 50 : toSend.length)}...');
    _socket!.emit('message', {'content': toSend, 'room': _currentRoom});
    return true;
  }

  static void deleteMessage(int messageId) {
    if (_currentRoom == null || !isConnected) return;
    _socket!.emit('delete_message', {'message_id': messageId, 'room': _currentRoom});
  }

  static String encryptMessage(String plaintext, String hexKey) {
    try {
      final keyBytes = _hexToBytes(hexKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromSecureRandom(12);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
      combined.setRange(0, iv.bytes.length, iv.bytes);
      combined.setRange(iv.bytes.length, combined.length, encrypted.bytes);
      return base64Encode(combined);
    } catch (e) {
      debugPrint('ChatService encrypt error: $e');
      return plaintext;
    }
  }

  static String decryptMessage(String encBase64, String hexKey) {
    try {
      final combined = base64Decode(encBase64);
      // Valid encrypted message: IV (12 bytes) + ciphertext (>=16 bytes for auth tag)
      if (combined.length < 28) {
        debugPrint('ChatService decrypt: data too short (${combined.length} bytes), returning original');
        return encBase64;
      }
      final keyBytes = _hexToBytes(hexKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV(combined.sublist(0, 12));
      final ciphertext = combined.sublist(12);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      return encrypter.decrypt(encrypt.Encrypted(ciphertext), iv: iv);
    } catch (e) {
      debugPrint('ChatService decrypt error: $e');
      return encBase64;
    }
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}