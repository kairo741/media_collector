import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MediaPlayerService {
  /// Abre um arquivo de mídia usando o aplicativo padrão do sistema
  Future<bool> openMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }

      // No Windows, usar o comando 'start' para abrir com o aplicativo padrão
      if (Platform.isWindows) {
        final result = await Process.run('start', ['', filePath], runInShell: true);
        return result.exitCode == 0;
      } else {
        // Para outras plataformas, usar url_launcher
        final uri = Uri.file(filePath);
        return await launchUrl(uri);
      }
    } catch (e) {
      print('Erro ao abrir arquivo de mídia: $e');
      return false;
    }
  }

  /// Abre a pasta contendo o arquivo no explorador de arquivos
  Future<bool> openContainingFolder(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado: $filePath');
      }

      final directory = file.parent.path;

      if (Platform.isWindows) {
        final result = await Process.run('explorer', ['/select,', filePath], runInShell: true);
        return result.exitCode == 0;
      } else {
        final uri = Uri.file(directory);
        return await launchUrl(uri);
      }
    } catch (e) {
      print('Erro ao abrir pasta: $e');
      return false;
    }
  }

  /// Verifica se o arquivo pode ser reproduzido
  Future<bool> canPlayFile(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
} 