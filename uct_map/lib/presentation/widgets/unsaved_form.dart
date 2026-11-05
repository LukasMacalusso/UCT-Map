import 'package:flutter/material.dart';

/// Protege la salida del editor; los cambios se guardan individualmente en cada formulario.
class UnsavedForm extends StatefulWidget {
  const UnsavedForm({super.key, required this.formKey, required this.child});
  final GlobalKey<FormState> formKey;
  final Widget child;
  @override
  State<UnsavedForm> createState() => _UnsavedFormState();
}

class _UnsavedFormState extends State<UnsavedForm> {
  bool _dirty = false;
  bool _leaving = false;
  bool _asking = false;
  Future<void> _leave(bool didPop, Object? result) async {
    if (didPop || _asking || !_dirty) return;
    _asking = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Los cambios de este formulario todavía no se han guardado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    _asking = false;
    if (!mounted || discard != true) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_dirty || _leaving,
    onPopInvokedWithResult: _leave,
    child: Form(
      key: widget.formKey,
      onChanged: () {
        if (!_dirty) setState(() => _dirty = true);
      },
      child: widget.child,
    ),
  );
}
