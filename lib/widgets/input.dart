import 'package:fl_clash/common/app_localizations.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/dialog.dart';
import 'package:fl_clash/widgets/null_status.dart';
import 'package:flutter/material.dart';

import 'card.dart';
import 'float_layout.dart';
import 'list.dart';

class OptionsDialog<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final T value;
  final String Function(T value) textBuilder;

  const OptionsDialog({
    super.key,
    required this.title,
    required this.options,
    required this.textBuilder,
    required this.value,
  });

  @override
  State<OptionsDialog<T>> createState() => _OptionsDialogState();
}

class _OptionsDialogState<T> extends State<OptionsDialog<T>> {
  final _defaultValue = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context =
          GlobalObjectKey(widget.value ?? _defaultValue).currentContext;
      if (context != null) {
        Scrollable.ensureVisible(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: widget.title,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      child: Wrap(
        children: [
          for (final option in widget.options)
            ListItem.radio(
              key: GlobalObjectKey(option ?? _defaultValue),
              delegate: RadioDelegate(
                value: option,
                groupValue: widget.value,
                onChanged: (T? value) {
                  Navigator.of(context).pop(value);
                },
              ),
              title: Text(
                widget.textBuilder(option),
              ),
            ),
        ],
      ),
    );
  }
}

class CommonCheckBox extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool isCircle;

  const CommonCheckBox({
    required this.value,
    required this.onChanged,
    this.isCircle = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      shape: isCircle ? const CircleBorder() : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class InputDialog extends StatefulWidget {
  final String title;
  final String value;
  final String? suffixText;
  final String? resetValue;

  const InputDialog({
    super.key,
    required this.title,
    required this.value,
    this.suffixText,
    this.resetValue,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  late TextEditingController textController;

  String get value => widget.value;

  String get title => widget.title;

  String? get suffixText => widget.suffixText;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(
      text: value,
    );
  }

  _handleUpdate() async {
    final text = textController.value.text;
    Navigator.of(context).pop<String>(text);
  }

  _handleReset() async {
    if (widget.resetValue == null) {
      return;
    }
    Navigator.of(context).pop<String>(widget.resetValue);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: title,
      actions: [
        if (widget.resetValue != null &&
            textController.value.text != widget.resetValue) ...[
          TextButton(
            onPressed: _handleReset,
            child: Text(appLocalizations.reset),
          ),
          const SizedBox(
            width: 4,
          ),
        ],
        TextButton(
          onPressed: _handleUpdate,
          child: Text(appLocalizations.submit),
        )
      ],
      child: Wrap(
        runSpacing: 16,
        children: [
          TextField(
            maxLines: 1,
            minLines: 1,
            controller: textController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixText: suffixText,
            ),
            onSubmitted: (_) {
              _handleUpdate();
            },
          ),
        ],
      ),
    );
  }
}

class ListInputPage extends StatelessWidget {
  final String title;
  final List<String> items;
  final Widget Function(String item) titleBuilder;
  final Widget Function(String item)? subtitleBuilder;
  final Widget Function(String item)? leadingBuilder;
  final String? valueLabel;
  final Function(List<String> items) onChange;

  const ListInputPage({
    super.key,
    required this.title,
    required this.items,
    required this.titleBuilder,
    required this.onChange,
    this.leadingBuilder,
    this.valueLabel,
    this.subtitleBuilder,
  });

  _handleAddOrEdit([String? item]) async {
    uniqueValidator(String? value) {
      final index = items.indexWhere(
        (entry) {
          return entry == value;
        },
      );
      final current = item == value;
      if (index != -1 && !current) {
        return appLocalizations.valueExists;
      }
      return null;
    }

    final valueField = Field(
      label: valueLabel ?? appLocalizations.value,
      value: item ?? "",
      validator: uniqueValidator,
    );
    final value = await globalState.showCommonDialog<String>(
      child: AddDialog(
        valueField: valueField,
        title: title,
      ),
    );
    if (value == null) return;
    final index = items.indexWhere(
      (entry) {
        return entry == item;
      },
    );
    final nextItems = List<String>.from(items);
    if (item != null) {
      nextItems[index] = value;
    } else {
      nextItems.add(value);
    }
    onChange(nextItems);
  }

  _handleDelete(String? item) {
    final entries = List<String>.from(
      items,
    );
    final index = entries.indexWhere(
      (entry) {
        return entry == item;
      },
    );
    if (index != -1) {
      entries.removeAt(index);
    }
    onChange(entries);
  }

  @override
  Widget build(BuildContext context) {
    return FloatLayout(
      floatingWidget: FloatWrapper(
        child: FloatingActionButton(
          onPressed: () async {
            _handleAddOrEdit();
          },
          child: const Icon(Icons.add),
        ),
      ),
      child: items.isEmpty
          ? NullStatus(label: appLocalizations.noData)
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(
                bottom: 16 + 64,
                left: 16,
                right: 16,
              ),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final e = items[index];
                return Padding(
                  key: ValueKey(e),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: CommonCard(
                      child: ListItem(
                        leading:
                            leadingBuilder != null ? leadingBuilder!(e) : null,
                        title: titleBuilder(e),
                        subtitle: subtitleBuilder != null
                            ? subtitleBuilder!(e)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            _handleDelete(e);
                          },
                        ),
                      ),
                      onPressed: () {
                        _handleAddOrEdit(e);
                      },
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final nextItems = List<String>.from(items);
                final item = nextItems.removeAt(oldIndex);
                nextItems.insert(newIndex, item);
                onChange(nextItems);
              },
            ),
    );
  }
}

class MapInputPage extends StatelessWidget {
  final String title;
  final Map<String, String> map;
  final Widget Function(MapEntry<String, String> item) titleBuilder;
  final Widget Function(MapEntry<String, String> item)? subtitleBuilder;
  final Widget Function(MapEntry<String, String> item)? leadingBuilder;
  final String? keyLabel;
  final String? valueLabel;
  final Function(Map<String, String> items) onChange;

  const MapInputPage({
    super.key,
    required this.title,
    required this.map,
    required this.titleBuilder,
    required this.onChange,
    this.leadingBuilder,
    this.keyLabel,
    this.valueLabel,
    this.subtitleBuilder,
  });

  List<MapEntry<String, String>> get items =>
      List<MapEntry<String, String>>.from(
        map.entries,
      );

  _handleAddOrEdit([MapEntry<String, String>? item]) async {
    uniqueValidator(String? value) {
      final index = items.indexWhere(
        (entry) {
          return entry.key == value;
        },
      );
      final current = item?.key == value;
      if (index != -1 && !current) {
        return appLocalizations.keyExists;
      }
      return null;
    }

    final keyField = Field(
      label: keyLabel ?? appLocalizations.key,
      value: item == null ? "" : item.key,
      validator: uniqueValidator,
    );

    final valueField = Field(
      label: valueLabel ?? appLocalizations.value,
      value: item == null ? "" : item.value,
    );

    final value = await globalState.showCommonDialog<MapEntry<String, String>>(
      child: AddDialog(
        keyField: keyField,
        valueField: valueField,
        title: title,
      ),
    );
    if (value == null) return;
    final index = items.indexWhere(
      (entry) {
        return entry.key == item?.key;
      },
    );

    final nextItems = List<MapEntry<String, String>>.from(items);
    if (item != null) {
      nextItems[index] = value;
    } else {
      nextItems.add(value);
    }
    onChange(Map.fromEntries(nextItems));
  }

  _handleDelete(MapEntry<String, String> item) {
    final index = items.indexWhere(
      (entry) {
        return entry.key == item.key;
      },
    );
    if (index != -1) {
      items.removeAt(index);
    }
    onChange(Map.fromEntries(items));
  }

  @override
  Widget build(BuildContext context) {
    return FloatLayout(
      floatingWidget: FloatWrapper(
        child: FloatingActionButton(
          onPressed: () async {
            _handleAddOrEdit();
          },
          child: const Icon(Icons.add),
        ),
      ),
      child: items.isEmpty
          ? NullStatus(label: appLocalizations.noData)
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(
                bottom: 16 + 64,
                left: 16,
                right: 16,
              ),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              itemBuilder: (_, index) {
                final e = items[index];
                return Padding(
                  key: ValueKey(e.key),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: CommonCard(
                      child: ListItem(
                        leading:
                            leadingBuilder != null ? leadingBuilder!(e) : null,
                        title: titleBuilder(e),
                        subtitle: subtitleBuilder != null
                            ? subtitleBuilder!(e)
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            _handleDelete(e);
                          },
                        ),
                      ),
                      onPressed: () {
                        _handleAddOrEdit(e);
                      },
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final nextItems = List<MapEntry<String, String>>.from(items);
                final item = nextItems.removeAt(oldIndex);
                nextItems.insert(newIndex, item);
                onChange(Map.fromEntries(nextItems));
              },
            ),
    );
  }
}

class AddDialog extends StatefulWidget {
  final String title;
  final Field? keyField;
  final Field valueField;

  const AddDialog({
    super.key,
    required this.title,
    this.keyField,
    required this.valueField,
  });

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog> {
  TextEditingController? keyController;
  late TextEditingController valueController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Field? get keyField => widget.keyField;

  Field get valueField => widget.valueField;

  @override
  void initState() {
    super.initState();
    if (keyField != null) {
      keyController = TextEditingController(
        text: keyField!.value,
      );
    }
    valueController = TextEditingController(
      text: valueField.value,
    );
  }

  _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (keyField != null) {
      Navigator.of(context).pop<MapEntry<String, String>>(
        MapEntry(
          keyController!.text,
          valueController.text,
        ),
      );
    } else {
      Navigator.of(context).pop<String>(
        valueController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: widget.title,
      actions: [
        TextButton(
          onPressed: _submit,
          child: Text(appLocalizations.confirm),
        )
      ],
      child: Form(
        key: _formKey,
        child: Wrap(
          runSpacing: 16,
          children: [
            if (keyField != null)
              TextFormField(
                maxLines: 2,
                minLines: 1,
                controller: keyController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: keyField!.label,
                ),
                validator: (String? value) {
                  if (keyField!.validator != null) {
                    return keyField!.validator!(value);
                  }
                  if (value == null || value.isEmpty) {
                    return appLocalizations.notEmpty;
                  }
                  return null;
                },
              ),
            TextFormField(
              maxLines: 3,
              minLines: 1,
              controller: valueController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: valueField.label,
              ),
              validator: (String? value) {
                if (valueField.validator != null) {
                  return valueField.validator!(value);
                }
                if (value == null || value.isEmpty) {
                  return appLocalizations.notEmpty;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
