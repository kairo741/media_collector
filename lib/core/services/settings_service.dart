import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings.dart';

class SettingsService extends ChangeNotifier {
  static const String _settingsBoxName = 'user_settings';

  late Box<UserSettings> _settingsBox;
  late SharedPreferences _prefs;

  UserSettings? _currentSettings;

  UserSettings get currentSettings => _currentSettings ?? UserSettings();

  // Singleton pattern
  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  /// Inicializa o serviço de configurações
  Future<void> initialize() async {
    try {
      // Inicializa Hive
      await Hive.initFlutter();

      // Registra adaptadores
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserSettingsAdapter());
      }

      // Abre as boxes
      _settingsBox = await Hive.openBox<UserSettings>(_settingsBoxName);

      // Inicializa SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Carrega configurações salvas
      await _loadSettings();

      debugPrint('SettingsService inicializado com sucesso');
    } catch (e) {
      debugPrint('Erro ao inicializar SettingsService: $e');
      // Cria configurações padrão em caso de erro
      _currentSettings = UserSettings();
    }
  }

  /// Carrega as configurações salvas
  Future<void> _loadSettings() async {
    try {
      // Tenta carregar do Hive primeiro
      if (_settingsBox.isNotEmpty) {
        _currentSettings = _settingsBox.get('settings');
      }

      // Se não encontrou no Hive, tenta carregar do SharedPreferences (migração)
      if (_currentSettings == null) {
        _currentSettings = await _loadFromSharedPreferences();
        if (_currentSettings != null) {
          await saveSettings();
        }
      }

      // Se ainda não encontrou, cria configurações padrão
      if (_currentSettings == null) {
        _currentSettings = UserSettings();
        await saveSettings();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar configurações: $e');
      _currentSettings = UserSettings();
    }
  }

  /// Carrega configurações do SharedPreferences (para migração)
  Future<UserSettings?> _loadFromSharedPreferences() async {
    try {
      final selectedDir = _prefs.getString('selected_directory');
      final recentDirs = _prefs.getStringList('recent_directories') ?? [];
      final autoScan = _prefs.getBool('auto_scan_on_startup') ?? true;
      final enableThumbnails = _prefs.getBool('enable_thumbnails') ?? true;
      final thumbnailQuality = _prefs.getString('thumbnail_quality') ?? 'medium';

      if (selectedDir != null || recentDirs.isNotEmpty) {
        return UserSettings(
          selectedDirectory: selectedDir,
          recentDirectories: recentDirs,
          autoScanOnStartup: autoScan,
          enableThumbnails: enableThumbnails,
          thumbnailQuality: thumbnailQuality,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao carregar do SharedPreferences: $e');
      return null;
    }
  }

  /// Salva as configurações atuais
  Future<void> saveSettings() async {
    try {
      if (_currentSettings != null) {
        await _settingsBox.put('settings', _currentSettings!);
        debugPrint('Configurações salvas com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao salvar configurações: $e');
    }
  }

  /// Define o diretório selecionado
  Future<void> setSelectedDirectory(String directory) async {
    if (_currentSettings == null) return;

    _currentSettings!.selectedDirectory = directory;
    _currentSettings!.addRecentDirectory(directory);

    await saveSettings();
    notifyListeners();
  }

  /// Obtém o diretório selecionado
  String? getSelectedDirectory() {
    return _currentSettings?.selectedDirectory;
  }

  /// Obtém diretórios recentes
  List<String> getRecentDirectories() {
    return _currentSettings?.recentDirectories ?? [];
  }

  /// Adiciona metadados de mídia
  Future<void> addMediaMetadata(String filePath, Map<String, dynamic> metadata) async {
    if (_currentSettings == null) return;

    _currentSettings!.addMediaMetadata(filePath, metadata);
    await saveSettings();
  }

  /// Obtém metadados de mídia
  Map<String, dynamic>? getMediaMetadata(String filePath) {
    return _currentSettings?.getMediaMetadata(filePath);
  }

  /// Define configurações de thumbnails
  Future<void> setThumbnailSettings({bool? enableThumbnails, String? thumbnailQuality}) async {
    if (_currentSettings == null) return;

    if (enableThumbnails != null) {
      _currentSettings!.enableThumbnails = enableThumbnails;
    }

    if (thumbnailQuality != null) {
      _currentSettings!.thumbnailQuality = thumbnailQuality;
    }

    await saveSettings();
    notifyListeners();
  }

  /// Define se deve escanear automaticamente na inicialização
  Future<void> setAutoScanOnStartup(bool enabled) async {
    if (_currentSettings == null) return;

    _currentSettings!.autoScanOnStartup = enabled;
    await saveSettings();
    notifyListeners();
  }

  /// Adiciona extensões excluídas
  Future<void> addExcludedExtension(String extension) async {
    if (_currentSettings == null) return;

    if (!_currentSettings!.excludedExtensions.contains(extension)) {
      _currentSettings!.excludedExtensions.add(extension);
      await saveSettings();
      notifyListeners();
    }
  }

  /// Remove extensões excluídas
  Future<void> removeExcludedExtension(String extension) async {
    if (_currentSettings == null) return;

    if (_currentSettings!.excludedExtensions.remove(extension)) {
      await saveSettings();
      notifyListeners();
    }
  }

  /// Obtém extensões excluídas
  List<String> getExcludedExtensions() {
    return _currentSettings?.excludedExtensions ?? [];
  }

  /// Define a pasta alternativa para posters
  Future<void> setAlternativePosterDirectory(String? directory) async {
    if (_currentSettings == null) return;

    _currentSettings!.alternativePosterDirectory = directory;
    await saveSettings();
    notifyListeners();
  }

  /// Obtém a pasta alternativa para posters
  String? getAlternativePosterDirectory() {
    return _currentSettings?.alternativePosterDirectory;
  }

  /// Define um título personalizado para uma mídia
  Future<void> setCustomTitle(String filePath, String customTitle) async {
    if (_currentSettings == null) return;

    _currentSettings!.setCustomTitle(filePath, customTitle);
    await saveSettings();
    notifyListeners();
  }

  /// Obtém o título personalizado de uma mídia
  String? getCustomTitle(String filePath) {
    return _currentSettings?.getCustomTitle(filePath);
  }

  /// Remove o título personalizado de uma mídia
  Future<void> removeCustomTitle(String filePath) async {
    if (_currentSettings == null) return;

    _currentSettings!.removeCustomTitle(filePath);
    await saveSettings();
    notifyListeners();
  }

  /// Limpa todos os títulos personalizados
  Future<void> clearCustomTitles() async {
    if (_currentSettings == null) return;

    _currentSettings!.clearCustomTitles();
    await saveSettings();
    notifyListeners();
  }

  /// Define um item como assistido
  Future<void> setWatched(String filePath, bool watched) async {
    if (_currentSettings == null) return;

    _currentSettings!.setWatched(filePath, watched);
    await saveSettings();
    notifyListeners();
  }

  /// Verifica se um item foi assistido
  bool isWatched(String filePath) {
    return _currentSettings?.isWatched(filePath) ?? false;
  }

  /// Remove o status de assistido de um item
  Future<void> removeWatched(String filePath) async {
    if (_currentSettings == null) return;

    _currentSettings!.removeWatched(filePath);
    await saveSettings();
    notifyListeners();
  }

  /// Limpa todos os status de assistido
  Future<void> clearWatchedItems() async {
    if (_currentSettings == null) return;

    _currentSettings!.clearWatchedItems();
    await saveSettings();
    notifyListeners();
  }

  /// Obtém a lista de itens assistidos
  Set<String> getWatchedItems() {
    return _currentSettings?.getWatchedItems() ?? {};
  }

  /// Reseta todas as configurações
  Future<void> resetSettings() async {
    _currentSettings = UserSettings();
    await _settingsBox.clear();
    await saveSettings();
    notifyListeners();
  }

  /// Fecha as conexões
  Future<void> dispose() async {
    await _settingsBox.close();
  }
}
