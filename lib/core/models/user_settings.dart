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

  @HiveField(9)
  Map<String, String> customTitles; // filePath -> customTitle

  @HiveField(10)
  List<String> watchedItems; // filePath -> watched status

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
    Map<String, String>? customTitles,
    List<String>? watchedItems,
  })  : recentDirectories = recentDirectories ?? [],
        mediaMetadata = mediaMetadata ?? {},
        excludedExtensions = excludedExtensions ?? [],
        customTitles = customTitles ?? {},
        watchedItems = watchedItems ?? [];

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

  /// Define um título personalizado para uma mídia
  void setCustomTitle(String filePath, String customTitle) {
    if (customTitle.trim().isEmpty) {
      customTitles.remove(filePath);
    } else {
      customTitles[filePath] = customTitle.trim();
    }
  }

  /// Obtém o título personalizado de uma mídia
  String? getCustomTitle(String filePath) {
    return customTitles[filePath];
  }

  /// Remove o título personalizado de uma mídia
  void removeCustomTitle(String filePath) {
    customTitles.remove(filePath);
  }

  /// Limpa todos os títulos personalizados
  void clearCustomTitles() {
    customTitles.clear();
  }

  /// Define um item como assistido
  void setWatched(String filePath, bool watched) {
    if (watched) {
      if (!watchedItems.contains(filePath)) {
        watchedItems.add(filePath);
      }
    } else {
      watchedItems.remove(filePath);
    }
  }

  /// Verifica se um item foi assistido
  bool isWatched(String filePath) {
    return watchedItems.contains(filePath);
  }

  /// Remove o status de assistido de um item
  void removeWatched(String filePath) {
    watchedItems.remove(filePath);
  }

  /// Limpa todos os status de assistido
  void clearWatchedItems() {
    watchedItems.clear();
  }

  /// Obtém a lista de itens assistidos
  Set<String> getWatchedItems() {
    return Set.from(watchedItems);
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
    Map<String, String>? customTitles,
    List<String>? watchedItems,
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
      customTitles: customTitles ?? Map.from(this.customTitles),
      watchedItems: watchedItems ?? List.from(this.watchedItems),
    );
  }
} 