import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class FFmpegThumbHelper {
  static const String ffmpegPath = r'C:\path\ffmpeg\bin\ffmpeg.exe';

  static String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Gera uma thumb PNG do frame do meio do vídeo [videoPath].
  /// Retorna o caminho do arquivo da thumb.
  static Future<String?> getThumb(String videoPath, String? quality) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) return null;

      var fileName = p.basenameWithoutExtension(file.path);
      var dirName = p.basenameWithoutExtension(file.parent.path);

      final tempDirPath = "${Directory.systemTemp.path}\\media_collector_thumb\\$dirName\\$fileName";
      final tempDir = Directory(tempDirPath);
      if (!await tempDir.exists()) tempDir.createSync(recursive: true);
      final thumbPath = p.join(tempDir.path, '${p.basenameWithoutExtension(videoPath)}_${quality}_thumb.png');

      // Se já existe, retorna
      if (await File(thumbPath).exists()) {
        debugPrint('Já existe a thumb: $thumbPath');
        return thumbPath;
      }
      // Pega duração do vídeo (em segundos)
      final durationResult = await Process.run(ffmpegPath.replaceAll('ffmpeg.exe', 'ffprobe.exe'), [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'default=noprint_wrappers=1:nokey=1',
        videoPath,
      ]);
      double duration = double.tryParse(durationResult.stdout.toString().trim()) ?? 0;
      final midSeconds = (duration / 2).floor();
      final midTime = _formatDuration(midSeconds);

      var scale = 180;
      if (quality != null && quality != "medium") {
        if (quality == "high") scale = 300;
        if (quality == "low") scale = 100;
      }

      // Gera thumb
      final result = await Process.run(ffmpegPath, [
        '-ss', midTime,
        '-i', videoPath,
        '-frames:v', '1',
        '-vf', 'scale=$scale:-1:flags=lanczos', // Aumenta resolução e usa melhor algoritmo de scaling
        '-q:v', '2', // Qualidade JPEG (2-31, sendo 2 o melhor)
        '-y', thumbPath,
      ]);
      if (result.exitCode == 0 && await File(thumbPath).exists()) {
        return thumbPath;
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao gerar thumb: $e');
      return null;
    }
  }
}
