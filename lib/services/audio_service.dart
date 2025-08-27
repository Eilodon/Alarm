import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  final _player = AudioPlayer();
  final _record = Record();

  Future<void> playUrl(String url) async {
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  Future<bool> hasMicPermission() async {
    return await _record.hasPermission();
  }

  Future<String?> startRecording() async {
    if (!await _record.hasPermission()) return null;
    await _record.start(
      encoder: AudioEncoder.wav, // PCM 16-bit WAV
      bitRate: 128000,
      samplingRate: 16000,
    );
    return await _record.getFilePath();
  }

  Future<String?> stopRecording() async {
    return await _record.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
