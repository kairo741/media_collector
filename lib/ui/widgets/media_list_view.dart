import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_collector/core/models/media_item.dart';
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
  final ScrollController _recentsScrollController = ScrollController();
  bool _showLeftButton = false;
  bool _showRightButton = false;

  @override
  void initState() {
    super.initState();
    _recentsScrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recentsScrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    setState(() {
      _showLeftButton = _recentsScrollController.hasClients && _recentsScrollController.offset > 0;
      _showRightButton =
          _recentsScrollController.hasClients &&
          _recentsScrollController.offset < _recentsScrollController.position.maxScrollExtent;
    });
  }

  void _scrollRecents(bool forward) {
    if (!_recentsScrollController.hasClients) return;

    final double offset = forward ? 700.0 : -700.0;
    _recentsScrollController.animateTo(
      _recentsScrollController.offset + offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        final recentUnwatchedItems = mediaProvider.showRecentSection
            ? mediaProvider.getRecentlyOpenedUnwatchedMedia()
            : <MediaItem>[];

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 10),
            _buildSearchAndFilters(context, mediaProvider),
            const SizedBox(height: 10),
            Flexible(
              child: _buildMediaList(
                context,
                mediaProvider.filteredItems,
                recentUnwatchedItems: recentUnwatchedItems,
              ),
            ),
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
                // Filtro de status assistido
                const SizedBox(width: 20),
                const SizedBox(
                  height: 20,
                  child: VerticalDivider(width: 10, thickness: 1, color: Colors.grey),
                ),
                const SizedBox(width: 20),
                const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                _buildWatchedFilterChip(
                  context,
                  'Todos',
                  null,
                  mediaProvider.watchedFilter == null,
                  () => mediaProvider.setWatchedFilter(null),
                ),
                const SizedBox(width: 8),
                _buildWatchedFilterChip(
                  context,
                  'Não assistidos',
                  false,
                  mediaProvider.watchedFilter == false,
                  () => mediaProvider.setWatchedFilter(false),
                ),
                const SizedBox(width: 8),
                _buildWatchedFilterChip(
                  context,
                  'Assistidos',
                  true,
                  mediaProvider.watchedFilter == true,
                  () => mediaProvider.setWatchedFilter(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    MediaType? filter,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withAlpha(50),
      checkmarkColor: colorScheme.secondary,
    );
  }

  Widget _buildWatchedFilterChip(
    BuildContext context,
    String label,
    bool? filter,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.tertiary.withAlpha(50),
      checkmarkColor: colorScheme.tertiary,
    );
  }

  Widget _buildMediaList(
    BuildContext context,
    List<MediaItem> items, {
    List<MediaItem>? recentUnwatchedItems,
  }) {
    if (items.isEmpty && (recentUnwatchedItems == null || recentUnwatchedItems.isEmpty)) {
      return _buildEmptyState(context);
    }

    // Grid responsivo usando CustomScrollView para integrar recentes com o grid
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

        return CustomScrollView(
          slivers: [
            // Seção de Recentes
            if (recentUnwatchedItems != null && recentUnwatchedItems.isNotEmpty)
              _buildRecentsSection(recentUnwatchedItems),

            // Grid de mídias
            if (items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = items[index];
                    return _MediaPosterCard(item: item);
                  }, childCount: items.length),
                ),
              ),
          ],
        );
      },
    );
  }

  SliverToBoxAdapter _buildRecentsSection(List<MediaItem> recentUnwatchedItems) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _recentsScrollController.hasClients) {
        _updateScrollButtons();
      }
    });

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recentes',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${recentUnwatchedItems.length} ${recentUnwatchedItems.length == 1 ? 'item' : 'itens'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      ScrollConfiguration(
                        behavior: ScrollConfiguration.of(
                          context,
                        ).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                        child: ListView.builder(
                          controller: _recentsScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: recentUnwatchedItems.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 140,
                                child: _buildRecentItem(recentUnwatchedItems[index]),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_showLeftButton)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Theme.of(context).colorScheme.surface.withAlpha(230),
                                  Theme.of(context).colorScheme.surface.withAlpha(0),
                                ],
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left, size: 32),
                              onPressed: () => _scrollRecents(false),
                              tooltip: 'Anterior',
                            ),
                          ),
                        ),
                      if (_showRightButton)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Theme.of(context).colorScheme.surface.withAlpha(230),
                                  Theme.of(context).colorScheme.surface.withAlpha(0),
                                ],
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right, size: 32),
                              onPressed: () => _scrollRecents(true),
                              tooltip: 'Próximo',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItem(MediaItem item) {
    final isMovie = !(item.type == MediaType.series);

    final posterPlaceholder = Container(
      color: Colors.grey[900],
      child: const Center(child: Icon(Icons.movie, size: 48, color: Colors.white24)),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (!isMovie) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SeriesEpisodesScreen(seriesName: item.seriesName ?? item.title),
            ),
          );
        } else {
          context.read<MediaProvider>().openMediaFile(item);
        }
      },
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
                child: item.posterUrl != null
                    ? Image.file(
                        File(item.posterUrl!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => posterPlaceholder,
                      )
                    : posterPlaceholder,
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (item.customTitle != null && item.title != item.fileName)
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
          Text(
            'Selecione uma pasta para começar a escanear',
            style: TextStyle(color: Colors.grey[500]),
          ),
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
    final isWatched = context.read<MediaProvider>().isWatched(item);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (!isMovie) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SeriesEpisodesScreen(seriesName: item.seriesName ?? item.title),
            ),
          );
        } else {
          context.read<MediaProvider>().openMediaFile(item);
        }
      },
      onSecondaryTapDown: (TapDownDetails details) =>
          _showContextMenu(context, details.globalPosition),
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
                child: _buildPosterImage(context),
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (item.customTitle != null && item.title != item.fileName)
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
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
                      icon: Icon(isWatched ? Icons.visibility_off : Icons.visibility, size: 20),
                      tooltip: isWatched ? 'Marcar como não assistido' : 'Marcar como assistido',
                      onPressed: () {
                        final mediaProvider = context.read<MediaProvider>();
                        final isCurrentlyWatched = mediaProvider.isWatched(item);
                        mediaProvider.setWatched(item, !isCurrentlyWatched);
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

  Widget _buildPosterImage(BuildContext context) {
    if (item.posterUrl != null && item.posterUrl!.isNotEmpty) {
      return Stack(
        children: [
          Image.file(
            File(item.posterUrl!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          ),
          // Indicador de status assistido
          if (context.read<MediaProvider>().isWatched(item)) _buildWatchedFlag(),
        ],
      );
    }
    return Stack(
      children: [
        _buildPlaceholderImage(),
        // Indicador de status assistido
        if (context.read<MediaProvider>().isWatched(item)) _buildWatchedFlag(),
      ],
    );
  }

  Widget _buildWatchedFlag() {
    return Positioned(
      top: 23,
      right: -38,
      child: Transform.rotate(
        angle: 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: Color(0xffba1a1a),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Text("Assistido", style: TextStyle(fontSize: 20, letterSpacing: 5)),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
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
              if (item.seasonNumber != null)
                _buildInfoRow('Temporada', item.seasonNumber.toString()),
              if (item.episodeNumber != null)
                _buildInfoRow('Episódio', item.episodeNumber.toString()),
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
                context.read<MediaProvider>().getCustomTitle(item) != null
                    ? Icons.edit
                    : Icons.edit_outlined,
                color: context.read<MediaProvider>().getCustomTitle(item) != null
                    ? Colors.orange
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.read<MediaProvider>().getCustomTitle(item) != null
                    ? 'Editar título'
                    : 'Renomear',
              ),
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
          value: 'watched',
          child: Row(
            children: [
              Icon(
                context.read<MediaProvider>().isWatched(item)
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: context.read<MediaProvider>().isWatched(item) ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.read<MediaProvider>().isWatched(item)
                    ? 'Marcar como não assistido'
                    : 'Marcar como assistido',
              ),
            ],
          ),
        ),
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
                MaterialPageRoute(
                  builder: (_) => SeriesEpisodesScreen(seriesName: item.seriesName ?? item.title),
                ),
              );
            }
            break;
          case 'folder':
            context.read<MediaProvider>().openContainingFolder(item);
            break;
          case 'remove_custom':
            context.read<MediaProvider>().removeCustomTitle(item);
            break;
          case 'watched':
            final mediaProvider = context.read<MediaProvider>();
            final isCurrentlyWatched = mediaProvider.isWatched(item);
            mediaProvider.setWatched(item, !isCurrentlyWatched);
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
