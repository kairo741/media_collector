import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;

import '../models/media_item.dart';

class MediaScannerService {
  static const List<String> _videoExtensions = [
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.3gp',
  ];

  Future<List<MediaItem>> scanDirectory(String directoryPath) async {
    final List<MediaItem> mediaItems = [];
    final Directory directory = Directory(directoryPath);

    if (!await directory.exists()) {
      throw Exception('Diretório não encontrado: $directoryPath');
    }

    await _scanDirectory(directory, mediaItems);
    return mediaItems;
  }

  /// Escaneia uma pasta de série e retorna todos os episódios organizados
  Future<List<MediaItem>> scanSeriesEpisodes(String seriesDirPath, String seriesName) async {
    final dir = Directory(seriesDirPath);
    if (!await dir.exists()) return [];
    
    final List<MediaItem> episodes = [];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = path.extension(entity.path).toLowerCase();
        if (!_videoExtensions.contains(ext)) continue;
        
        final fileName = path.basename(entity.path);
        final fileNameNoExt = path.basenameWithoutExtension(entity.path);
        final info = _extractEpisodeInfo(fileNameNoExt, entity.path);
        
        episodes.add(MediaItem(
          id: entity.path.hashCode.toString(),
          title: info.title,
          filePath: entity.path,
          fileName: fileName,
          type: MediaType.series,
          seriesName: seriesName,
          seasonNumber: info.seasonNumber,
          episodeNumber: info.episodeNumber,
          year: null,
          quality: null,
          language: null,
          lastModified: await entity.lastModified(),
          fileSize: await entity.length(),
        ));
      }
    }
    return episodes;
  }

  /// Extrai informações de temporada e episódio do nome do arquivo
  _EpisodeInfo _extractEpisodeInfo(String fileName, String filePath) {
    // Padrões para identificar temporada e episódio
    final patterns = [
      RegExp(r'^(.+?)[ ._-]+S(\d{1,2})E(\d{1,2})', caseSensitive: false),
      RegExp(r'^(.+?)[ ._-]+(\d{1,2})x(\d{1,2})', caseSensitive: false),
      RegExp(r'^(.+?)[ ._-]+T(\d{1,2})E(\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(fileName);
      if (match != null) {
        return _EpisodeInfo(
          title: match.group(1)?.replaceAll('.', ' ')?.trim() ?? fileName,
          seasonNumber: int.tryParse(match.group(2) ?? ''),
          episodeNumber: int.tryParse(match.group(3) ?? ''),
        );
      }
    }
    
    // Tentar extrair temporada do nome da pasta
    final parentDir = path.basename(path.dirname(filePath));
    final seasonMatch = RegExp(r'(?:temporada|season)[ _-]?(\d{1,2})', caseSensitive: false).firstMatch(parentDir);
    int? season;
    if (seasonMatch != null) {
      season = int.tryParse(seasonMatch.group(1)!);
    }
    
    return _EpisodeInfo(
      title: fileName,
      seasonNumber: season,
      episodeNumber: null,
    );
  }

  Future<void> _scanDirectory(Directory directory, List<MediaItem> mediaItems) async {
    try {
      await for (final FileSystemEntity entity in directory.list(recursive: false)) {
        if (entity is File) {
          final MediaItem? mediaItem = _processFile(entity);
          if (mediaItem != null) {
            print("Media: ${mediaItem.displayTitle}");
            mediaItems.add(mediaItem);
          }
        } else if (entity is Directory) {
          final MediaItem? mediaItem = await _processSubDirs(entity, mediaItems);
          if (mediaItem != null) {
            print("Dir: ${mediaItem.displayTitle}");
            mediaItems.add(mediaItem);
          }
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
    final MediaInfo mediaInfo = _extractMediaInfo(fileNameWithoutExtension, MediaType.movie);

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

  Future<MediaItem?> _processSubDirs(Directory dir, List<MediaItem> mediaItems) async {
    final String fileName = path.basename(dir.path);
    var contentList = <String>[];
    await _hasMediaContent(dir, contentList);

    if (contentList.isEmpty) return null;

    final mediaType = contentList.length > 1 ? MediaType.series : MediaType.movie;

    // Tentar extrair informações do nome do arquivo
    final MediaInfo mediaInfo = MediaInfo(
      title: fileName.replaceAll(".", " "),
      type: MediaType.series,
      seriesName: fileName,
      seasonNumber: 1,
      episodeNumber: 1,
      quality: "match.group(4)",
      language: "match.group(5)",
    );
    Random random = new Random();
    int randomNumber = random.nextInt(100);
    return MediaItem(
      id: _generateId(dir.path),
      title: mediaInfo.title,
      filePath: mediaType == MediaType.movie ? contentList.first : dir.path,
      fileName: fileName,
      type: mediaType,
      seriesName: mediaInfo.seriesName,
      seasonNumber: mediaInfo.seasonNumber,
      episodeNumber: mediaInfo.episodeNumber,
      year: mediaInfo.year,
      quality: mediaInfo.quality,
      language: mediaInfo.language,
      lastModified: DateTime.now(),
      fileSize: 10,
      posterUrl: "https://picsum.photos/200/300?random=${randomNumber}",
    );
  }

  Future<void> _hasMediaContent(Directory directory, List<String> contentList) async {
    await for (final FileSystemEntity entity in directory.list(recursive: true)) {
      if (entity is File) {
        final MediaItem? mediaItem = _processFile(entity);
        if (mediaItem != null) {
          contentList.add(entity.path);
        }
      }
    }
  }

  MediaInfo _extractMediaInfo(String fileName, MediaType type) {
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
            title: match.group(1)!.trim().replaceAll(".", " "),
            type: type,
            seriesName: match.group(1)!.trim(),
            seasonNumber: int.tryParse(match.group(2)!),
            episodeNumber: int.tryParse(match.group(3)!),
            quality: match.group(4),
            language: match.group(5),
          );
        } else if (match.groupCount >= 2) {
          // Padrão de filme
          return MediaInfo(
            title: match.group(1)!.trim().replaceAll(".", " "),
            type: type,
            year: match.group(2),
            quality: match.group(3),
            language: match.group(4),
          );
        }
      }
    }

    // Fallback: tratar como filme com nome simples
    return MediaInfo(title: fileName.trim(), type: type);
  }

  String _generateId(String filePath) {
    // Gerar ID único baseado no caminho do arquivo
    return filePath.hashCode.toString();
  }
}

class _EpisodeInfo {
  final String title;
  final int? seasonNumber;
  final int? episodeNumber;
  _EpisodeInfo({required this.title, this.seasonNumber, this.episodeNumber});
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
