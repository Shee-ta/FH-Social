import 'package:flutter/material.dart';
import 'package:frontend/entity/event.dart';

class TagsSelector extends StatefulWidget {
  const TagsSelector({
    super.key,
    required this.closeEventList,
    required this.availableTags,
    required this.disabledTags,
    required this.setTag,
  });

  final void Function(List<Event> events, {bool forceClose}) closeEventList; 
  final void Function(bool isSelected, String tag) setTag;
  final Map<String, int> availableTags;
  final List<String> disabledTags;

  @override
  State<TagsSelector> createState() => _TagsSelectorState();
}

class _TagsSelectorState extends State<TagsSelector> {
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      style: MenuStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.all(8),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.availableTags.entries.map((e) {
                  return FilterChip(
                    label: Padding(
                      padding: const EdgeInsets.all(4), 
                      child: Text('${e.key} (${e.value})')),
                    selected: !widget.disabledTags.contains(e.key),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          widget.setTag(true, e.key);
                        } else {
                          widget.setTag(false, e.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return ElevatedButton(
          onPressed: () => {
            widget.closeEventList(List.empty(), forceClose: true),
            controller.isOpen
            ? controller.close()
            : controller.open(),
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            iconSize: 40,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(24),
          ),
          child: Icon(Icons.filter_list_alt),
        );
      },
    );
  }
}