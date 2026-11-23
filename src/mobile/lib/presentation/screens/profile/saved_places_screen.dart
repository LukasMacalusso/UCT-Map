import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key, this.onNavigateToTab});
  final Function(int)? onNavigateToTab;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Lugares guardados'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
    ),
    body: const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Todavía no hay una función para guardar lugares en tu cuenta. Puedes consultar los espacios desde Mapa y Buscar.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
