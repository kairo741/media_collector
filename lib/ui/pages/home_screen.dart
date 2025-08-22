import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:media_collector/ui/widgets/media_list_view.dart';
import 'package:media_collector/ui/widgets/settings_dialog.dart';
import 'package:provider/provider.dart';

import '../widgets/directory_selector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            if (mediaProvider.selectedDirectory.isEmpty) {
              // Welcome screen pode rolar
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProgressIndicator(mediaProvider),
                    const DirectorySelector(),
                    if (mediaProvider.errorMessage != null) _buildErrorBanner(context, mediaProvider.errorMessage!),
                    _buildWelcomeScreen(context),
                  ],
                ),
              );
            } else {
              return Column(
                children: [
                  _buildProgressIndicator(mediaProvider),
                  if (mediaProvider.errorMessage != null) _buildErrorBanner(context, mediaProvider.errorMessage!),
                  Expanded(child: const MediaListView()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(Icons.video_library_outlined, size: 120, color: colorScheme.primary),
            ),
            const SizedBox(height: 32),
            Text(
              'Bem-vindo ao Media Collector',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Seu gerenciador pessoal de filmes e séries',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      context,
                      Icons.folder_open,
                      'Selecione uma pasta',
                      'Escolha a pasta onde estão seus arquivos de mídia',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      Icons.search,
                      'Busque e filtre',
                      'Encontre rapidamente o que você procura',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      Icons.play_arrow,
                      'Reproduza facilmente',
                      'Clique para abrir no seu player favorito',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(description, style: TextStyle(color: colorScheme.secondary, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red[100],
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Remove o banner de erro
            },
            color: Colors.red[700],
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Fechar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(MediaProvider provider) {
    return LinearProgressIndicator(value: provider.isScanning ? null : 0, backgroundColor: Colors.transparent);
  }

  PreferredSizeWidget _buildAppBar(BuildContext ctx) {
    final colorScheme = Theme.of(ctx).colorScheme;
    const iconButtonSize = 18.0;
    return AppBar(
      actionsPadding: EdgeInsets.only(right: 10),
      title: const Row(
        children: [
          Icon(Icons.video_library, color: Colors.white),
          SizedBox(width: 8),
          Text('Media Collector'),
        ],
      ),
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        const SizedBox(width: 5),
        Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            if (mediaProvider.selectedDirectory.isNotEmpty) {
              return Row(
                children: [
                  if (mediaProvider.totalItems > 0) ...[
                    _buildStatistics(mediaProvider),
                    const SizedBox(width: 10),
                    const VerticalDivider(width: 20, thickness: 1, indent: 20, endIndent: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                  ],
                  FilledButton.icon(
                    label: Text(mediaProvider.selectedDirectory, style: TextStyle(color: colorScheme.primary)),
                    icon: Icon(Icons.folder, color: colorScheme.primary, size: 24),
                    onPressed: mediaProvider.isScanning ? null : () => _selectDirectory(context),
                    style: FilledButton.styleFrom(backgroundColor: colorScheme.secondary.withAlpha(40)),
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: iconButtonSize),
                    onPressed: mediaProvider.isScanning ? null : () => _clearData(context),
                    tooltip: 'Limpar',
                    style: IconButton.styleFrom(backgroundColor: colorScheme.secondary.withAlpha(40)),
                    constraints: const BoxConstraints(minWidth: iconButtonSize, minHeight: iconButtonSize),
                    hoverColor: Colors.red.withAlpha(40),
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    icon: Icon(Icons.refresh, color: colorScheme.primary, size: iconButtonSize),
                    onPressed: mediaProvider.isScanning ? null : () => _rescanDirectory(context),
                    tooltip: 'Reescanear',
                    style: IconButton.styleFrom(backgroundColor: colorScheme.secondary.withAlpha(40)),
                    constraints: const BoxConstraints(minWidth: iconButtonSize, minHeight: iconButtonSize),
                  ),
                  const SizedBox(width: 5),
                  if (mediaProvider.errorMessage != null) ...[
                    const VerticalDivider(width: 20, thickness: 1, indent: 20, endIndent: 20, color: Colors.grey),
                    IconButton(
                      icon: const Icon(Icons.error, color: Colors.orange),
                      onPressed: () => _showErrorSnackBar(context, mediaProvider.errorMessage!),
                      tooltip: 'Ver erro',
                    ),
                  ],
                    const VerticalDivider(width: 20, thickness: 1, indent: 20, endIndent: 20, color: Colors.grey),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: 5),
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white, size: iconButtonSize),
          onPressed: () => _showSettingsDialog(ctx),
          tooltip: 'Configurações',
          style: IconButton.styleFrom(backgroundColor: colorScheme.secondary.withAlpha(40)),
          constraints: const BoxConstraints(minWidth: iconButtonSize, minHeight: iconButtonSize),
        ),
      ],
    );
  }

  Widget _buildStatistics(MediaProvider mediaProvider) {
    return Row(
      children: [
        _buildStatChip('Total: ${mediaProvider.totalItems}', Icons.video_library, Colors.grey),
        const SizedBox(width: 8),
        _buildStatChip('Filmes: ${mediaProvider.movieCount}', Icons.movie, Colors.blue),
        const SizedBox(width: 8),
        _buildStatChip('Séries: ${mediaProvider.seriesCount}', Icons.tv, Colors.green),
        const SizedBox(width: 4),
        const VerticalDivider(width: 20, thickness: 1, indent: 20, endIndent: 20, color: Colors.grey),
        const SizedBox(width: 4),
        _buildStatChip('Assistidos: ${mediaProvider.watchedCount}', Icons.visibility, Colors.green),
        const SizedBox(width: 8),
        _buildStatChip('Não assistidos: ${mediaProvider.unwatchedCount}', Icons.visibility_off, Colors.orange),
      ],
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
      if (context.mounted) {
        _showErrorDialog(context, 'Erro ao selecionar pasta: $e');
      }
    }
  }

  Future<void> _rescanDirectory(BuildContext context) async {
    try {
      final mediaProvider = context.read<MediaProvider>();
      await mediaProvider.scanDirectory(mediaProvider.selectedDirectory);
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Erro ao reescanear pasta: $e');
      }
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              context.read<MediaProvider>().resetSettings();
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }
}
