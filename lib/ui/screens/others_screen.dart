import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import 'settings_screen.dart';
import 'referral_screen.dart';


import 'dart:io' as io;

class OthersScreen extends ConsumerStatefulWidget {
  const OthersScreen({super.key});

  @override
  ConsumerState<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends ConsumerState<OthersScreen> {
  Future<void> _exportData() async {
    final game = ref.read(gameProvider.notifier);
    final data = game.exportData();
    
    if (kIsWeb) {
      await Share.share(data, subject: 'Ma sauvegarde Life RPG');
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/life_rpg_backup.json';
        final file = io.File(path);
        await file.writeAsString(data);
        await Share.shareXFiles([XFile(path)], text: 'Ma sauvegarde Life RPG');
      } catch (e) {
        debugPrint('Export error: $e');
      }
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
        
    if (result != null) {
      try {
        String content;
        if (kIsWeb) {
          content = utf8.decode(result.files.single.bytes!);
        } else {
          final file = io.File(result.files.single.path!);
          content = await file.readAsString();
        }
        
        ref.read(gameProvider.notifier).importData(content);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Données importées !')));
        }
      } catch (e) {
        debugPrint('Import error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur lors de l\'importation')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.others.toUpperCase())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            context,
            t.focusMode,
            t.focusModeDesc,
            Icons.timer_off,
            Colors.cyan,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const FocusModeScreen())),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            t.backup,
            t.backupDesc,
            Icons.import_export,
            Colors.amber,
            () => _showBackupDialog(context, t),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            t.referral,
            t.referralDesc,
            Icons.group_add,
            Colors.pink,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ReferralScreen())),
          ),
          const SizedBox(height: 16),
          _buildFeatureCard(
            context,
            t.settings,
            t.settingsDesc,
            Icons.settings,
            Colors.grey,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, Translations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.backup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.upload),
                title: Text(t.export),
                onTap: () {
                  Navigator.pop(context);
                  _exportData();
                }),
            ListTile(
                leading: const Icon(Icons.download),
                title: Text(t.import),
                onTap: () {
                  Navigator.pop(context);
                  _importData();
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, String desc,
      IconData icon, Color color, VoidCallback? onTap) {
    return Card(
      child: ListTile(
        onTap: onTap,
        enabled: onTap != null,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key});

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen>
    with WidgetsBindingObserver {
  int _selectedMinutes = 5;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isActive = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isActive && state != AppLifecycleState.resumed) {
      _failSession();
    }
  }

  void _startSession() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isActive = true;
      _hasFailed = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _completeSession() {
    _timer?.cancel();
    final mins = _selectedMinutes;
    ref.read(gameProvider.notifier).addFocusXp(mins);

    setState(() {
      _isActive = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('RÉUSSITE !'),
        content: Text(
            'Félicitations, vous êtes resté concentré pendant $mins minutes.\n\nVous gagnez +${mins * 5} XP !'),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context), child: const Text('SUPER')),
        ],
      ),
    );
  }

  void _failSession() {
    if (!_isActive) return;
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _hasFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.withValues(alpha: 0.1),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isActive) ...[
              const Icon(Icons.self_improvement, size: 80, color: Colors.cyan),
              const SizedBox(height: 24),
              const Text('MODE CONCENTRATION',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                child: Text(
                  'Si vous quittez cette application avant la fin du temps, vous perdez la session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 12,
                children: [5, 10, 20, 30, 60]
                    .map((m) => ChoiceChip(
                          label: Text('$m min'),
                          selected: _selectedMinutes == m,
                          onSelected: (val) => setState(() => _selectedMinutes = m),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 40),
              if (_hasFailed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text('ÉCHEC : Vous avez quitté l\'écran !',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: _startSession,
                child: const Text('COMMENCER',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('RETOUR', style: TextStyle(color: Colors.white54))),
            ] else ...[
              const Text('RESTEZ CONCENTRÉ',
                  style: TextStyle(
                      letterSpacing: 4,
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Text(
                '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.w100,
                    color: Colors.white,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.cyan, strokeWidth: 2),
              const SizedBox(height: 80),
              const Text('Ne quittez pas l\'application...',
                  style:
                      TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _failSession();
                },
                child:
                    const Text('ABANDONNER', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
