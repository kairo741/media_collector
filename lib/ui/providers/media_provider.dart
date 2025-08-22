import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_collector/core/models/media_item.dart';
import 'package:media_collector/core/services/media_player_service.dart';
import 'package:media_collector/core/services/media_scanner_service.dart';
import 'package:media_collector/core/services/settings_service.dart';

class MediaProvider extends ChangeNotifier {
  final MediaScannerService _scannerService = MediaScannerService();
  final MediaPlayerService _playerService = MediaPlayerService();
  final SettingsService _settingsService = SettingsService();

  List<MediaItem> _mediaItems = [];
  List<MediaItem> _filteredItems = [];
  String _selectedDirectory = '';
  bool _isScanning = false;
  String? _errorMessage;
  MediaType? _selectedFilter;
  String _searchQuery = '';
  bool? _watchedFilter; // null = todos, true = apenas assistidos, false = apenas não assistidos

  // Getters
  List<MediaItem> get mediaItems => _mediaItems;

  List<MediaItem> get filteredItems => _filteredItems;

  String get selectedDirectory => _selectedDirectory;

  bool get isScanning => _isScanning;

  String? get errorMessage => _errorMessage;

  MediaType? get selectedFilter => _selectedFilter;

  String get searchQuery => _searchQuery;

  bool? get watchedFilter => _watchedFilter;

  // Estatísticas
  int get totalItems => _mediaItems.length;

  int get movieCount => _mediaItems.where((item) => item.type == MediaType.movie).length;

  int get seriesCount => _mediaItems.where((item) => item.type == MediaType.series).length;

  int get watchedCount => _mediaItems.where((item) => item.isWatched).length;

  int get unwatchedCount => _mediaItems.where((item) => !item.isWatched).length;

  int get totalSize {
    return _mediaItems.fold(0, (sum, item) => sum + item.fileSize);
  }

  /// Inicializa o provider e carrega configurações salvas
  Future<void> initialize() async {
    await _settingsService.initialize();

    // Carrega diretório salvo
    final savedDirectory = _settingsService.getSelectedDirectory();
    if (savedDirectory != null && savedDirectory.isNotEmpty) {
      _selectedDirectory = savedDirectory;

      // Se auto-scan estiver habilitado, escaneia automaticamente
      if ( _settingsService.currentSettings.autoScanOnStartup) {
        await scanDirectory(savedDirectory);
      }
    }

    notifyListeners();
  }

  /// Escaneia um diretório em busca de arquivos de mídia
  Future<void> scanDirectory(String directoryPath) async {
    _setScanning(true);
    _clearError();

    try {
      _selectedDirectory = directoryPath;

      // Salva o diretório selecionado
      await _settingsService.setSelectedDirectory(directoryPath);

      _mediaItems = await _scannerService.scanDirectory(directoryPath);

      // Carrega títulos personalizados salvos
      _loadCustomTitles();

      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao escanear diretório: $e');
    } finally {
      _setScanning(false);
    }
  }

  /// Abre um arquivo de mídia
  Future<void> openMediaFile(MediaItem item) async {
    try {
      final success = await _playerService.openMediaFile(item.filePath);
      if (!success) {
        _setError('Não foi possível abrir o arquivo: ${item.fileName}');
      }
    } catch (e) {
      _setError('Erro ao abrir arquivo: $e');
    }
  }

  /// Abre a pasta contendo o arquivo
  Future<void> openContainingFolder(MediaItem item) async {
    try {
      final success = await _playerService.openContainingFolder(item.filePath);
      if (!success) {
        _setError('Não foi possível abrir a pasta: ${item.fileName}');
      }
    } catch (e) {
      _setError('Erro ao abrir pasta: $e');
    }
  }

  /// Escaneia episódios de uma série
  Future<List<MediaItem>> scanSeriesEpisodes(String seriesDirPath, String seriesName) async {
    try {
      return await _scannerService.scanSeriesEpisodes(seriesDirPath, seriesName);
    } catch (e) {
      _setError('Erro ao escanear episódios: $e');
      return [];
    }
  }

  /// Define o filtro de tipo de mídia
  void setFilter(MediaType? filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Define a query de busca
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Define o filtro de status assistido
  void setWatchedFilter(bool? filter) {
    _watchedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica filtros e busca
  void _applyFilters() {
    _filteredItems = _mediaItems.where((item) {
      // Filtro por tipo
      if (_selectedFilter != null && item.type != _selectedFilter) {
        return false;
      }

      // Filtro por status assistido
      if (_watchedFilter != null) {
        if (_watchedFilter! && !item.isWatched) {
          return false;
        }
        if (!_watchedFilter! && item.isWatched) {
          return false;
        }
      }

      // Filtro por busca
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = item.title.toLowerCase();
        final fileName = item.fileName.toLowerCase();
        final seriesName = item.seriesName?.toLowerCase() ?? '';
        final customTitle = item.customTitle?.toLowerCase() ?? '';

        if (!title.contains(query) &&
            !fileName.contains(query) &&
            !customTitle.contains(query) &&
            !seriesName.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Ordena a lista alfabeticamente usando o título personalizado quando disponível
    _filteredItems.sort((a, b) {
      // Usa o título personalizado se disponível, senão usa o título original
      final titleA = (a.customTitle ?? a.title).toLowerCase();
      final titleB = (b.customTitle ?? b.title).toLowerCase();
      
      return titleA.compareTo(titleB);
    });
  }

  /// Obtém diretórios recentes
  List<String> getRecentDirectories() {
    return _settingsService.getRecentDirectories();
  }

  /// Obtém configurações de thumbnails
  bool get enableThumbnails => _settingsService.currentSettings.enableThumbnails;
  String get thumbnailQuality => _settingsService.currentSettings.thumbnailQuality;

  /// Define configurações de thumbnails
  Future<void> setThumbnailSettings({
    bool? enableThumbnails,
    String? thumbnailQuality,
  }) async {
    await _settingsService.setThumbnailSettings(
      enableThumbnails: enableThumbnails,
      thumbnailQuality: thumbnailQuality,
    );
  }

  /// Define auto-scan na inicialização
  Future<void> setAutoScanOnStartup(bool enabled) async {
    await _settingsService.setAutoScanOnStartup(enabled);
  }

  /// Obtém extensões excluídas
  List<String> getExcludedExtensions() {
    return _settingsService.getExcludedExtensions();
  }

  /// Adiciona extensão excluída
  Future<void> addExcludedExtension(String extension) async {
    await _settingsService.addExcludedExtension(extension);
  }

  /// Remove extensão excluída
  Future<void> removeExcludedExtension(String extension) async {
    await _settingsService.removeExcludedExtension(extension);
  }

  /// Define a pasta alternativa para posters
  Future<void> setAlternativePosterDirectory(String? directory) async {
    await _settingsService.setAlternativePosterDirectory(directory);
  }

  /// Obtém a pasta alternativa para posters
  String? getAlternativePosterDirectory() {
    return _settingsService.getAlternativePosterDirectory();
  }

  /// Define um título personalizado para uma mídia
  Future<void> setCustomTitle(MediaItem item, String customTitle) async {
    await _settingsService.setCustomTitle(item.filePath, customTitle);

    // Atualiza o item na lista local
    final index = _mediaItems.indexWhere((m) => m.id == item.id);
    if (index != -1) {
      _mediaItems[index] = item.copyWithCustomTitle(customTitle);
      _applyFilters();
      notifyListeners();
    }
  }

  /// Remove o título personalizado de uma mídia
  Future<void> removeCustomTitle(MediaItem item) async {
    await _settingsService.removeCustomTitle(item.filePath);

    // Atualiza o item na lista local
    final index = _mediaItems.indexWhere((m) => m.id == item.id);
    if (index != -1) {
      _mediaItems[index] = item.copyWithCustomTitle(null);
      _applyFilters();
      notifyListeners();
    }
  }

  /// Obtém o título personalizado de uma mídia
  String? getCustomTitle(MediaItem item) {
    return _settingsService.getCustomTitle(item.filePath);
  }

  /// Limpa todos os títulos personalizados
  Future<void> clearCustomTitles() async {
    await _settingsService.clearCustomTitles();

    // Atualiza todos os itens na lista local
    for (int i = 0; i < _mediaItems.length; i++) {
      _mediaItems[i] = _mediaItems[i].copyWithCustomTitle(null);
    }
    _applyFilters();
    notifyListeners();
  }

  /// Carrega títulos personalizados salvos para os itens de mídia
  void _loadCustomTitles() {
    for (int i = 0; i < _mediaItems.length; i++) {
      final customTitle = _settingsService.getCustomTitle(_mediaItems[i].filePath);
      if (customTitle != null) {
        _mediaItems[i] = _mediaItems[i].copyWithCustomTitle(customTitle);
      }
      
      // Carrega status de assistido
      final isWatched = _settingsService.isWatched(_mediaItems[i].filePath);
      if (isWatched != _mediaItems[i].isWatched) {
        _mediaItems[i] = _mediaItems[i].copyWithWatchedStatus(isWatched);
      }
    }
  }

  /// Atualiza as configurações aplicadas aos itens de mídia sem reescanear o diretório
  void refreshMediaItemsWithSettings() {
    _loadCustomTitles();
    _applyFilters();
    notifyListeners();
  }

  /// Define um item como assistido
  Future<void> setWatched(MediaItem item, bool watched) async {
    await _settingsService.setWatched(item.filePath, watched);

    // Atualiza o item na lista local
    final index = _mediaItems.indexWhere((m) => m.id == item.id);
    if (index != -1) {
      _mediaItems[index] = item.copyWithWatchedStatus(watched);
      _applyFilters();
      notifyListeners();
    }
  }

  /// Verifica se um item foi assistido
  bool isWatched(MediaItem item) {
    return _settingsService.isWatched(item.filePath);
  }

  /// Remove o status de assistido de um item
  Future<void> removeWatched(MediaItem item) async {
    await _settingsService.removeWatched(item.filePath);

    // Atualiza o item na lista local
    final index = _mediaItems.indexWhere((m) => m.id == item.id);
    if (index != -1) {
      _mediaItems[index] = item.copyWithWatchedStatus(false);
      _applyFilters();
      notifyListeners();
    }
  }

  /// Limpa todos os status de assistido
  Future<void> clearWatchedItems() async {
    await _settingsService.clearWatchedItems();

    // Atualiza todos os itens na lista local
    for (int i = 0; i < _mediaItems.length; i++) {
      _mediaItems[i] = _mediaItems[i].copyWithWatchedStatus(false);
    }
    _applyFilters();
    notifyListeners();
  }

  /// Obtém a lista de itens assistidos
  Set<String> getWatchedItems() {
    return _settingsService.getWatchedItems();
  }

  /// Calcula o tamanho total ocupado pelas thumbnails em disco
  Future<String> getThumbnailsSize() async {
    try {
      final tempDir = Directory('${Directory.systemTemp.path}\\media_collector_thumb');
      if (!await tempDir.exists()) {
        return '0 MB';
      }

      int totalSize = 0;
      await for (final entity in tempDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      if (totalSize < 1024) {
        return '$totalSize B';
      } else if (totalSize < 1024 * 1024) {
        return '${(totalSize / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      debugPrint('Erro ao calcular tamanho das thumbnails: $e');
      return '0 MB';
    }
  }

  /// Limpa todas as thumbnails
  Future<bool> clearThumbnails() async {
    try {
      final tempDir = Directory('${Directory.systemTemp.path}\\media_collector_thumb');
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        debugPrint('Thumbnails limpas com sucesso');
        return true;
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao limpar thumbnails: $e');
      return false;
    }
  }

  /// Reseta configurações
  Future<void> resetSettings() async {
    await _settingsService.resetSettings();
    _selectedDirectory = '';
    _mediaItems.clear();
    _filteredItems.clear();
    notifyListeners();
  }

  /// Obtém itens agrupados por série
  Map<String, List<MediaItem>> getSeriesGrouped() {
    final Map<String, List<MediaItem>> grouped = {};

    for (final item in _filteredItems.where((item) => item.type == MediaType.series)) {
      final seriesName = item.seriesName ?? 'Série Desconhecida';
      grouped.putIfAbsent(seriesName, () => []).add(item);
    }

    // Ordenar episódios dentro de cada série
    for (final series in grouped.values) {
      series.sort((a, b) {
        if (a.seasonNumber != b.seasonNumber) {
          return (a.seasonNumber ?? '').compareTo(b.seasonNumber ?? '');
        }
        return (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0);
      });
    }

    return grouped;
  }

  /// Obtém apenas filmes
  List<MediaItem> get movies => _filteredItems.where((item) => item.type == MediaType.movie).toList();

  void _setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
