import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../services/fpt_api.dart';
import '../services/audio_service.dart';

class EditNoteScreen extends StatefulWidget {
  final Note? note;
  const EditNoteScreen({super.key, this.note});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime _scheduleAt = DateTime.now().add(const Duration(minutes: 5));
  String _voice = 'banmai';
  bool _recording = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    if (n != null) {
      _titleCtrl.text = n.title;
      _contentCtrl.text = n.content;
      _scheduleAt = n.scheduledAt;
      _voice = n.ttsVoice ?? 'banmai';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: _scheduleAt,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduleAt),
    );
    if (time == null) return;
    setState(() {
      _scheduleAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final p = context.read<NoteProvider>();
    final n = Note(
      id: widget.note?.id,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      scheduledAt: _scheduleAt,
      ttsVoice: _voice,
    );
    if (n.id == null) {
      await p.add(n);
    } else {
      await p.update(n);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _playTts() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      final url = await FptApi.instance.ttsGetAudioUrl(text: text, voice: _voice);
      await AudioService.instance.playUrl(url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS lỗi: $e')),
      );
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await AudioService.instance.stopRecording();
      setState(() {
        _recording = false;
        _recordPath = path;
      });
      if (path != null) {
        try {
          final text = await FptApi.instance.sttTranscribeFile(path);
          setState(() {
            final cur = _contentCtrl.text;
            _contentCtrl.text = cur.isEmpty ? text : '$cur $text';
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('STT lỗi: $e')),
          );
        }
      }
    } else {
      final ok = await AudioService.instance.hasMicPermission();
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa cấp quyền micro')),
        );
        return;
      }
      await AudioService.instance.startRecording();
      setState(() => _recording = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voices = const ['banmai', 'lannhi', 'myan', 'giahuy', 'leminh'];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Tạo ghi chú' : 'Sửa ghi chú'),
        actions: [
          IconButton(
            onPressed: _playTts,
            icon: const Icon(Icons.volume_up),
            tooltip: 'Đọc ghi chú (FPT TTS)',
          ),
          IconButton(
            onPressed: _toggleRecord,
            icon: Icon(_recording ? Icons.stop_circle : Icons.mic),
            tooltip: 'Ghi âm (FPT STT)',
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Lưu & nhắc lịch',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _voice,
            items: voices
                .map((v) => DropdownMenuItem(value: v, child: Text('Giọng: $v')))
                .toList(),
            onChanged: (v) => setState(() => _voice = v ?? 'banmai'),
            decoration: const InputDecoration(
              labelText: 'Chọn giọng TTS',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Nội dung ghi chú',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Thời gian nhắc'),
            subtitle: Text(_scheduleAt.toString()),
            trailing: ElevatedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule),
              label: const Text('Chọn'),
            ),
          ),
          if (_recordPath != null)
            Text('File ghi âm: $_recordPath', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
