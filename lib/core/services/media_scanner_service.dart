import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/media_item.dart';
import '../services/settings_service.dart';

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

  static const List<String> _imageExtensions = ['.png', '.jpg', '.webp', '.jpeg'];
  final SettingsService _settingsService = SettingsService();

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
        final customTitle = _settingsService.getCustomTitle(entity.path);
        episodes.add(
          MediaItem(
            id: entity.path.hashCode.toString(),
            title: info.title,
            filePath: entity.path,
            fileName: fileName,
            type: MediaType.series,
            seriesName: seriesName,
            seasonNumber: info.seasonNumber,
            episodeNumber: info.episodeNumber,
            year: null,
            quality: info.quality,
            language: info.language,
            lastModified: await entity.lastModified(),
            fileSize: await entity.length(),
            customTitle: customTitle,
          ),
        );
      }
    }
    return episodes;
  }

  /// Extrai informações de temporada e episódio do nome do arquivo
  _EpisodeInfo _extractEpisodeInfo(String fileName, String filePath) {
    final parentDir = path.basename(path.dirname(filePath));
    final patterns = [
      RegExp(r'^(.+?)[ ._-]*S(\d{1,2})E(\d{1,2})[ ._-]*(.+)?$', caseSensitive: false),
      RegExp(r'^(\d{1,2})[ ._-]+(.+?)[ ._-]+(\d{1,2})[ ._-]+(.+)$', caseSensitive: false),
      RegExp(r'^(.+?)\.S(\d{1,2})E(\d{1,2})\.(.+)$', caseSensitive: false),
      RegExp(r'^(.+?)\.S(\d{1,2})E(\d{1,2})\.(.+)$', caseSensitive: false),
      RegExp(r'^(.+?)[ ._-]+(\d{1,2})x(\d{1,2})', caseSensitive: false),
      RegExp(r'^(.+?)[ ._-]+T(\d{1,2})E(\d{1,2})', caseSensitive: false),
      RegExp(r'^(\d{1,2})[ ._-]+(.+)$', caseSensitive: false),
    ];

    int? episodeNumber;
    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(fileName);
      if (match != null) {
        switch (i) {
          case 0:
          case 2:
          case 3:
            episodeNumber = int.tryParse(match.group(3) ?? '');
            break;
          case 1:
            episodeNumber = int.tryParse(match.group(1) ?? '');
            break;
          case 4:
          case 5:
            episodeNumber = int.tryParse(match.group(3) ?? '');
            break;
          case 6:
            episodeNumber = int.tryParse(match.group(1) ?? '');
            break;
        }
        break;
      }
    }

    final derivedTitle = _deriveEpisodeTitleFromFileName(fileName);
    final title = derivedTitle.isNotEmpty ? derivedTitle : fileName;
    final derivedSeason = _deriveSeasonLabel(parentDir, fileName);
    final qualityLang = _detectQualityAndLanguage(fileName);
    return _EpisodeInfo(
      title: title,
      seasonNumber: derivedSeason,
      episodeNumber: episodeNumber,
      quality: qualityLang.quality,
      language: qualityLang.language,
    );
  }

  Future<void> _scanDirectory(Directory directory, List<MediaItem> mediaItems) async {
    try {
      await for (final FileSystemEntity entity in directory.list(recursive: false)) {
        if (entity is File) {
          final MediaItem? mediaItem = _processFile(entity);
          if (mediaItem != null) {
            if (kDebugMode) print("Media: ${mediaItem.title}");
            mediaItems.add(mediaItem);
          }
        } else if (entity is Directory) {
          final MediaItem? mediaItem = await _processSubDirs(entity, mediaItems);
          if (mediaItem != null) {
            if (kDebugMode) print("Dir: ${mediaItem.title}");
            mediaItems.add(mediaItem);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao escanear diretório ${directory.path}: $e');
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

    // Tentar buscar poster local na pasta alternativa
    final String? localPosterPath = _getLocalPoster(path.dirname(file.path), fileName);

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
      posterUrl: localPosterPath,
    );
  }

  Future<MediaItem?> _processSubDirs(Directory dir, List<MediaItem> mediaItems) async {
    final String fileName = path.basename(dir.path);
    var contentList = <String>[];
    var localPosterPath = <String>[''];
    await _hasMediaContent(dir, contentList, localPosterPath);

    if (contentList.isEmpty) return null;

    final mediaType = contentList.length > 1 ? MediaType.series : MediaType.movie;

    final qualityLang = _detectQualityAndLanguage(fileName);
    // Tentar extrair informações do nome do arquivo
    final MediaInfo mediaInfo = MediaInfo(
      title: fileName.replaceAll(".", " "),
      type: MediaType.series,
      seriesName: fileName,
      episodeNumber: 1,
      quality: qualityLang.quality,
      language: qualityLang.language,
    );

    return MediaItem(
      id: _generateId(dir.path),
      title: mediaInfo.title,
      filePath: mediaType == MediaType.movie ? contentList.first : dir.path,
      fileName: fileName,
      type: mediaType,
      seriesName: mediaInfo.seriesName,
      episodeNumber: mediaInfo.episodeNumber,
      year: mediaInfo.year,
      quality: mediaInfo.quality ?? qualityLang.quality,
      language: mediaInfo.language ?? qualityLang.language,
      lastModified: DateTime.now(),
      fileSize: 10,
      posterUrl: localPosterPath[0].isEmpty
          ? _getLocalPoster(dir.path, fileName)
          : localPosterPath[0],
    );
  }

  Future<void> _hasMediaContent(
    Directory directory,
    List<String> contentList,
    List<String> localPosterPath,
  ) async {
    await for (final FileSystemEntity entity in directory.list(recursive: true)) {
      if (entity is File) {
        final String extension = path.extension(entity.path).toLowerCase();
        if (localPosterPath[0].isEmpty && _imageExtensions.contains(extension)) {
          localPosterPath[0] = entity.path;
        }

        final MediaItem? mediaItem = _processFile(entity);
        if (mediaItem != null) {
          contentList.add(entity.path);
        }
      }
    }
  }

  _getLocalPoster(String dirPath, String mediaFileNm) {
    try {
      // Obter o caminho alternativo para posters das configurações
      final SettingsService settingsService = SettingsService();
      final String? alternativePosterDir = settingsService.getAlternativePosterDirectory();

      if (alternativePosterDir == null || alternativePosterDir.isEmpty) {
        return null;
      }

      // Verificar se o diretório alternativo existe
      final Directory altDir = Directory(alternativePosterDir);
      if (!altDir.existsSync()) {
        return null;
      }

      // Obter o nome do arquivo sem extensão para buscar o poster correspondente
      final String fileNameWithoutExt = path.basenameWithoutExtension(mediaFileNm);

      // Buscar por arquivos de imagem com o mesmo nome
      for (final String ext in _imageExtensions) {
        final String posterPath = path.join(alternativePosterDir, '$fileNameWithoutExt$ext');
        final File posterFile = File(posterPath);

        if (posterFile.existsSync()) {
          return posterPath;
        }
      }

      // Se não encontrou com extensão exata, tentar buscar por correspondência parcial
      // (útil para casos onde o nome do arquivo de mídia e do poster podem ter pequenas diferenças)
      final List<FileSystemEntity> files = altDir.listSync();

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          final String ext = path.extension(entity.path).toLowerCase();
          if (_imageExtensions.contains(ext)) {
            final String entityName = path.basenameWithoutExtension(entity.path);

            // Verificar se o nome do arquivo de mídia contém o nome do poster ou vice-versa
            if (fileNameWithoutExt.toLowerCase().contains(entityName.toLowerCase()) ||
                entityName.toLowerCase().contains(fileNameWithoutExt.toLowerCase())) {
              return entity.path;
            }
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao buscar poster local: $e');
      return null;
    }
  }

  MediaInfo _extractMediaInfo(String fileName, MediaType type) {
    final qualityLang = _detectQualityAndLanguage(fileName);
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
            seasonNumber: match.group(2),
            episodeNumber: int.tryParse(match.group(3)!),
            quality: match.group(4) ?? qualityLang.quality,
            language: match.group(5) ?? qualityLang.language,
          );
        } else if (match.groupCount >= 2) {
          // Padrão de filme
          return MediaInfo(
            title: match.group(1)!.trim().replaceAll(".", " "),
            type: type,
            year: match.group(2),
            quality: match.group(3) ?? qualityLang.quality,
            language: match.group(4) ?? qualityLang.language,
          );
        }
      }
    }

    // Fallback: tratar como filme com nome simples
    return MediaInfo(
      title: fileName.trim(),
      type: type,
      quality: qualityLang.quality,
      language: qualityLang.language,
    );
  }

  String _generateId(String filePath) {
    // Gerar ID único baseado no caminho do arquivo
    return filePath.hashCode.toString();
  }
}

class _EpisodeInfo {
  final String title;
  final String? seasonNumber;
  final int? episodeNumber;
  final String? quality;
  final String? language;

  _EpisodeInfo({
    required this.title,
    this.seasonNumber,
    this.episodeNumber,
    this.quality,
    this.language,
  });
}

class QualityLanguage {
  final String? quality;
  final String? language;

  const QualityLanguage({this.quality, this.language});
}

class MediaInfo {
  final String title;
  final MediaType type;
  final String? seriesName;
  final String? seasonNumber;
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

/// Tenta derivar o título real do episódio a partir do nome do arquivo, ignorando padrões como
/// SxxExx, 1x02, TxxExx e removendo indicadores de qualidade/resolução.
String _deriveEpisodeTitleFromFileName(String fileName) {
  final sanitized = fileName.replaceAll(RegExp(r'[._]+'), ' ').trim();
  final patterns = [
    RegExp(r'[Ss](\d{1,2})[Ee](\d{1,2})', caseSensitive: false),
    RegExp(r'(\d{1,2})x(\d{1,2})', caseSensitive: false),
    RegExp(r'[Tt](\d{1,2})[Ee](\d{1,2})', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(sanitized);
    if (match != null) {
      final tail = sanitized.substring(match.end).replaceFirst(RegExp(r'^[\s:._-]+'), '');
      final cleaned = _cleanEpisodeTitle(tail);
      if (cleaned.isNotEmpty) {
        return cleaned;
      }
    }
  }

  var fallback = sanitized
      .replaceAll(RegExp(r'[Ss](\d{1,2})[Ee](\d{1,2})', caseSensitive: false), '')
      .replaceAll(RegExp(r'(\d{1,2})x(\d{1,2})', caseSensitive: false), '')
      .replaceAll(RegExp(r'[Tt](\d{1,2})[Ee](\d{1,2})', caseSensitive: false), '')
      .trim();

  final cleanedFallback = _cleanEpisodeTitle(fallback);
  if (cleanedFallback.isNotEmpty) {
    return cleanedFallback;
  }

  return _cleanEpisodeTitle(sanitized);
}

/// Remove palavras-chave de release e excesso de pontuação para deixar apenas o título limpo.
String _cleanEpisodeTitle(String rawTitle) {
  var cleaned = rawTitle.replaceAll(RegExp(r'[._]+'), ' ').trim();
  final extraneous = RegExp(
    r'[\s:._-]*(imax|web[-_. ]?dl|web[-_. ]?rip|web|dl|hdtv|bluray|bdrip|brip|hdrip|remux|proper|repack|extended|directors cut|dual(?:[- ]?audio)?|dub(?:bed)?|sub(?:bed)?|x264|x265|xvid|hevc|hdr10\+?|hdr10|hdr|uhd|2160p|1080p|720p|480p|4k|8k|dts|ac3|truehd|ddp5\.1|dd5\.1|dd2\.0|atmos|lossless|clean|limited)\b.*',
    caseSensitive: false,
  );
  cleaned = cleaned.replaceAll(extraneous, '').trim();
  cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ');
  return cleaned;
}

final _seasonReleasePattern = RegExp(
  r'[\s:._-]*(?:web[-_. ]?dl|web[-_. ]?rip|webrip|webdl|bdrip|brip|bluray|hdrip|remux|proper|repack|extended|directors cut|limited|cam(?:rip)?|ts|telesync|dvdrip|dvd(?:rip)?|hdcam|uncut)\b',
  caseSensitive: false,
);

final List<RegExp> _seasonExtrasPatterns = [
  RegExp(r'\b\d{3,4}p\b', caseSensitive: false),
  RegExp(r'\bdual(?:x\d+)?\b', caseSensitive: false),
  RegExp(r'\bx(?:264|265)\b', caseSensitive: false),
  RegExp(r'\bhevc\b', caseSensitive: false),
  RegExp(r'\bhdr10\+?\b', caseSensitive: false),
  RegExp(r'\bhdr10\b', caseSensitive: false),
  RegExp(r'\bhdr\b', caseSensitive: false),
  RegExp(r'\buhd\b', caseSensitive: false),
];

/// Normaliza a label de temporada removendo releases e adicionando tokens relevantes
/// de qualidade (ex: 1080p, DUALx264) para exibição na tela.
String _deriveSeasonLabel(String parentDir, String fileName) {
  final seasonNumber = _extractSeasonNumber(parentDir) ?? _extractSeasonNumber(fileName);
  final extras = _collectSeasonExtras('$parentDir $fileName');
  final baseFallback = _cleanSeasonBase(parentDir);
  final labelBase = seasonNumber != null
      ? 'Temporada $seasonNumber'
      : baseFallback.isNotEmpty
      ? baseFallback
      : parentDir.trim().isNotEmpty
      ? parentDir.trim()
      : 'Temporada';
  if (extras.isEmpty) {
    return labelBase;
  }
  return '$labelBase ${extras.map((extra) => '[$extra]').join(' ')}';
}

String _cleanSeasonBase(String value) {
  final cleaned = value.replaceAll(_seasonReleasePattern, '').trim();
  return cleaned.isNotEmpty ? cleaned : value.trim();
}

String? _extractSeasonNumber(String text) {
  if (text.isEmpty) return null;
  final normalized = text.replaceAll(RegExp(r'[._]+'), ' ');
  final patterns = [
    RegExp(r'[Ss]eason[\s-]*(\d{1,2})', caseSensitive: false),
    RegExp(r'[Ss](\d{1,2})\b', caseSensitive: false),
    RegExp(r'\b(\d{1,2})x', caseSensitive: false),
    RegExp(r'[Tt](\d{1,2})[Ee]', caseSensitive: false),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(normalized);
    if (match != null && match.groupCount >= 1) {
      final value = match.group(1);
      if (value != null && value.isNotEmpty) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed.toString();
        }
        return value;
      }
    }
  }
  return null;
}

List<String> _collectSeasonExtras(String source) {
  final extras = <String>[];
  final seen = <String>{};
  final normalized = source.replaceAll(RegExp(r'[._]+'), ' ');
  for (final pattern in _seasonExtrasPatterns) {
    for (final match in pattern.allMatches(normalized)) {
      final token = match.group(0)?.trim();
      if (token == null || token.isEmpty) continue;
      final canonical = token.toLowerCase();
      if (seen.contains(canonical)) continue;
      seen.add(canonical);
      extras.add(token);
    }
  }
  return extras;
}

const List<String> _qualityKeywords = [
  '1080p',
  '2160p',
  '720p',
  '480p',
  '4k',
  '8k',
  'hdr10+',
  'hdr10',
  'hdr',
  'uhd',
  'bluray',
  'web-dl',
  'webdl',
  'web-rip',
  'webrip',
  'bdrip',
  'brip',
  'hdtv',
  'remux',
  'x264',
  'x265',
  'xvid',
  'hevc',
  'dual x264',
  'dual x265',
  'dual',
  'hdcam',
  'cam',
  'ts',
  'dvdrip',
  'truehd',
  'ddp5.1',
  'dd5.1',
  'dd2.0',
  'atmos',
  'dts',
];

const List<String> _languageKeywords = [
  'pt-br',
  'ptbr',
  'portuguese',
  'es',
  'eng',
  'en',
  'english',
  'spanish',
  'dual audio',
  'dual',
  'dublado',
  'dubbed',
  'subtitled',
];

/// Detecta qualidade e idioma com base em palavras-chave comuns no nome do arquivo.
QualityLanguage _detectQualityAndLanguage(String fileName) {
  final normalized = fileName.replaceAll(RegExp(r'[._]+'), ' ').toLowerCase();
  String? quality;
  String? language;

  for (final keyword in _qualityKeywords) {
    final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
    if (pattern.hasMatch(normalized)) {
      quality = keyword.toUpperCase();
      break;
    }
  }

  for (final keyword in _languageKeywords) {
    final pattern = RegExp(r'\b' + RegExp.escape(keyword) + r'\b', caseSensitive: false);
    if (pattern.hasMatch(normalized)) {
      language = keyword.toUpperCase();
      break;
    }
  }

  return QualityLanguage(quality: quality, language: language);
}
