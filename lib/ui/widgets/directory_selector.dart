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
                    const Text(
                      'Pasta de Mídia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (mediaProvider.isScanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDirectoryInfo(context, mediaProvider),
                const SizedBox(height: 16),
                _buildActionButtons(context, mediaProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectoryInfo(BuildContext context, MediaProvider mediaProvider) {

    final colorScheme = Theme.of(context).colorScheme;
    if (mediaProvider.selectedDirectory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nenhuma pasta selecionada. Selecione uma pasta para começar a escanear seus arquivos de mídia.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mediaProvider.selectedDirectory,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          if (mediaProvider.totalItems > 0) ...[
            const SizedBox(height: 8),
            _buildStatistics(mediaProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics(MediaProvider mediaProvider) {
    return Row(
      children: [
        _buildStatChip(
          'Total: ${mediaProvider.totalItems}',
          Icons.video_library,
          Colors.grey,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          'Filmes: ${mediaProvider.movieCount}',
          Icons.movie,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          'Séries: ${mediaProvider.seriesCount}',
          Icons.tv,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MediaProvider mediaProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: mediaProvider.isScanning ? null : () => _selectDirectory(context),
            icon: const Icon(Icons.folder_open),
            label: Text(
              mediaProvider.selectedDirectory.isEmpty ? 'Selecionar Pasta' : 'Alterar Pasta',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (mediaProvider.selectedDirectory.isNotEmpty) ...[
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: mediaProvider.isScanning ? null : () => _rescanDirectory(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Reescanear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: mediaProvider.isScanning ? null : () => _clearData(context),
            icon: const Icon(Icons.clear),
            label: const Text('Limpar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _selectDirectory(BuildContext context) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecione a pasta de mídia',
      );

      if (selectedDirectory != null) {
        await context.read<MediaProvider>().scanDirectory(selectedDirectory);
      }
    } catch (e) {
      _showErrorDialog(context, 'Erro ao selecionar pasta: $e');
    }
  }

  Future<void> _rescanDirectory(BuildContext context) async {
    try {
      final mediaProvider = context.read<MediaProvider>();
      await mediaProvider.scanDirectory(mediaProvider.selectedDirectory);
    } catch (e) {
      _showErrorDialog(context, 'Erro ao reescanear pasta: $e');
    }
  }

  void _clearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Dados'),
        content: const Text(
          'Tem certeza que deseja limpar todos os dados escaneados? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<MediaProvider>().clearData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 