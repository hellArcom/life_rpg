import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import '../../services/server_service.dart';
import 'dart:io' as io;

class GdprScreen extends ConsumerStatefulWidget {
  const GdprScreen({super.key});

  @override
  ConsumerState<GdprScreen> createState() => _GdprScreenState();
}

class _GdprScreenState extends ConsumerState<GdprScreen> {
  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.gdpr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(t.changePassword),
          _buildFeatureCard(
            context,
            t.changePassword,
            Icons.lock_outline,
            Colors.orange,
            () => _showChangePasswordDialog(context, t),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            t.changeEmail,
            Icons.email_outlined,
            Colors.blue,
            () => _showChangeEmailDialog(context, t),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            t.changeUsername,
            Icons.person_outline,
            Colors.teal,
            () => _showChangeUsernameDialog(context, t),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(t.exportMyData),
          _buildFeatureCard(
            context,
            t.exportMyDataDesc,
            Icons.download,
            Colors.green,
            () => _exportServerData(context, t),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            context,
            t.readableDataDesc,
            Icons.article_outlined,
            Colors.cyan,
            () => _exportReadableData(context, t),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(t.legalDocuments),
          _buildFeatureCard(
            context,
            t.legalDocumentsDesc,
            Icons.gavel,
            Colors.indigo,
            () => _showLegalDocuments(context, t),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(t.deleteMyData),
          _buildFeatureCard(
            context,
            t.deleteMyDataDesc,
            Icons.delete_forever,
            Colors.red,
            () => _showDeleteDataDialog(context, t),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(subtitle, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, Translations t) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.changePassword),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.currentPassword),
                validator: (v) => (v == null || v.isEmpty) ? t.passwordRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.newPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return t.passwordRequired;
                  if (v.length < 8) return t.passwordMin8;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.confirmNewPassword),
                validator: (v) {
                  if (v != newController.text) return t.passwordMismatch;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final res = await ServerService.updatePassword(
                currentPassword: currentController.text,
                newPassword: newController.text,
              );
              if (mounted) {
                if (res != null && res['message'] != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.passwordUpdated)),
                  );
                } else {
                  final err = res?['error'];
                  final msg = err is Map ? (err['message']?.toString() ?? t.error) : (err?.toString() ?? t.error);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              }
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, Translations t) {
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.changeEmail),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password),
                validator: (v) => (v == null || v.isEmpty) ? t.passwordRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: t.newEmail),
                validator: (v) {
                  if (v == null || v.isEmpty) return t.passwordRequired;
                  if (!v.contains('@')) return t.error;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final res = await ServerService.updateEmail(
                password: passwordController.text,
                newEmail: emailController.text,
              );
              if (mounted) {
                if (res != null && res['message'] != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.emailUpdated)),
                  );
                } else {
                  final err = res?['error'];
                  final msg = err is Map ? (err['message']?.toString() ?? t.error) : (err?.toString() ?? t.error);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              }
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  void _showChangeUsernameDialog(BuildContext context, Translations t) {
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.changeUsername),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password),
                validator: (v) => (v == null || v.isEmpty) ? t.passwordRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: t.newUsername),
                validator: (v) {
                  if (v == null || v.isEmpty) return t.passwordRequired;
                  if (v.length < 3) return t.error;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final res = await ServerService.updateUsername(
                password: passwordController.text,
                newUsername: usernameController.text,
              );
              if (mounted) {
                if (res != null && res['message'] != null) {
                  final game = ref.read(gameProvider.notifier);
                  game.updatePseudo(usernameController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.usernameUpdated)),
                  );
                } else {
                  final err = res?['error'];
                  final msg = err is Map ? (err['message']?.toString() ?? t.error) : (err?.toString() ?? t.error);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }
              }
            },
            child: Text(t.save),
          ),
        ],
      ),
    );
  }

  Future<void> _exportServerData(BuildContext context, Translations t) async {
    final res = await ServerService.exportUserData();
    if (!mounted) return;
    if (res != null && !res.containsKey('error')) {
      final jsonData = const JsonEncoder.withIndent('  ').convert(res);
      await _shareJsonData(context, jsonData, 'liferpg_server_data.json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.dataExported)),
        );
      }
    } else {
      if (mounted) {
                  final err = res?['error'];
                  final msg = err is Map ? (err['message']?.toString() ?? t.error) : (err?.toString() ?? t.error);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
      }
    }
  }

  void _exportReadableData(BuildContext context, Translations t) {
    final game = ref.read(gameProvider.notifier);
    final data = game.exportReadableData();
    _shareJsonData(context, data, 'liferpg_my_data.json');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.dataExported)),
    );
  }

  Future<void> _shareJsonData(BuildContext context, String jsonData, String filename) async {
    if (kIsWeb) {
      await Share.share(jsonData, subject: 'Life RPG - Mes données');
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$filename';
        final file = io.File(path);
        await file.writeAsString(jsonData);
        await Share.shareXFiles([XFile(path)], text: 'Life RPG - Mes données');
      } catch (e) {
        debugPrint('Export error: $e');
      }
    }
  }

  void _showLegalDocuments(BuildContext context, Translations t) {
    _loadAndShowLocalLegal(context, t);
  }

  Future<void> _loadAndShowLocalLegal(BuildContext context, Translations t) async {
    String? content;
    try {
      content = await rootBundle.loadString('assets/CGU.md');
    } catch (_) {}
    if (content == null) {
      try {
        final file = io.File('CGU.md');
        if (await file.exists()) {
          content = await file.readAsString();
        }
      } catch (_) {}
    }
    if (content != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LegalDocumentScreen(
            title: t.legalDocuments,
            content: content!,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document légal introuvable')),
      );
    }
  }

  void _showDeleteDataDialog(BuildContext context, Translations t) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.deleteDataConfirm),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.deleteDataWarning,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(t.deleteDataConfirmMsg),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: t.password),
                validator: (v) => (v == null || v.isEmpty) ? t.passwordRequired : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context);
              final game = ref.read(gameProvider.notifier);
              final success = await game.deleteAllUserData(
                password: passwordController.text,
              );
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.dataDeleted)),
                );
                Navigator.pop(context);
              }
            },
            child: Text(t.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const _LegalDocumentScreen({required this.title, required this.content});

  List<String> _parseSections(String md) {
    final sections = <String>[];
    final lines = md.split('\n');
    final buffer = StringBuffer();
    for (final line in lines) {
      if (line.startsWith('## ') && buffer.isNotEmpty) {
        sections.add(buffer.toString());
        buffer.clear();
      }
      buffer.writeln(line);
    }
    if (buffer.isNotEmpty) sections.add(buffer.toString());
    return sections;
  }

  String _renderMarkdownLine(String line) {
    line = line.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1)!);
    line = line.replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) => m.group(1)!);
    return line;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parseSections(content);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: sections.length > 1
              ? TabBar(
                  isScrollable: true,
                  tabs: sections.map((s) {
                    final firstTitle = s.split('\n').firstWhere(
                      (l) => l.startsWith('## ') || l.startsWith('# '),
                      orElse: () => '',
                    ).replaceFirst(RegExp(r'^#+\s*'), '');
                    return Tab(text: firstTitle.isNotEmpty ? firstTitle : 'Section');
                  }).toList(),
                )
              : null,
        ),
        body: sections.length > 1
            ? TabBarView(
                children: sections.map((section) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(section, theme),
                  );
                }).toList(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContent(content, theme),
              ),
      ),
    );
  }

  Widget _buildContent(String text, ThemeData theme) {
    final widgets = <Widget>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            _renderMarkdownLine(trimmed.substring(4)),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            _renderMarkdownLine(trimmed.substring(3)),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text(
            _renderMarkdownLine(trimmed.substring(2)),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      } else if (trimmed.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(_renderMarkdownLine(trimmed.substring(2)))),
            ],
          ),
        ));
      } else if (trimmed.startsWith('---')) {
        widgets.add(const Divider(height: 24));
      } else if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 4));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Text(_renderMarkdownLine(trimmed)),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
