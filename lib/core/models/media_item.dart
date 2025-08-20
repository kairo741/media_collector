class MediaItem {
  final String id;
  final String title;
  final String filePath;
  final String fileName;
  final MediaType type;
  final String? seriesName;
  final String? seasonNumber;
  final int? episodeNumber;
  final String? year;
  final String? quality;
  final String? language;
  final DateTime lastModified;
  final int fileSize;
  final String? posterUrl;
  final String? customTitle;

  MediaItem({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileName,
    required this.type,
    this.seriesName,
    this.seasonNumber,
    this.episodeNumber,
    this.year,
    this.quality,
    this.language,
    required this.lastModified,
    required this.fileSize,
    this.posterUrl,
    this.customTitle,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      title: json['title'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      type: MediaType.values.firstWhere((e) => e.toString() == json['type']),
      seriesName: json['seriesName'],
      seasonNumber: json['seasonNumber'],
      episodeNumber: json['episodeNumber'],
      year: json['year'],
      quality: json['quality'],
      language: json['language'],
      lastModified: DateTime.parse(json['lastModified']),
      fileSize: json['fileSize'],
      posterUrl: json['posterUrl'],
      customTitle: json['customTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'fileName': fileName,
      'type': type.toString(),
      'seriesName': seriesName,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'year': year,
      'quality': quality,
      'language': language,
      'lastModified': lastModified.toIso8601String(),
      'fileSize': fileSize,
      'posterUrl': posterUrl,
      'customTitle': customTitle,
    };
  }

  /// Retorna o título a ser exibido (customTitle se disponível, senão title)
  String get displayTitle => customTitle ?? title;

  /// Cria uma cópia do MediaItem com um novo título personalizado
  MediaItem copyWithCustomTitle(String? customTitle) {
    return MediaItem(
      id: id,
      title: title,
      filePath: filePath,
      fileName: fileName,
      type: type,
      seriesName: seriesName,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      year: year,
      quality: quality,
      language: language,
      lastModified: lastModified,
      fileSize: fileSize,
      posterUrl: posterUrl,
      customTitle: customTitle,
    );
  }

  String get fileSizeFormatted {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int index = 0;
    double size = fileSize.toDouble();
    
    while (size >= 1024 && index < suffixes.length - 1) {
      size /= 1024;
      index++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[index]}';
  }
}

enum MediaType {
  movie,
  series,
} 