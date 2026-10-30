import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/translations.dart';
import '../../providers/game_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/chat_service.dart';
import '../../services/server_service.dart';

const _officialLifeRpgServer = 'https://liferpg.dpdns.org';

Future<bool> enableOnlineServices(BuildContext context, WidgetRef ref) async {
  if (ServerService.onlineServicesEnabled && ServerService.baseUrl != null) {
    return true;
  }

  final t = ref.read(translationsProvider);
  final settings = ref.read(settingsProvider);
  final controller = TextEditingController(
    text: ServerService.isValidServerUrl(settings.serverUrl)
        ? settings.serverUrl
        : _officialLifeRpgServer,
  );
  final formKey = GlobalKey<FormState>();
  final serverUrl = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.cloud_sync_outlined, size: 36),
      title: Text(t.onlineServices),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.onlineServicesConsent),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: t.serverUrl,
                helperText: t.onlineServicesServerHint,
              ),
              validator: (value) => value != null && ServerService.isValidServerUrl(value)
                  ? null
                  : t.invalidServerUrl,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(t.cancel),
        ),
        FilledButton.icon(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          icon: const Icon(Icons.cloud_done_outlined),
          label: Text(t.enableOnlineServices),
        ),
      ],
    ),
  );
  controller.dispose();
  if (serverUrl == null || !context.mounted) return false;

  final settingsNotifier = ref.read(settingsProvider.notifier);
  await settingsNotifier.setServerUrl(serverUrl);
  await settingsNotifier.setOnlineServicesEnabled(true);
  await ServerService.resetServerRegistration();
  ref.read(gameProvider.notifier).setOnlineServicesDisabled();
  ChatService.disconnect();
  ref.invalidate(serverStatusProvider);
  final status = await ServerService.healthCheck();
  if (status == null) {
    await settingsNotifier.setOnlineServicesEnabled(false);
    ref.invalidate(serverStatusProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.onlineServicesNotReady)),
      );
    }
    return false;
  }
  if (!context.mounted) return false;
  await ref.read(gameProvider.notifier).syncWithServer();
  return context.mounted;
}

class OnlineServicesNotice extends ConsumerWidget {
  const OnlineServicesNotice({
    super.key,
    required this.onEnabled,
    this.title,
    this.description,
  });

  final Future<void> Function() onEnabled;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final settings = ref.watch(settingsProvider);
    if (settings.onlineServicesEnabled && ServerService.baseUrl != null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              title ?? t.onlineServicesNeeded,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description ?? t.onlineServicesConsent,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final enabled = await enableOnlineServices(context, ref);
                if (enabled && context.mounted) await onEnabled();
              },
              icon: const Icon(Icons.cloud_sync_outlined),
              label: Text(t.configureAndEnableOnlineServices),
            ),
          ],
        ),
      ),
    );
  }
}
