import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:provider/provider.dart';

class DirectorySelector extends StatelessWidget {
  const DirectorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.folder_open, size: 24, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Pasta de Mídia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (mediaProvider.isScanning)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDirectoryMessage(context, mediaProvider),
                const SizedBox(height: 16),
                _buildRecentDirectories(context, mediaProvider),
                const SizedBox(height: 16),
                _buildActionButtons(context, mediaProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectoryMessage(BuildContext context, MediaProvider mediaProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (mediaProvider.selectedDirectory.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pasta selecionada:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mediaProvider.selectedDirectory,
                    style: TextStyle(color: colorScheme.onSecondaryContainer),
                  ),
                  if (mediaProvider.totalItems > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${mediaProvider.totalItems} arquivos encontrados',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nenhuma pasta selecionada. Selecione uma pasta para começar a escanear seus arquivos de mídia.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDirectories(BuildContext context, MediaProvider mediaProvider) {
    final recentDirs = mediaProvider.getRecentDirectories();
    
    if (recentDirs.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pastas Recentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentDirs.length,
            itemBuilder: (context, index) {
              final dir = recentDirs[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 8),
                child: Card(
                  child: InkWell(
                    onTap: () => _selectDirectory(context, dir),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.folder, size: 16, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  dir.split('\\').last.split('/').last,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dir,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaProvider mediaProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: mediaProvider.isScanning ? null : () => _selectDirectory(context),
            icon: const Icon(Icons.folder_open),
            label: Text(mediaProvider.selectedDirectory.isEmpty ? 'Selecionar Pasta' : 'Alterar Pasta'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        if (mediaProvider.selectedDirectory.isNotEmpty) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: mediaProvider.isScanning ? null : () => _rescanDirectory(context, mediaProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Reescanear pasta',
          ),
        ],
      ],
    );
  }

  Future<void> _selectDirectory(BuildContext context, [String? preSelectedPath]) async {
    final mediaProvider = context.read<MediaProvider>();

    try {
      String? selectedDirectory;
      
      if (preSelectedPath != null) {
        selectedDirectory = preSelectedPath;
      } else {
        selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Selecione a pasta de mídia',
        );
      }

      if (selectedDirectory != null) {
        await mediaProvider.scanDirectory(selectedDirectory);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Erro ao selecionar pasta: $e');
      }
    }
  }

  Future<void> _rescanDirectory(BuildContext context, MediaProvider mediaProvider) async {
    try {
      await mediaProvider.scanDirectory(mediaProvider.selectedDirectory);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Erro ao reescanear pasta: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
