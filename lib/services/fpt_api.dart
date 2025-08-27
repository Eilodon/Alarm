import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;

class FptApi {
  static final FptApi instance = FptApi._();
  FptApi._();

  // Lấy từ --dart-define=FPT_API_KEY=...
  static const String _apiKey =
      String.fromEnvironment('FPT_API_KEY', defaultValue: '');

  // Voices gợi ý: "banmai", "lannhi", "myan", "giahuy", "leminh"
  Future<String> ttsGetAudioUrl({
    required String text,
    String voice = 'banmai',
    int speed = 0, // -3..3
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('FPT_API_KEY chưa được cấu hình');
    }
    final uri = Uri.parse('https://api.fpt.ai/hmi/tts/v5');
    final resp = await http.post(
      uri,
      headers: {
        'api-key': _apiKey,
        'speed': speed.toString(),
        'voice': voice,
        'content-type': 'text/plain; charset=utf-8',
      },
      body: utf8.encode(text),
    );

    if (resp.statusCode != 200) {
      throw Exception('TTS request failed: ${resp.statusCode} ${resp.body}');
    }

    // Response thường dạng JSON: {"async":"https://.../output.mp3"}
    final data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final asyncUrl = data['async'] as String?;
    if (asyncUrl == null) {
      throw Exception('TTS response missing async URL');
    }

    // Đơn giản: trả URL (audioplayers sẽ stream khi sẵn)
    return asyncUrl;
  }

  Future<String> sttTranscribeFile(String filePath) async {
    if (_apiKey.isEmpty) {
      throw Exception('FPT_API_KEY chưa được cấu hình');
    }

    final uri = Uri.parse('https://api.fpt.ai/hmi/asr/general');
    final req = http.MultipartRequest('POST', uri);
    req.headers['api-key'] = _apiKey;
    req.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType('audio', 'wav'),
    ));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('STT failed: ${resp.statusCode} ${resp.body}');
    }

    final data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final text = (data['text'] ??
            (data['hypotheses'] is List && data['hypotheses'].isNotEmpty
                ? data['hypotheses'][0]['utterance']
                : null)) as String?;
    if (text == null) {
      throw Exception('STT response missing text');
    }
    return text;
  }
}
