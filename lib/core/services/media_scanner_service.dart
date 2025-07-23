import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/media_item.dart';

class MediaScannerService {
  static const List<String> _videoExtensions = [
    '.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.3gp'
  ];

  Future<List<MediaItem>> scanDirectory(String directoryPath) async {
    final List<MediaItem> mediaItems = [];
    final Directory directory = Directory(directoryPath);

    if (!await directory.exists()) {
      throw Exception('Diretório não encontrado: $directoryPath');
    }

    await _scanDirectoryRecursively(directory, mediaItems);
    return mediaItems;
  }

  Future<void> _scanDirectoryRecursively(Directory directory, List<MediaItem> mediaItems) async {
    try {
      await for (final FileSystemEntity entity in directory.list(recursive: false)) {
        if (entity is File) {
          final MediaItem? mediaItem = _processFile(entity);
          if (mediaItem != null) {
            mediaItems.add(mediaItem);
          }
        } else if (entity is Directory) {
          await _scanDirectoryRecursively(entity, mediaItems);
        }
      }
    } catch (e) {
      print('Erro ao escanear diretório ${directory.path}: $e');
    }
  }

  MediaItem? _processFile(File file) {
    final String extension = path.extension(file.path).toLowerCase();
    
    if (!_videoExtensions.contains(extension)) {
      return null;
    }

    final String fileName = path.basename(file.path);
    final String fileNameWithoutExtension = path.basenameWithoutExtension(file.path);
    
    // Tentar extrair informações do nome do arquivo
    final MediaInfo mediaInfo = _extractMediaInfo(fileNameWithoutExtension);
    
    return MediaItem(
      id: _generateId(file.path),
      title: mediaInfo.title,
      filePath: file.path,
      fileName: fileName,
      type: mediaInfo.type,
      seriesName: mediaInfo.seriesName,
      seasonNumber: mediaInfo.seasonNumber,
      episodeNumber: mediaInfo.episodeNumber,
      year: mediaInfo.year,
      quality: mediaInfo.quality,
      language: mediaInfo.language,
      lastModified: file.lastModifiedSync(),
      fileSize: file.lengthSync(),
    );
  }

  MediaInfo _extractMediaInfo(String fileName) {
    // Padrões comuns para nomes de arquivos de mídia
    final patterns = [
      // Série: Nome.S01E02.Qualidade.Idioma
      RegExp(r'^(.+?)\.S(\d{1,2})E(\d{1,2})\.(.+?)(?:\.(.+))?$', caseSensitive: false),
      // Série: Nome 1x02.Qualidade.Idioma
      RegExp(r'^(.+?)\s+(\d{1,2})x(\d{1,2})\.(.+?)(?:\.(.+))?$', caseSensitive: false),
      // Filme: Nome (Ano).Qualidade.Idioma
      RegExp(r'^(.+?)\s*\((\d{4})\)\.(.+?)(?:\.(.+))?$', caseSensitive: false),
      // Filme: Nome.Ano.Qualidade.Idioma
      RegExp(r'^(.+?)\.(\d{4})\.(.+?)(?:\.(.+))?$', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fileName);
      if (match != null) {
        if (match.groupCount >= 3 && match.group(2)!.length <= 2) {
          // Padrão de série
          return MediaInfo(
            title: match.group(1)!.trim(),
            type: MediaType.series,
            seriesName: match.group(1)!.trim(),
            seasonNumber: int.tryParse(match.group(2)!),
            episodeNumber: int.tryParse(match.group(3)!),
            quality: match.group(4),
            language: match.group(5),
          );
        } else if (match.groupCount >= 2) {
          // Padrão de filme
          return MediaInfo(
            title: match.group(1)!.trim(),
            type: MediaType.movie,
            year: match.group(2),
            quality: match.group(3),
            language: match.group(4),
          );
        }
      }
    }

    // Fallback: tratar como filme com nome simples
    return MediaInfo(
      title: fileName.trim(),
      type: MediaType.movie,
    );
  }

  String _generateId(String filePath) {
    // Gerar ID único baseado no caminho do arquivo
    return filePath.hashCode.toString();
  }
}

class MediaInfo {
  final String title;
  final MediaType type;
  final String? seriesName;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? year;
  final String? quality;
  final String? language;

  MediaInfo({
    required this.title,
    required this.type,
    this.seriesName,
    this.seasonNumber,
    this.episodeNumber,
    this.year,
    this.quality,
    this.language,
  });
} 