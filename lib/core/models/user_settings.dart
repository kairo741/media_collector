import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 0)
class UserSettings extends HiveObject {
  @HiveField(0)
  String? selectedDirectory;

  @HiveField(1)
  List<String> recentDirectories;

  @HiveField(2)
  Map<String, dynamic> mediaMetadata; // filePath -> metadata

  @HiveField(3)
  bool autoScanOnStartup;

  @HiveField(4)
  List<String> excludedExtensions;

  @HiveField(5)
  int maxRecentDirectories;

  @HiveField(6)
  bool enableThumbnails;

  @HiveField(7)
  String thumbnailQuality; // 'low', 'medium', 'high'

  @HiveField(8)
  String? alternativePosterDirectory; // Pasta alternativa para buscar posters

  UserSettings({
    this.selectedDirectory,
    List<String>? recentDirectories,
    Map<String, dynamic>? mediaMetadata,
    this.autoScanOnStartup = true,
    List<String>? excludedExtensions,
    this.maxRecentDirectories = 5,
    this.enableThumbnails = true,
    this.thumbnailQuality = 'medium',
    this.alternativePosterDirectory,
  })  : recentDirectories = recentDirectories ?? [],
        mediaMetadata = mediaMetadata ?? {},
        excludedExtensions = excludedExtensions ?? [];

  // Métodos auxiliares
  void addRecentDirectory(String directory) {
    if (directory.isEmpty) return;
    
    // Remove se já existe
    recentDirectories.remove(directory);
    
    // Adiciona no início
    recentDirectories.insert(0, directory);
    
    // Mantém apenas os mais recentes
    if (recentDirectories.length > maxRecentDirectories) {
      recentDirectories = recentDirectories.take(maxRecentDirectories).toList();
    }
  }

  void addMediaMetadata(String filePath, Map<String, dynamic> metadata) {
    mediaMetadata[filePath] = metadata;
  }

  Map<String, dynamic>? getMediaMetadata(String filePath) {
    return mediaMetadata[filePath];
  }

  void clearMediaMetadata() {
    mediaMetadata.clear();
  }

  // Cria uma cópia das configurações
  UserSettings copyWith({
    String? selectedDirectory,
    List<String>? recentDirectories,
    Map<String, dynamic>? mediaMetadata,
    bool? autoScanOnStartup,
    List<String>? excludedExtensions,
    int? maxRecentDirectories,
    bool? enableThumbnails,
    String? thumbnailQuality,
    String? alternativePosterDirectory,
  }) {
    return UserSettings(
      selectedDirectory: selectedDirectory ?? this.selectedDirectory,
      recentDirectories: recentDirectories ?? List.from(this.recentDirectories),
      mediaMetadata: mediaMetadata ?? Map.from(this.mediaMetadata),
      autoScanOnStartup: autoScanOnStartup ?? this.autoScanOnStartup,
      excludedExtensions: excludedExtensions ?? List.from(this.excludedExtensions),
      maxRecentDirectories: maxRecentDirectories ?? this.maxRecentDirectories,
      enableThumbnails: enableThumbnails ?? this.enableThumbnails,
      thumbnailQuality: thumbnailQuality ?? this.thumbnailQuality,
      alternativePosterDirectory: alternativePosterDirectory ?? this.alternativePosterDirectory,
    );
  }
} 