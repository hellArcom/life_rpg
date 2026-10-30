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
  static List<String> _encryptionKeys = [];
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
    // Use header auth preferentially; query param kept for legacy compatibility but not logged
    final url = ServerService.baseUrl;
    debugPrint('ChatService: connecting to $url');

    _cleanupSocket();
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'X-Device-ID': deviceId},
      'auth': {'device_id': deviceId},
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
        if (_currentRoom != null && _currentRoom == room && msg['content'] is String) {
          final content = msg['content'] as String;
          if (content.startsWith('enc:v1:')) {
            final payload = content.substring(7);
            final candidates = [if (_encryptionKey != null) _encryptionKey!, ..._encryptionKeys];
            final decrypted = candidates.isEmpty ? null : decryptWithAvailableKeys(payload, candidates);
            if (decrypted == null) {
              debugPrint('ChatService: decryption failed (keys=${candidates.length}), triggering key refresh');
              _onDecryptionFailure?.call();
              msg['content'] = candidates.isEmpty
                  ? '[Message chiffré — clé indisponible]'
                  : '[Message chiffré — déchiffrement impossible]';
            } else {
              msg['content'] = decrypted;
            }
          }
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
            if (_currentRoom == room && msg['content'] is String) {
              final content = msg['content'] as String;
              if (content.startsWith('enc:v1:')) {
                final payload = content.substring(7);
                final candidates = [if (_encryptionKey != null) _encryptionKey!, ..._encryptionKeys];
                final decrypted = candidates.isEmpty ? null : decryptWithAvailableKeys(payload, candidates);
                if (decrypted == null) {
                  debugPrint('ChatService: history decryption failed (keys=${candidates.length}), triggering key refresh');
                  _onDecryptionFailure?.call();
                  msg['content'] = candidates.isEmpty
                      ? '[Message chiffré — clé indisponible]'
                      : '[Message chiffré — déchiffrement impossible]';
                } else {
                  msg['content'] = decrypted;
                }
              }
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

  static String? decryptWithAvailableKeys(String payload, Iterable<String> keys) {
    for (final key in keys.toSet()) {
      final decrypted = decryptMessage(payload, key);
      if (decrypted != payload) return decrypted;
    }
    return null;
  }

  static Future<void> joinGuildRoom(
    String guildId, {
    String? encryptionKey,
    List<String> encryptionKeys = const [],
  }) async {
    debugPrint('ChatService.joinGuildRoom: guildId=$guildId, isConnected=$isConnected, connecting=$_connecting, hasEncryptionKey=${encryptionKey != null}');
    if (!isConnected) await connect();
    _encryptionKey = encryptionKey;
    _encryptionKeys = [
      ...encryptionKeys,
      if (encryptionKey != null) encryptionKey,
    ].where((key) => RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(key)).toSet().toList();
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
    _encryptionKeys = [];
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
      final key = encrypt.Key(Uint8List.fromList(_hexToBytes(hexKey)));
      final iv = encrypt.IV.fromSecureRandom(12);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      // Shared web/mobile wire format: enc:v1:<base64 IV>:<base64 ciphertext+tag>.
      return '${base64Encode(iv.bytes)}:${base64Encode(encrypted.bytes)}';
    } catch (e) {
      debugPrint('ChatService encrypt error: $e');
      rethrow;
    }
  }

  static String decryptMessage(String payload, String hexKey) {
    try {
      final key = encrypt.Key(Uint8List.fromList(_hexToBytes(hexKey)));
      late final encrypt.IV iv;
      late final List<int> ciphertext;
      if (payload.contains(':')) {
        // Current browser format separates the 12-byte IV and authenticated data.
        final parts = payload.split(':');
        if (parts.length != 2) throw const FormatException('Invalid encrypted message');
        iv = encrypt.IV(base64Decode(parts[0]));
        ciphertext = base64Decode(parts[1]);
      } else {
        // Previous mobile releases stored IV + ciphertext together in one base64 value.
        final combined = base64Decode(payload);
        if (combined.length < 28) throw const FormatException('Encrypted message is too short');
        iv = encrypt.IV(combined.sublist(0, 12));
        ciphertext = combined.sublist(12);
      }
      if (iv.bytes.length != 12 || ciphertext.length < 16) {
        throw const FormatException('Invalid AES-GCM message size');
      }
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
      return encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(ciphertext)), iv: iv);
    } catch (e) {
      debugPrint('ChatService decrypt error: $e');
      return payload;
    }
  }

  static List<int> _hexToBytes(String hex) {
    if (hex.length != 64 || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hex)) {
      throw const FormatException('Guild key must be 32-byte hexadecimal');
    }
    return [for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)];
  }
}