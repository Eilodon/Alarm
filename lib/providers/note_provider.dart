import 'package:flutter/foundation.dart';
import '../db/app_database.dart';
import '../models/note.dart';
import '../services/notification_service.dart';

class NoteProvider extends ChangeNotifier {
  DateTime _selectedDay = DateTime.now();
  List<Note> _notes = [];

  DateTime get selectedDay => _selectedDay;
  List<Note> get notes => _notes;

  Future<void> loadForDay(DateTime day) async {
    _selectedDay = DateTime(day.year, day.month, day.day);
    _notes = await AppDatabase.instance.getNotesForDay(_selectedDay);
    notifyListeners();
  }

  Future<void> add(Note note) async {
    final id = await AppDatabase.instance.insertNote(note);
    final withId = note.copyWith(id: id);
    await _schedule(withId);
    await loadForDay(_selectedDay);
  }

  Future<void> update(Note note) async {
    await AppDatabase.instance.updateNote(note);
    if (note.id != null) {
      await NotificationService.instance.cancel(note.id!);
      await _schedule(note);
    }
    await loadForDay(_selectedDay);
  }

  Future<void> remove(Note note) async {
    if (note.id != null) {
      await NotificationService.instance.cancel(note.id!);
      await AppDatabase.instance.deleteNote(note.id!);
      await loadForDay(_selectedDay);
    }
  }

  Future<void> _schedule(Note n) async {
    if (n.id == null) return;
    if (n.scheduledAt.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleNotification(
        id: n.id!,
        title: n.title,
        body: n.content,
        scheduledAt: n.scheduledAt,
      );
    }
  }
}
