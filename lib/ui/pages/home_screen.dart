import 'package:flutter/material.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/directory_selector.dart';
import '../widgets/media_list_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
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
          Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              if (mediaProvider.errorMessage != null) {
                return IconButton(
                  icon: const Icon(Icons.error, color: Colors.orange),
                  onPressed: () => _showErrorSnackBar(context, mediaProvider.errorMessage!),
                  tooltip: 'Ver erro',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<MediaProvider>(
          builder: (context, mediaProvider, child) {
            if (mediaProvider.selectedDirectory.isEmpty) {
              // Welcome screen pode rolar
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const DirectorySelector(),
                    if (mediaProvider.errorMessage != null) _buildErrorBanner(context, mediaProvider.errorMessage!),
                    _buildWelcomeScreen(context),
                  ],
                ),
              );
            } else {
              // Listagem ocupa espaço normalmente
              return Column(
                children: [
                  const DirectorySelector(),
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
              child:Padding(
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
              context.read<MediaProvider>().clearData();
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
}
