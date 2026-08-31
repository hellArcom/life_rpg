import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import '../../services/server_service.dart';
import '../../services/notification_service.dart';

class AccountLinkScreen extends ConsumerStatefulWidget {
  const AccountLinkScreen({super.key});

  @override
  ConsumerState<AccountLinkScreen> createState() => _AccountLinkScreenState();
}

class _AccountLinkScreenState extends ConsumerState<AccountLinkScreen> {
  bool _loading = true;
  bool _linked = false;
  String? _lastSyncAt;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    final status = await ServerService.getSyncStatus();
    if (mounted && status != null) {
      setState(() {
        _linked = status['linked'] == true;
        _lastSyncAt = status['last_sync_at'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.accountSync)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 24),
                if (_linked) ...[
                  _buildSyncSection(),
                  const SizedBox(height: 16),
                  _buildUnlinkButton(),
                ] else ...[
                  _buildLinkOrCreateSection(),
                ],
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    final t = ref.watch(translationsProvider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _linked ? Icons.cloud_done : Icons.cloud_off,
              size: 64,
              color: _linked ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _linked ? t.accountLinked : t.noAccountLinked,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _linked
                  ? t.dataSyncedServer
                  : t.linkAccountHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_linked && _lastSyncAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '${t.lastSync} : $_lastSyncAt',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSection() {
    final t = ref.watch(translationsProvider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.synchronization, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              label: Text(_syncing ? t.syncing : t.syncNow),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlinkButton() {
    final t = ref.watch(translationsProvider);
    return OutlinedButton.icon(
      onPressed: _unlinkAccount,
      icon: const Icon(Icons.link_off, color: Colors.redAccent),
      label: Text(t.unlinkAccount, style: const TextStyle(color: Colors.redAccent)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.redAccent),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildLinkOrCreateSection() {
    final t = ref.watch(translationsProvider);
    return Column(
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.linkExistingAccount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(t.linkExistingHint),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showLinkDialog(context),
                  icon: const Icon(Icons.link),
                  label: Text(t.linkMyAccount),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.createNewAccount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(t.createAccountHint),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showCreateAccountDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: Text(t.createAccount),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLinkDialog(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.linkYourAccount),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: t.email, border: const OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: t.password, border: const OutlineInputBorder()),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setDialogState(() => loading = true);
                final res = await ServerService.linkAccount(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res != null && res['message'] != null) {
                  NotificationService.showFeedback(t.success, res['message']);
                  _loadStatus();
                  ref.read(gameProvider.notifier).checkAccountLinkStatus();
                  _checkAndShowMergeDialog();
                } else {
                  final errorMsg = res?['error'];
                  final msg = (errorMsg is Map ? errorMsg['message'] : errorMsg) ?? t.cannotSync;
                  NotificationService.showFeedback(t.error, msg);
                }
              },
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.link),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAccountDialog(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.createAccount),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: t.email, border: const OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: t.username, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: t.passwordMin, border: const OutlineInputBorder()),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setDialogState(() => loading = true);
                final res = await ServerService.registerAccount(
                  email: emailController.text.trim(),
                  username: usernameController.text.trim(),
                  password: passwordController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                if (res != null && res['message'] != null) {
                  NotificationService.showFeedback(t.success, res['message']);
                  _loadStatus();
                  ref.read(gameProvider.notifier).checkAccountLinkStatus();
                  _checkAndShowMergeDialog();
                } else {
                  final errorMsg = res?['error'];
                  final msg = (errorMsg is Map ? errorMsg['message'] : errorMsg) ?? t.cannotSync;
                  NotificationService.showFeedback(t.error, msg);
                }
              },
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(t.createAccount),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    final t = ref.watch(translationsProvider);

    // Demander le mot de passe pour le chiffrement E2E
    final password = await _showPasswordDialog(t.e2ePasswordTitle, t.e2ePasswordMsg);
    if (password == null || password.isEmpty) {
      return; // Annulé
    }
    
    setState(() => _syncing = true);
    final notifier = ref.read(gameProvider.notifier);
    final gameState = ref.read(gameProvider);
    final user = gameState.user;
    final localData = {
      'level': user.level,
      'globalXp': user.globalXp,
      'coins': user.coins,
      'streak': user.streak,
      'badgeIds': user.badgeIds,
      'total_quests_completed': gameState.quests.where((q) => q.status.name == 'completed').length,
    };
    final res = await ServerService.syncData(localData, password: password);
    if (!mounted) return;
    setState(() => _syncing = false);
    
    // Déchiffrer la réponse si nécessaire
    final serverData = ServerService.decryptSyncResponse(res ?? {}, password);
    if (serverData != null) {
      final serverLevel = serverData['level'] as int? ?? user.level;
      final serverXp = serverData['globalXp'] as int? ?? user.globalXp;
      final serverCoins = serverData['coins'] as int? ?? user.coins;
      final serverStreak = serverData['streak'] as int? ?? user.streak;
      final merged = Map<String, dynamic>.from(gameState.toJson());
      merged['user']['level'] = serverLevel > user.level ? serverLevel : user.level;
      merged['user']['globalXp'] = serverXp > user.globalXp ? serverXp : user.globalXp;
      merged['user']['coins'] = serverCoins > user.coins ? serverCoins : user.coins;
      merged['user']['streak'] = serverStreak > user.streak ? serverStreak : user.streak;
      notifier.importData(jsonEncode(merged));
      NotificationService.showFeedback(t.synced, t.dataUpdatedE2E);
      _loadStatus();
    } else if (res != null && res['data'] != null) {
      // Fallback : réponse non chiffrée
      final data = res['data'] as Map<String, dynamic>;
      final serverLevel = data['level'] as int? ?? user.level;
      final serverXp = data['globalXp'] as int? ?? user.globalXp;
      final serverCoins = data['coins'] as int? ?? user.coins;
      final serverStreak = data['streak'] as int? ?? user.streak;
      final merged = Map<String, dynamic>.from(gameState.toJson());
      merged['user']['level'] = serverLevel > user.level ? serverLevel : user.level;
      merged['user']['globalXp'] = serverXp > user.globalXp ? serverXp : user.globalXp;
      merged['user']['coins'] = serverCoins > user.coins ? serverCoins : user.coins;
      merged['user']['streak'] = serverStreak > user.streak ? serverStreak : user.streak;
      notifier.importData(jsonEncode(merged));
      NotificationService.showFeedback(t.synced, t.dataUpdated);
      _loadStatus();
    } else {
      NotificationService.showFeedback(t.error, t.cannotSync);
    }
  }

  Future<String?> _showPasswordDialog(String title, String message) async {
    final t = ref.watch(translationsProvider);
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t.password,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(t.confirm),
          ),
        ],
      ),
    );
  }

  bool _hasLocalData() {
    final gameState = ref.read(gameProvider);
    final user = gameState.user;
    return user.level > 1 || user.globalXp > 0 || user.coins > 0;
  }

  void _checkAndShowMergeDialog() {
    final t = ref.watch(translationsProvider);
    if (!_hasLocalData()) return;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.sync_problem, size: 48, color: Colors.orange),
        title: Text(t.localDataDetected),
        content: Text(
          t.localDataMsg,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(gameProvider.notifier).syncWithServer(mode: 'pull');
              NotificationService.showFeedback(t.synced, 'Données serveur appliquées');
            },
            child: Text(t.replaceByServer),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(gameProvider.notifier).syncWithServer(mode: 'push');
              NotificationService.showFeedback(t.synced, 'Vos données ont été envoyées');
            },
            child: Text(t.sendToServer),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(gameProvider.notifier).syncWithServer(mode: 'merge');
              NotificationService.showFeedback(t.synced, 'Données fusionnées');
            },
            child: Text(t.mergeSum),
          ),
        ],
      ),
    );
  }

  Future<void> _unlinkAccount() async {
    final t = ref.watch(translationsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.unlinkAccountConfirm),
        content: Text(t.unlinkAccountMsg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.unlink),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await ServerService.unlinkAccount();
    if (!mounted) return;
    if (res != null && res['message'] != null) {
      NotificationService.showFeedback(t.success, res['message']);
      _loadStatus();
    } else {
      NotificationService.showFeedback(t.error, res?['error'] ?? t.error);
    }
  }
}
