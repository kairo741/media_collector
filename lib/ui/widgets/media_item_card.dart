import 'package:flutter/material.dart';
import 'package:media_collector/core/models/media_item.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:provider/provider.dart';

class MediaItemCard extends StatelessWidget {
  final MediaItem item;

  const MediaItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () => _openMediaFile(context),
        onSecondaryTap: () => _showContextMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.seriesName != null && item.type == MediaType.series)
                          Text(
                            'Série: ${item.seriesName}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(context),
              const SizedBox(height: 8),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData iconData;
    Color iconColor;

    switch (item.type) {
      case MediaType.movie:
        iconData = Icons.movie;
        iconColor = Colors.blue;
        break;
      case MediaType.series:
        iconData = Icons.tv;
        iconColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Row(
      children: [
        if (item.year != null) ...[
          _buildInfoChip('${item.year}', Icons.calendar_today),
          const SizedBox(width: 8),
        ],
        if (item.quality != null) ...[
          _buildInfoChip(item.quality!, Icons.high_quality),
          const SizedBox(width: 8),
        ],
        if (item.language != null) ...[
          _buildInfoChip(item.language!, Icons.language),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            item.fileSizeFormatted,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () => _openMediaFile(context),
          icon: const Icon(Icons.play_arrow),
          tooltip: 'Reproduzir',
          color: Colors.green,
        ),
        IconButton(
          onPressed: () => _openContainingFolder(context),
          icon: const Icon(Icons.folder_open),
          tooltip: 'Abrir pasta',
          color: Colors.blue,
        ),
        IconButton(
          onPressed: () => _showContextMenu(context),
          icon: const Icon(Icons.more_vert),
          tooltip: 'Mais opções',
        ),
      ],
    );
  }

  void _openMediaFile(BuildContext context) {
    context.read<MediaProvider>().openMediaFile(item);
  }

  void _openContainingFolder(BuildContext context) {
    context.read<MediaProvider>().openContainingFolder(item);
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildContextMenu(context),
    );
  }

  Widget _buildContextMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.green),
            title: const Text('Reproduzir'),
            onTap: () {
              Navigator.pop(context);
              _openMediaFile(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open, color: Colors.blue),
            title: const Text('Abrir pasta'),
            onTap: () {
              Navigator.pop(context);
              _openContainingFolder(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.orange),
            title: const Text('Informações do arquivo'),
            onTap: () {
              Navigator.pop(context);
              _showFileInfo(context);
            },
          ),
        ],
      ),
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
              _buildInfoRow2('Nome do arquivo', item.fileName),
              _buildInfoRow2('Caminho', item.filePath),
              _buildInfoRow2('Tipo', item.type == MediaType.movie ? 'Filme' : 'Série'),
              if (item.seriesName != null)
                _buildInfoRow2('Nome da série', item.seriesName!),
              if (item.seasonNumber != null)
                _buildInfoRow2('Temporada', item.seasonNumber.toString()),
              if (item.episodeNumber != null)
                _buildInfoRow2('Episódio', item.episodeNumber.toString()),
              if (item.year != null)
                _buildInfoRow2('Ano', item.year!),
              if (item.quality != null)
                _buildInfoRow2('Qualidade', item.quality!),
              if (item.language != null)
                _buildInfoRow2('Idioma', item.language!),
              _buildInfoRow2('Tamanho', item.fileSizeFormatted),
              _buildInfoRow2('Modificado', _formatDate(item.lastModified)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow2(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
} 