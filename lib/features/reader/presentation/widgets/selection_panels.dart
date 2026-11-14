import 'package:flutter/material.dart';

import '../../../../core/db/app_database.dart';
import '../../../dictionary/dictionary_view.dart';
import '../../data/reader_bridge.dart';
import '../../domain/reader_palette.dart';

/// Floating panel shown while text is selected. A single word gets an
/// inline definition, like Kindle.
class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    required this.selection,
    required this.onHighlight,
    required this.onNote,
    required this.onCopy,
    required this.onSearch,
    required this.onDefine,
    required this.onClose,
    super.key,
  });

  final ReaderSelection selection;
  final ValueChanged<int> onHighlight;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onSearch;
  final ValueChanged<String> onDefine;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = selection.singleWord;
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DictionaryPreview(
                  word: word,
                  onMore: () => onDefine(word),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8, bottom: 4),
                child: Text(
                  '“${selection.text}”',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'serif',
                  ),
                ),
              ),
            const Divider(height: 12),
            // Two rows so the panel fits narrow (320dp) phones: colours plus
            // close, then the actions, which wrap rather than overflow.
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    children: [
                      for (
                        var index = 0;
                        index < highlightSwatches.length;
                        index++
                      )
                        _SwatchButton(
                          color: highlightSwatches[index],
                          label: 'Highlight ${highlightSwatchNames[index]}',
                          onTap: () => onHighlight(index),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
            Wrap(
              spacing: 2,
              children: [
                _ActionButton(
                  icon: Icons.edit_note,
                  label: 'Note',
                  onPressed: onNote,
                ),
                _ActionButton(
                  icon: Icons.copy,
                  label: 'Copy',
                  onPressed: onCopy,
                ),
                _ActionButton(
                  icon: Icons.search,
                  label: 'Search',
                  onPressed: onSearch,
                ),
                if (word != null)
                  _ActionButton(
                    icon: Icons.menu_book_outlined,
                    label: 'Define',
                    onPressed: () => onDefine(word),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.color,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check, size: 16, color: Color(0xFF2B2B2B))
                : null,
          ),
        ),
      ),
    );
  }
}

Future<String?> showNoteDialog(
  BuildContext context, {
  String? initial,
  String? quote,
}) async {
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(initial == null ? 'Add note' : 'Edit note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quote != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '“$quote”',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'serif'),
              ),
            ),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Your thoughts…'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

/// Sheet for an existing highlight: recolour, edit note, define, delete.
Future<void> showHighlightSheet(
  BuildContext context, {
  required Highlight highlight,
  required ValueChanged<int> onColor,
  required VoidCallback onEditNote,
  required VoidCallback onDelete,
  required ValueChanged<String> onDefine,
}) {
  final word = ReaderSelection(
    cfiRange: highlight.cfiRange,
    text: highlight.selectedText,
    chapterTitle: '',
  ).singleWord;
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '“${highlight.selectedText}”',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'serif',
                  ),
                ),
              ),
              if (highlight.note?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Text(
                    highlight.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      children: [
                        for (
                          var index = 0;
                          index < highlightSwatches.length;
                          index++
                        )
                          _SwatchButton(
                            color: highlightSwatches[index],
                            label: highlightSwatchNames[index],
                            selected: highlight.color == index,
                            onTap: () {
                              Navigator.pop(context);
                              onColor(index);
                            },
                          ),
                      ],
                    ),
                  ),
                  if (word != null)
                    IconButton(
                      tooltip: 'Define',
                      icon: const Icon(Icons.menu_book_outlined),
                      onPressed: () {
                        Navigator.pop(context);
                        onDefine(word);
                      },
                    ),
                  IconButton(
                    tooltip: highlight.note?.isNotEmpty == true
                        ? 'Edit note'
                        : 'Add note',
                    icon: const Icon(Icons.edit_note),
                    onPressed: () {
                      Navigator.pop(context);
                      onEditNote();
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete highlight',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
