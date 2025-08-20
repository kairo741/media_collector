import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_collector/core/models/media_item.dart';
import 'package:media_collector/core/utils/string_extensions.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:media_collector/ui/widgets/rename_dialog.dart';
import 'package:media_collector/ui/widgets/series_episodes_screen.dart';
import 'package:provider/provider.dart';

class MediaListView extends StatefulWidget {
  const MediaListView({super.key});

  @override
  State<MediaListView> createState() => _MediaListViewState();
}

class _MediaListViewState extends State<MediaListView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 10),
            _buildSearchAndFilters(context, mediaProvider),
            const SizedBox(height: 10),
            Flexible(child: _buildMediaList(context, mediaProvider.filteredItems)),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, MediaProvider mediaProvider) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar filmes e séries...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          mediaProvider.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                mediaProvider.setSearchQuery(value);
              },
            ),
            const SizedBox(height: 16),
            // Filtros
            Row(
              children: [
                const Text('Filtrar por:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                _buildFilterChip(
                  context,
                  'Todos',
                  null,
                  mediaProvider.selectedFilter == null,
                  () => mediaProvider.setFilter(null),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Filmes',
                  MediaType.movie,
                  mediaProvider.selectedFilter == MediaType.movie,
                  () => mediaProvider.setFilter(MediaType.movie),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  'Séries',
                  MediaType.series,
                  mediaProvider.selectedFilter == MediaType.series,
                  () => mediaProvider.setFilter(MediaType.series),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, MediaType? filter, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withAlpha(50),
      checkmarkColor: colorScheme.secondary,
    );
  }

  Widget _buildMediaList(BuildContext context, List<MediaItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    // Grid responsivo
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double width = constraints.maxWidth;
        if (width > 1200) {
          crossAxisCount = 6;
        } else if (width > 900) {
          crossAxisCount = 5;
        } else if (width > 700) {
          crossAxisCount = 4;
        } else if (width > 500) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _MediaPosterCard(item: item);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum arquivo de mídia encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('Selecione uma pasta para começar a escanear', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _MediaPosterCard extends StatelessWidget {
  final MediaItem item;

  const _MediaPosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMovie = !(item.type == MediaType.series);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (!isMovie) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SeriesEpisodesScreen(seriesName: item.seriesName ?? item.title)));
        } else {
          context.read<MediaProvider>().openMediaFile(item);
        }
      },
      onSecondaryTapDown: (TapDownDetails details) => _showContextMenu(context, details.globalPosition),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: _buildPosterImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SizedBox(
                height: item.customTitle != null && item.title != item.fileName ? 40 : 25,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (item.customTitle != null && item.title != item.fileName)
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 48, // altura fixa para o footer
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open, size: 20),
                      tooltip: 'Abrir pasta',
                      onPressed: () {
                        context.read<MediaProvider>().openContainingFolder(item);
                      },
                    ),
                    Chip(
                      label: Text(isMovie ? "Filme" : "Série"),
                      backgroundColor: isMovie
                          ? colorScheme.primaryContainer.withAlpha(100)
                          : colorScheme.tertiaryContainer.withAlpha(100),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      tooltip: 'Informações',
                      onPressed: () {
                        _showFileInfo(context);
                        final mediaProvider = context.read<MediaProvider>();
                        final currentCustomTitle = mediaProvider.getCustomTitle(item);

                        showDialog(
                          context: context,
                          builder: (context) => RenameDialog(
                            mediaItem: item,
                            currentCustomTitle: currentCustomTitle,
                            onRename: (newTitle) {
                              mediaProvider.setCustomTitle(item, newTitle);
                            },
                            onRemoveCustomTitle: currentCustomTitle != null
                                ? () {
                                    mediaProvider.removeCustomTitle(item);
                                  }
                                : null,
                          ),
                        );
                      },
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

  Widget _buildPosterImage() {
    if (item.posterUrl != null && item.posterUrl!.isNotEmpty) {
      final url = item.posterUrl!;
      if (url.isUrl) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return Image.file(
          File(url),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(child: Icon(Icons.movie, size: 48, color: Colors.white24)),
    );
  }

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Nome do arquivo', item.fileName),
              _buildInfoRow('Caminho', item.filePath),
              _buildInfoRow('Tipo', item.type == MediaType.movie ? 'Filme' : 'Série'),
              if (item.seriesName != null) _buildInfoRow('Nome da série', item.seriesName!),
              if (item.seasonNumber != null) _buildInfoRow('Temporada', item.seasonNumber.toString()),
              if (item.episodeNumber != null) _buildInfoRow('Episódio', item.episodeNumber.toString()),
              if (item.year != null) _buildInfoRow('Ano', item.year!),
              if (item.quality != null) _buildInfoRow('Qualidade', item.quality!),
              if (item.language != null) _buildInfoRow('Idioma', item.language!),
              _buildInfoRow('Tamanho', item.fileSizeFormatted),
              _buildInfoRow('Modificado', _formatDate(item.lastModified)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 200, // Posiciona acima da posição do mouse
        position.dx + 200, // Largura do menu
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'play',
          child: Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Reproduzir'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'folder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Abrir pasta'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(
                context.read<MediaProvider>().getCustomTitle(item) != null ? Icons.edit : Icons.edit_outlined,
                color: context.read<MediaProvider>().getCustomTitle(item) != null ? Colors.orange : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(context.read<MediaProvider>().getCustomTitle(item) != null ? 'Editar título' : 'Renomear'),
            ],
          ),
        ),
        if (context.read<MediaProvider>().getCustomTitle(item) != null) ...[
          PopupMenuItem(
            value: 'remove_custom',
            child: Row(
              children: [
                Icon(Icons.clear, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text('Remover personalização'),
              ],
            ),
          ),
        ],
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text('Informações do arquivo'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (context.mounted) {
        switch (value) {
          case 'play':
            if (!(item.type == MediaType.series)) {
              context.read<MediaProvider>().openMediaFile(item);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SeriesEpisodesScreen(seriesName: item.seriesName ?? item.title)),
              );
            }
            break;
          case 'folder':
            context.read<MediaProvider>().openContainingFolder(item);
            break;
          case 'remove_custom':
            context.read<MediaProvider>().removeCustomTitle(item);
            break;
          case 'rename':
            final mediaProvider = context.read<MediaProvider>();
            final currentCustomTitle = mediaProvider.getCustomTitle(item);

            showDialog(
              context: context,
              builder: (context) => RenameDialog(
                mediaItem: item,
                currentCustomTitle: currentCustomTitle,
                onRename: (newTitle) {
                  mediaProvider.setCustomTitle(item, newTitle);
                },
                onRemoveCustomTitle: currentCustomTitle != null
                    ? () {
                        mediaProvider.removeCustomTitle(item);
                      }
                    : null,
              ),
            );
            break;
          case 'info':
            _showFileInfo(context);
            break;
        }
      }
    });
  }
}
