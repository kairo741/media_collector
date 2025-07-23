import 'package:flutter/material.dart';
import 'package:media_collector/core/models/media_item.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:provider/provider.dart';
import 'ffmpeg_thumb_helper.dart';
import 'dart:io';

class SerieEpisodesScreen extends StatelessWidget {
  final String seriesName;
  const SerieEpisodesScreen({super.key, required this.seriesName});

  @override
  Widget build(BuildContext context) {
    final episodes = context.read<MediaProvider>().mediaItems
      .where((item) => item.type == MediaType.series && (item.seriesName ?? item.title) == seriesName)
      .toList();
    if (episodes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(seriesName)),
        body: const Center(child: Text('Nenhum episódio encontrado.')),
      );
    }
    // Agrupar por temporada
    final Map<int, List<MediaItem>> bySeason = {};
    for (final ep in episodes) {
      final season = ep.seasonNumber ?? 1;
      bySeason.putIfAbsent(season, () => []).add(ep);
    }
    return Scaffold(
      appBar: AppBar(title: Text(seriesName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: bySeason.entries.map((entry) {
          final season = entry.key;
          final eps = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: Text('Temporada $season', style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                _EpisodesGrid(episodes: eps),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EpisodesGrid extends StatelessWidget {
  final List<MediaItem> episodes;
  const _EpisodesGrid({required this.episodes});

  @override
  Widget build(BuildContext context) {
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
            return _EpisodeCard(ep: episodes[index]);
          },
        );
      },
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final MediaItem ep;
  const _EpisodeCard({required this.ep});

  Future<String?> _getThumbPath() async {
    return await FFmpegThumbHelper.getThumb(ep.filePath);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.read<MediaProvider>().openMediaFile(ep),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 21.6 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: FutureBuilder<String?>(
                  future: _getThumbPath(),
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
              child: Text(
                ep.displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
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
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Informações',
                    onPressed: () => _showFileInfo(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ep.displayTitle),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}