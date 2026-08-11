import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';

class EveningEntryScreen extends ConsumerStatefulWidget {
  final bool autoFocus;
  const EveningEntryScreen({super.key, this.autoFocus = false});

  @override
  ConsumerState<EveningEntryScreen> createState() => _EveningEntryScreenState();
}

class _EveningEntryScreenState extends ConsumerState<EveningEntryScreen> {
  final _controller = TextEditingController();
  String _selectedMood = '😊';
  bool _submitted = false;

  final List<String> _moods = ['😊', '😐', '😢', '😤', '🥱'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final notifier = ref.read(gameProvider.notifier);
    final submitted = _submitted || !notifier.canSubmitEveningEntry();

    return Scaffold(
      appBar: AppBar(title: Text(t.eveningEntryTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.eveningEntrySubtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            Text(t.howAreYou, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moods.map((m) => GestureDetector(
                onTap: submitted ? null : () => setState(() => _selectedMood = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedMood == m ? Colors.amber.withValues(alpha: 0.2) : null,
                    borderRadius: BorderRadius.circular(12),
                    border: _selectedMood == m ? Border.all(color: Colors.amber) : null,
                  ),
                  child: Text(m, style: const TextStyle(fontSize: 32)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Text(t.whatYouDid, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              enabled: !submitted,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: t.eveningHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (submitted || _controller.text.trim().isEmpty)
                    ? null
                    : () {
                        notifier.submitEveningEntry(_controller.text.trim(), _selectedMood);
                        setState(() => _submitted = true);
                      },
                icon: Icon(submitted ? Icons.check : Icons.send),
                label: Text(submitted ? t.eveningDone : t.eveningSubmit),
              ),
            ),
            if (submitted)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(t.eveningAlreadyDone, style: const TextStyle(color: Colors.green)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
