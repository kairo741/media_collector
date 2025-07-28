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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
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
      ],
    );
  }

  Future<void> _selectDirectory(BuildContext context) async {
    // Captura do MediaProvider antes da operação assíncrona
    final mediaProvider = context.read<MediaProvider>();

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Selecione a pasta de mídia');

      if (selectedDirectory != null) {
        await mediaProvider.scanDirectory(selectedDirectory);
      }
    } catch (e) {
      // Verifica se o contexto ainda é válido antes de mostrar o diálogo
      if (context.mounted) {
        _showErrorDialog(context, 'Erro ao selecionar pasta: $e');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}
