import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_collector/ui/providers/media_provider.dart';
import 'package:provider/provider.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _enableThumbnails = true;
  String _thumbnailQuality = 'medium';
  bool _autoScanOnStartup = true;
  List<String> _excludedExtensions = [];
  String _thumbnailsSize = '0 MB';
  bool _isCalculatingSize = false;
  String? _alternativePosterDirectory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
    });
  }

  void _loadCurrentSettings() {
    final mediaProvider = context.read<MediaProvider>();
    setState(() {
      _enableThumbnails = mediaProvider.enableThumbnails;
      _thumbnailQuality = mediaProvider.thumbnailQuality;
      _autoScanOnStartup = true; // Será carregado do SettingsService
      _excludedExtensions = List.from(mediaProvider.getExcludedExtensions());
      _alternativePosterDirectory = mediaProvider.getAlternativePosterDirectory();
    });
    _calculateThumbnailsSize();
  }

  Future<void> _calculateThumbnailsSize() async {
    if (_isCalculatingSize) return;

    setState(() {
      _isCalculatingSize = true;
    });

    try {
      final mediaProvider = context.read<MediaProvider>();
      final size = await mediaProvider.getThumbnailsSize();
      if (mounted) {
        setState(() {
          _thumbnailsSize = size;
          _isCalculatingSize = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _thumbnailsSize = 'Erro ao calcular';
          _isCalculatingSize = false;
        });
      }
    }
  }

  Future<void> _clearThumbnails() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Thumbnails'),
        content: const Text(
          'Tem certeza que deseja limpar todas as thumbnails? '
          'Isso liberará espaço em disco, mas as thumbnails serão regeneradas quando necessário.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final mediaProvider = context.read<MediaProvider>();
        final success = await mediaProvider.clearThumbnails();

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thumbnails limpas com sucesso!')));
            // Recalcula o tamanho após limpar
            await _calculateThumbnailsSize();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao limpar thumbnails')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao limpar thumbnails: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurações'),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnailSettings(),
              const Divider(),
              _buildPosterSettings(context),
              const Divider(),
              _buildGeneralSettings(),
              const Divider(),
              _buildCustomTitlesSettings(),
              const Divider(),
              _buildWatchedStatusSettings(),
              const Divider(),
              _buildExcludedExtensions(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _saveSettings, child: const Text('Salvar')),
      ],
    );
  }

  Widget _buildThumbnailSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thumbnails', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Gerar thumbnails automaticamente'),
          subtitle: const Text('Cria miniaturas para arquivos de vídeo'),
          value: _enableThumbnails,
          onChanged: (value) {
            setState(() {
              _enableThumbnails = value;
            });
          },
        ),
        if (_enableThumbnails) ...[
          const SizedBox(height: 8),
          const Text('Qualidade dos thumbnails:'),
          DropdownButtonFormField<String>(
            value: _thumbnailQuality,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Baixa (rápido)')),
              DropdownMenuItem(value: 'medium', child: Text('Média (padrão)')),
              DropdownMenuItem(value: 'high', child: Text('Alta (lento)')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _thumbnailQuality = value;
                });
              }
            },
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Espaço ocupado pelas thumbnails:', style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_isCalculatingSize)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Text(_thumbnailsSize, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isCalculatingSize ? null : _calculateThumbnailsSize,
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Recalcular',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isCalculatingSize ? null : _clearThumbnails,
                        icon: const Icon(Icons.delete_sweep, size: 18),
                        label: const Text('Limpar Thumbnails'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPosterSettings(BuildContext ctx) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Posters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pasta alternativa para posters', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text(
                    'Busca posters nesta pasta quando não encontrados no arquivo original',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showAlternativePosterDirectoryDialog,
              icon: Icon(Icons.folder, color: colorScheme.primary, size: 24),
              tooltip: 'Selecionar pasta de posters alternativos',
              style: IconButton.styleFrom(backgroundColor: colorScheme.secondary.withAlpha(40)),
            ),
          ],
        ),
        if (_alternativePosterDirectory != null) ...[
          const SizedBox(height: 8),
          const Text('Diretório de posters alternativos:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [ // TODO - Fazer possível várias pastas
              Chip(
                label: Text(_alternativePosterDirectory!),
                deleteIcon: Icon(Icons.clear, color: Colors.red),
                onDeleted: _clearAlternativePosterDirectory,
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Clique no botão de pasta para selecionar uma pasta que contenha posters para filmes e séries.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _clearAlternativePosterDirectory() {
    setState(() {
      _alternativePosterDirectory = null;
    });
  }

  Future<void> _clearAllCustomTitles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Títulos Personalizados'),
        content: const Text(
          'Tem certeza que deseja remover todos os títulos personalizados? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('Limpar Todos'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final mediaProvider = context.read<MediaProvider>();
        await mediaProvider.clearCustomTitles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos os títulos personalizados foram removidos!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao limpar títulos personalizados: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearAllWatchedStatus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Status de Assistido'),
        content: const Text(
          'Tem certeza que deseja remover todos os status de assistido? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Limpar Todos'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final mediaProvider = context.read<MediaProvider>();
        await mediaProvider.clearWatchedItems();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Todos os status de assistido foram removidos!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao limpar status de assistido: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAlternativePosterDirectoryDialog() async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Selecione a pasta de posters alternativos',
      );

      if (selectedDirectory != null) {
        setState(() {
          _alternativePosterDirectory = selectedDirectory;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao selecionar pasta: $e')));
      }
    }
  }

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Geral', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Escanear automaticamente na inicialização'),
          subtitle: const Text('Escaneia a pasta salva quando o app abrir'),
          value: _autoScanOnStartup,
          onChanged: (value) {
            setState(() {
              _autoScanOnStartup = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomTitlesSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Títulos Personalizados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Gerencie os títulos personalizados das suas mídias:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Os títulos personalizados são salvos apenas no programa e não alteram os arquivos originais.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _clearAllCustomTitles,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpar Todos os Títulos Personalizados'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWatchedStatusSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status de Assistido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Gerencie o status de assistido dos itens de mídia:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.visibility, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Os status de assistido são salvos apenas no programa e não alteram os arquivos originais.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _clearAllWatchedStatus,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpar Todos os Status de Assistido'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExcludedExtensions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Extensões Excluídas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Extensões que serão ignoradas durante o escaneamento:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ..._excludedExtensions.map(
              (ext) => Chip(
                label: Text(ext),
                onDeleted: () {
                  setState(() {
                    _excludedExtensions.remove(ext);
                  });
                },
              ),
            ),
            ActionChip(label: const Text('+ Adicionar'), onPressed: _showAddExtensionDialog),
          ],
        ),
      ],
    );
  }

  void _showAddExtensionDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Extensão'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Extensão (ex: .tmp)', hintText: '.tmp'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final extension = controller.text.trim();
              if (extension.isNotEmpty && !extension.startsWith('.')) {
                controller.text = '.$extension';
              }

              if (controller.text.isNotEmpty && !_excludedExtensions.contains(controller.text)) {
                setState(() {
                  _excludedExtensions.add(controller.text);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final mediaProvider = context.read<MediaProvider>();

    try {
      // Salva configurações de thumbnails
      await mediaProvider.setThumbnailSettings(
        enableThumbnails: _enableThumbnails,
        thumbnailQuality: _thumbnailQuality,
      );

      // Salva auto-scan
      await mediaProvider.setAutoScanOnStartup(_autoScanOnStartup);

      // Salva pasta alternativa de posters
      await mediaProvider.setAlternativePosterDirectory(_alternativePosterDirectory);

      // Salva extensões excluídas
      final currentExcluded = mediaProvider.getExcludedExtensions();

      // Remove extensões que não estão mais na lista
      for (final ext in currentExcluded) {
        if (!_excludedExtensions.contains(ext)) {
          await mediaProvider.removeExcludedExtension(ext);
        }
      }

      // Adiciona novas extensões
      for (final ext in _excludedExtensions) {
        if (!currentExcluded.contains(ext)) {
          await mediaProvider.addExcludedExtension(ext);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar configurações: $e')));
      }
    }
  }
}
