import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/note_provider.dart';
import 'edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CalendarFormat _format = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final p = context.read<NoteProvider>();
    p.loadForDay(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<NoteProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes + Lịch + Nhắc'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            selectedDayPredicate: (d) =>
                d.year == p.selectedDay.year &&
                d.month == p.selectedDay.month &&
                d.day == p.selectedDay.day,
            onDaySelected: (selected, focused) {
              _focusedDay = focused;
              p.loadForDay(selected);
            },
            onFormatChanged: (f) => setState(() => _format = f),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: p.notes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = p.notes[i];
                return ListTile(
                  title: Text(n.title),
                  subtitle: Text(
                      '${n.scheduledAt.hour.toString().padLeft(2, '0')}:${n.scheduledAt.minute.toString().padLeft(2, '0')}  •  ${n.content}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => p.remove(n),
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditNoteScreen(note: n),
                      ),
                    );
                    await p.loadForDay(p.selectedDay);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EditNoteScreen(),
            ),
          );
          await p.loadForDay(p.selectedDay);
        },
        label: const Text('Thêm ghi chú'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
