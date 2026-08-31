import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/translations.dart';
import '../../providers/game_provider.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _sending = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).ensureReferralCode();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    final t = ref.watch(translationsProvider);
    final code = ref.read(gameProvider.notifier).ensureReferralCode();
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.copied)),
      );
    }
  }

  Future<void> _share() async {
    final t = ref.watch(translationsProvider);
    final code = ref.read(gameProvider.notifier).ensureReferralCode();
    await Share.share(
      '${t.referralShare}$code\nhttps://github.com/hellArcom/Life-RPG-release',
      subject: t.referralShareSubject,
    );
  }

  Future<void> _submit() async {
    final notifier = ref.read(gameProvider.notifier);
    setState(() {
      _sending = true;
      _result = null;
    });
    final status = await notifier.submitReferral(_codeController.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(gameProvider).user;
    final myCode = user.referralCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.referral)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Mon code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  t.myReferralCode,
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  myCode,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _copyCode,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(t.copy),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: Text(t.share),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Explication des récompenses
          Text(t.howReferralWorks, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _rewardRow(
            Icons.monetization_on,
            t.referrerReward,
            '+${GameNotifier.referrerRewardCoins}💰 / ${GameNotifier.referrerRewardFreezeDays}j ${t.freezeDays} / +${GameNotifier.referrerRewardXp} XP',
          ),
          const SizedBox(height: 8),
          _rewardRow(
            Icons.person_add,
            t.refereeReward,
            '+${GameNotifier.refereeRewardCoins}💰 / +${GameNotifier.refereeRewardXp} XP',
          ),

          const SizedBox(height: 24),

          // Entrer un code
          if (user.referralSubmitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.referralAlreadyUsed,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: t.enterReferralCode,
                hintText: 'ABC234X',
                prefixIcon: const Icon(Icons.card_giftcard),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.validate),
            ),
            const SizedBox(height: 12),
            if (_result == null)
              Text(
                t.referralOfflineHint,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              )
            else if (_result == 'ok')
              _resultBanner(Icons.check_circle, Colors.green, t.referralOk)
            else if (_result == 'self')
              _resultBanner(Icons.info, theme.colorScheme.primary, t.referralSelf)
            else if (_result == 'already')
              _resultBanner(Icons.info, Colors.amber, t.referralAlreadyUsed)
            else if (_result == 'invalid')
              _resultBanner(Icons.error, Colors.red, t.referralInvalid)
            else
              const SizedBox.shrink(), // 'offline' → aucun message
          ],
        ],
      ),
    );
  }

  Widget _rewardRow(IconData icon, String title, String detail) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(detail, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBanner(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}