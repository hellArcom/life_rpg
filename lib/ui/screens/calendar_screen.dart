import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart' hide isSameDay;
import 'package:intl/intl.dart';
import '../../core/utils.dart';
import '../../models/game_models.dart';
import '../../providers/game_provider.dart';
import '../../core/translations.dart';
import '../widgets/add_quest_dialog.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Object> _getEventsForDay(DateTime day, List<Quest> quests, List<Bet> bets) {
    final events = <Object>[];
    
    // Quests scheduled or due on this day
    for (final quest in quests) {
      if (quest.dueDate != null && isSameDay(quest.dueDate, day)) {
        events.add(quest);
      } else if (quest.startTime != null && isSameDay(quest.startTime, day)) {
        events.add(quest);
      }
    }

    // Bets due on this day
    for (final bet in bets) {
      if (isSameDay(bet.deadline, day)) {
        events.add(bet);
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final quests = ref.watch(gameProvider.select((s) => s.quests));
    final bets = ref.watch(gameProvider.select((s) => s.bets));

    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay, quests, bets);
    // Sort events by time
    selectedEvents.sort((a, b) {
      DateTime? getTime(Object e) {
        if (e is Quest) return e.startTime ?? e.dueDate;
        if (e is Bet) return e.deadline;
        return null;
      }
      final timeA = getTime(a);
      final timeB = getTime(b);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(t.calendarPlanning),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddQuestDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() => _calendarFormat = format);
              }
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            eventLoader: (day) => _getEventsForDay(day, quests, bets),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.cyan,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(child: Text(t.noEvents))
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = selectedEvents[index];
                      if (event is Quest) {
                        return _buildQuestTile(event, t, key: ValueKey('quest_${event.id}'));
                      } else if (event is Bet) {
                        return _buildBetTile(event, t, key: ValueKey('bet_${event.id}'));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTile(Quest quest, Translations t, {Key? key}) {
    final timeStr = quest.startTime != null 
        ? "${DateFormat('HH:mm').format(quest.startTime!)} - ${quest.dueDate != null ? DateFormat('HH:mm').format(quest.dueDate!) : '...'}"
        : (quest.dueDate != null ? "Échéance: ${DateFormat('HH:mm').format(quest.dueDate!)}" : t.allDay);

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          quest.status == QuestStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: quest.status == QuestStatus.completed ? Colors.green : Colors.grey,
        ),
        title: Text(quest.title, style: TextStyle(
          decoration: quest.status == QuestStatus.completed ? TextDecoration.lineThrough : null,
        )),
        subtitle: Text("$timeStr\n${t.translateCategory(quest.category.label)}"),
        isThreeLine: true,
        trailing: Text("+${quest.xpRewardValue} XP", style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
        onTap: () => ref.read(gameProvider.notifier).toggleQuestStatus(quest.id),
        onLongPress: () => showAddQuestDialog(context, ref, existingQuest: quest),
      ),
    );
  }

  Widget _buildBetTile(Bet bet, Translations t, {Key? key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.amber.withValues(alpha: 0.1),
      child: ListTile(
        leading: const Icon(Icons.casino, color: Colors.amber),
        title: Text("${t.betLabel}: ${bet.title}"),
        subtitle: Text("Échéance: ${DateFormat('HH:mm').format(bet.deadline)}"),
        trailing: Text("${bet.rewardXp} XP", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
