import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_collector/core/models/media_item.dart';
import 'package:media_collector/core/utils/ffmpeg_thumb_helper.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:media_collector/ui/widgets/rename_dialog.dart';
import 'package:provider/provider.dart';

class SeriesEpisodesScreen extends StatefulWidget {
  final String seriesName;

  const SeriesEpisodesScreen({super.key, required this.seriesName});

  @override
  State<SeriesEpisodesScreen> createState() => _SeriesEpisodesScreenState();
}

class _SeriesEpisodesScreenState extends State<SeriesEpisodesScreen> {
  @override
  Widget build(BuildContext context) {
    final mediaProvider = context.read<MediaProvider>();
    // Encontrar o MediaItem da série
    MediaItem? serie;
    try {
      serie = mediaProvider.mediaItems.firstWhere(
        (item) => item.type == MediaType.series && (item.seriesName ?? item.title) == widget.seriesName,
      );
    } catch (_) {
      serie = null;
    }
    if (serie == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.seriesName)),
        body: const Center(child: Text('Série não encontrada.')),
      );
    }
    return FutureBuilder<List<MediaItem>>(
      future: mediaProvider.scanSeriesEpisodes(serie.filePath, widget.seriesName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(serie?.displayTitle ?? widget.seriesName)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(serie?.displayTitle ?? widget.seriesName)),
            body: const Center(child: Text('Nenhum episódio encontrado.')),
          );
        }
        final episodes = snapshot.data!;
        // Agrupar por temporada
        final Map<String, List<MediaItem>> bySeason = {};
        for (final ep in episodes) {
          final season = ep.seasonNumber ?? '1';
          bySeason.putIfAbsent(season, () => []).add(ep);
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(serie?.displayTitle ?? widget.seriesName),
            actionsPadding: EdgeInsets.only(right: 15),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: bySeason.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final seasonEntry = entry.value;
              final season = seasonEntry.key;
              final eps = seasonEntry.value;
              eps.sort((a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0));
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  initiallyExpanded: index == 0, // Apenas a primeira temporada expandida
                  title: Text('Temporada $season', style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [_buildEpisodesGrid(eps)],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEpisodesGrid(List<MediaItem> episodes) {
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 16 / 11, // 16:9 + espaço para título e botões
          ),
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            return _buildEpisodeCard(episodes[index]);
          },
        );
      },
    );
  }

  Widget _buildEpisodeCard(MediaItem ep) {
    final isWatched = context.read<MediaProvider>().isWatched(ep);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.read<MediaProvider>().openMediaFile(ep),
        onSecondaryTapDown: (TapDownDetails details) => _showContextMenu(context, details.globalPosition, ep),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 26 / 9,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: FutureBuilder<String?>(
                      future: _getThumbPath(context, ep), // TODO - Fazer validação caso o usuário configure sem thumbs
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(File(snapshot.data!), fit: BoxFit.cover);
                        }
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(child: Icon(Icons.tv, size: 40, color: Colors.white24)),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    children: [
                      Text(
                        "${ep.episodeNumber != null ? '${ep.episodeNumber} | ' : ''}${ep.displayTitle}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (ep.customTitle != null && ep.title != ep.fileName)
                        Text(
                          ep.title,
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
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Reproduzir',
                        onPressed: () => context.read<MediaProvider>().openMediaFile(ep),
                      ),
                      IconButton(
                        icon: Icon(isWatched ? Icons.visibility_off : Icons.visibility, size: 20),
                        tooltip: isWatched ? 'Marcar como não assistido' : 'Marcar como assistido',
                        onPressed: () {
                          setState(() {
                            final mediaProvider = context.read<MediaProvider>();
                            final isCurrentlyWatched = mediaProvider.isWatched(ep);
                            mediaProvider.setWatched(ep, !isCurrentlyWatched);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isWatched) _buildWatchedFlag(),
          ],
        ),
      ),
    );
  }

  Future<String?> _getThumbPath(BuildContext context, MediaItem ep) async {
    final quality = context.read<MediaProvider>().thumbnailQuality;
    return await FFmpegThumbHelper.getThumb(ep.filePath, quality);
  }

  void _showFileInfo(BuildContext context, MediaItem ep) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ep.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Nome do arquivo', ep.fileName),
              _buildInfoRow('Caminho', ep.filePath),
              _buildInfoRow('Temporada', ep.seasonNumber?.toString() ?? '-'),
              _buildInfoRow('Episódio', ep.episodeNumber?.toString() ?? '-'),
              if (ep.year != null) _buildInfoRow('Ano', ep.year!),
              if (ep.quality != null) _buildInfoRow('Qualidade', ep.quality!),
              if (ep.language != null) _buildInfoRow('Idioma', ep.language!),
              _buildInfoRow('Tamanho', ep.fileSizeFormatted),
              _buildInfoRow('Modificado', _formatDate(ep.lastModified)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
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
          decoration: BoxDecoration(color: Color(0xffba1a1a), borderRadius: BorderRadius.circular(0)),
          child: Text("Assistido", style: TextStyle(fontSize: 20, letterSpacing: 5)),
        ),
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

  void _showContextMenu(BuildContext context, Offset position, MediaItem ep) {
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
                context.read<MediaProvider>().getCustomTitle(ep) != null ? Icons.edit : Icons.edit_outlined,
                color: context.read<MediaProvider>().getCustomTitle(ep) != null ? Colors.orange : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(context.read<MediaProvider>().getCustomTitle(ep) != null ? 'Editar título' : 'Renomear'),
            ],
          ),
        ),
        if (context.read<MediaProvider>().getCustomTitle(ep) != null) ...[
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
                context.read<MediaProvider>().isWatched(ep) ? Icons.visibility_off : Icons.visibility,
                color: context.read<MediaProvider>().isWatched(ep) ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(context.read<MediaProvider>().isWatched(ep) ? 'Marcar como não assistido' : 'Marcar como assistido'),
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
            context.read<MediaProvider>().openMediaFile(ep);
            break;
          case 'folder':
            context.read<MediaProvider>().openContainingFolder(ep);
            break;
          case 'remove_custom':
            setState(() {
              context.read<MediaProvider>().removeCustomTitle(ep);
            });
            break;
          case 'watched':
            final mediaProvider = context.read<MediaProvider>();
            final isCurrentlyWatched = mediaProvider.isWatched(ep);
            mediaProvider.setWatched(ep, !isCurrentlyWatched);
            break;
          case 'rename':
            final mediaProvider = context.read<MediaProvider>();
            final currentCustomTitle = mediaProvider.getCustomTitle(ep);
            showDialog(
              context: context,
              builder: (context) => RenameDialog(
                mediaItem: ep,
                currentCustomTitle: currentCustomTitle,
                onRename: (newTitle) {
                  setState(() {
                    mediaProvider.setCustomTitle(ep, newTitle);
                  });
                },
                onRemoveCustomTitle: currentCustomTitle != null
                    ? () {
                        setState(() {
                          mediaProvider.removeCustomTitle(ep);
                        });
                      }
                    : null,
              ),
            );
            break;
          case 'info':
            _showFileInfo(context, ep);
            break;
        }
      }
    });
  }
}
