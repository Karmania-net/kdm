import 'package:flutter/material.dart';
import 'package:kdm/l10n/app_localizations.dart';

class AddUrlDialog extends StatefulWidget {
  const AddUrlDialog({super.key});

  @override
  State<AddUrlDialog> createState() => _AddUrlDialogState();
}

class _AddUrlDialogState extends State<AddUrlDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addUrl),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.urlHint,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return l10n.invalidUrl;
            final uri = Uri.tryParse(value.trim());
            if (uri == null || !uri.hasScheme) return l10n.invalidUrl;
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final url = _controller.text.trim();
              Navigator.of(context).pop(url);
            }
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }
}
