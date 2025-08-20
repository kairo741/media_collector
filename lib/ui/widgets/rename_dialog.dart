import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_collector/core/models/media_item.dart';

class RenameDialog extends StatefulWidget {
  final MediaItem mediaItem;
  final String? currentCustomTitle;
  final Function(String) onRename;
  final VoidCallback? onRemoveCustomTitle;

  const RenameDialog({
    super.key,
    required this.mediaItem,
    this.currentCustomTitle,
    required this.onRename,
    this.onRemoveCustomTitle,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentCustomTitle ?? widget.mediaItem.title);
    _titleFocusNode = FocusNode();

    // Foca no campo de texto e seleciona todo o conteúdo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      _titleController.selection = TextSelection(baseOffset: 0, extentOffset: _titleController.text.length);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.mediaItem.type == MediaType.movie ? Icons.movie : Icons.tv,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('Renomear Mídia'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome original do arquivo
            Text('Arquivo:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              widget.mediaItem.fileName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Título original (se diferente do nome do arquivo)
            if (widget.mediaItem.title != widget.mediaItem.fileName) ...[
              Text(
                'Título Original:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                widget.mediaItem.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
            ],

            // Campo para título personalizado
            Text(
              'Título Personalizado:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            KeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  var isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter;
                  var isCtrlOrAltOrShiftPressed =
                      (HardwareKeyboard.instance.isShiftPressed ||
                      HardwareKeyboard.instance.isAltPressed ||
                      HardwareKeyboard.instance.isControlPressed);
                  if (isEnterPressed && !isCtrlOrAltOrShiftPressed) {
                    _handleRename();
                  }
                }
              },
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: InputDecoration(
                  hintText: 'Digite o novo título...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  helperText: 'Pressione Enter para salvar',
                  helperMaxLines: 2,
                ),
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                onSubmitted: (_) => _handleRename(),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'O título personalizado será salvo apenas no programa e não alterará o arquivo original.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        // Botão para remover título personalizado (se existir)
        if (widget.currentCustomTitle != null && widget.onRemoveCustomTitle != null)
          TextButton(
            onPressed: () {
              widget.onRemoveCustomTitle!();
              Navigator.of(context).pop();
            },
            child: const Text('Remover Personalização'),
          ),

        // Botão Cancelar
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),

        // Botão Salvar
        ElevatedButton(onPressed: _handleRename, child: const Text('Salvar')),
      ],
    );
  }

  void _handleRename() {
    final newTitle = _titleController.text.trim();

    if (newTitle.isEmpty) {
      // Se o campo estiver vazio, remove a personalização
      if (widget.onRemoveCustomTitle != null) {
        widget.onRemoveCustomTitle!();
      }
    } else {
      // Salva o novo título personalizado
      widget.onRename(newTitle);
    }

    Navigator.of(context).pop();
  }
}
