import 'package:flutter/foundation.dart';
import 'package:media_collector/core/models/media_item.dart';
import 'package:media_collector/core/services/media_player_service.dart';
import 'package:media_collector/core/services/media_scanner_service.dart';

class MediaProvider extends ChangeNotifier {
  final MediaScannerService _scannerService = MediaScannerService();
  final MediaPlayerService _playerService = MediaPlayerService();

  List<MediaItem> _mediaItems = [];
  List<MediaItem> _filteredItems = [];
  String _selectedDirectory = '';
  bool _isScanning = false;
  String? _errorMessage;
  MediaType? _selectedFilter;
  String _searchQuery = '';

  // Getters
  List<MediaItem> get mediaItems => _mediaItems;

  List<MediaItem> get filteredItems => _filteredItems;

  String get selectedDirectory => _selectedDirectory;

  bool get isScanning => _isScanning;

  String? get errorMessage => _errorMessage;

  MediaType? get selectedFilter => _selectedFilter;

  String get searchQuery => _searchQuery;

  // Estatísticas
  int get totalItems => _mediaItems.length;

  int get movieCount => _mediaItems.where((item) => item.type == MediaType.movie).length;

  int get seriesCount => _mediaItems.where((item) => item.type == MediaType.series).length;

  int get totalSize {
    return _mediaItems.fold(0, (sum, item) => sum + item.fileSize);
  }

  /// Escaneia um diretório em busca de arquivos de mídia
  Future<void> scanDirectory(String directoryPath) async {
    _setScanning(true);
    _clearError();

    try {
      _selectedDirectory = directoryPath;
      _mediaItems = await _scannerService.scanDirectory(directoryPath);
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
    _searchQuery = query.toLowerCase();
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

      // Filtro por busca
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        return item.title.toLowerCase().contains(searchLower) ||
            item.fileName.toLowerCase().contains(searchLower) ||
            (item.seriesName?.toLowerCase().contains(searchLower) ?? false) ||
            (item.year?.contains(searchLower) ?? false) ||
            (item.quality?.toLowerCase().contains(searchLower) ?? false);
      }

      return true;
    }).toList();

    // Ordenar por nome
    _filteredItems.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
  }

  /// Limpa todos os dados
  void clearData() {
    _mediaItems.clear();
    _filteredItems.clear();
    _selectedDirectory = '';
    _selectedFilter = null;
    _searchQuery = '';
    _clearError();
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
          return (a.seasonNumber ?? 0).compareTo(b.seasonNumber ?? 0);
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
