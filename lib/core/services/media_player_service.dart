import 'dart:io';
import 'package:flutter/foundation.dart';
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
      if (kDebugMode) print('Erro ao abrir arquivo de mídia: $e');
      return false;
    }
  }

  /// Abre a pasta contendo o arquivo no explorador de arquivos
  Future<bool> openContainingFolder(String path) async {
    try {
      final file = File(path);
      final directory = Directory(path);
      bool isFile = await file.exists();
      bool isDir = await directory.exists();
      String folderToOpen;
      if (isFile) {
        folderToOpen = file.parent.path;
      } else if (isDir) {
        folderToOpen = directory.path;
      } else {
        throw Exception('Arquivo ou pasta não encontrado: $path');
      }

      if (Platform.isWindows) {
        if (isFile) {
          await Process.run('explorer', ['/select,', path], runInShell: true);
          return true;
        } else {
          await Process.run('explorer', [folderToOpen], runInShell: true);
          return true;
        }
      } else {
        final uri = Uri.file(folderToOpen);
        return await launchUrl(uri);
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao abrir pasta: $e');
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
