import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/lost_object_dto.dart';
import '../../../domain/entities/lost_object.dart';
import '../../../domain/repositories/lost_objects_repository.dart';

/// Formulario para registrar un nuevo objeto perdido con validaciones en tiempo real
/// y retroalimentación interactiva conforme al contrato del backend ASP.NET Core.
class CreateLostObjectScreen extends StatefulWidget {
  final LostObjectsRepository repository;

  const CreateLostObjectScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CreateLostObjectScreen> createState() => _CreateLostObjectScreenState();
}

class _CreateLostObjectScreenState extends State<CreateLostObjectScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _structureIdController = TextEditingController();
  final _photoUrlController = TextEditingController();

  LostObjectStatus _selectedStatus = LostObjectStatus.pending;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _previewUrl;

  // Estructuras de campus frecuentes de ejemplo para facilitar pruebas y uso
  static const Map<String, String> _presetStructures = {
    'Biblioteca Central': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
    'Edificio Aulario': 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
    'Gimnasio Techado': 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
  };

  @override
  void initState() {
    super.initState();
    _photoUrlController.addListener(_onPhotoUrlChanged);
  }

  void _onPhotoUrlChanged() {
    final text = _photoUrlController.text.trim();
    if (CreateLostObjectDto.isValidAbsoluteUrl(text)) {
      if (_previewUrl != text) {
        setState(() => _previewUrl = text);
      }
    } else {
      if (_previewUrl != null) {
        setState(() => _previewUrl = null);
      }
    }
  }

  @override
  void dispose() {
    _photoUrlController.removeListener(_onPhotoUrlChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _structureIdController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final dto = CreateLostObjectDto(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _selectedStatus,
      photoUrl: _photoUrlController.text.trim(),
      structureId: _structureIdController.text.trim(),
    );

    try {
      final response = await widget.repository.createLostObject(dto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Objeto registrado con éxito (ID: ${response.id})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      String message;
      if (e is ProblemDetailsException) {
        message = e.problemDetails.userMessage;
      } else if (e is ApiException) {
        message = e.message;
      } else if (e is ArgumentError) {
        message = e.message.toString();
      } else {
        message = 'Ocurrió un error inesperado al registrar el objeto.';
      }

      setState(() {
        _errorMessage = message;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _submit,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportar Objeto Perdido',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) _buildErrorBanner(),

                // Header explicativo
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.uctBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.uctBlue.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.uctBlue, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Ingresa los datos del objeto. Recuerda que la foto debe estar subida a un servidor público accesible.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                _buildFieldLabel('Título del objeto *'),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'Ej. Mochila negra con franja gris',
                    prefixIcon: Icons.title_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El título es obligatorio.';
                    }
                    if (value.trim().length < 3) {
                      return 'El título debe tener al menos 3 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Descripción
                _buildFieldLabel('Descripción detallada *'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'Detalla color, marca, lugar específico donde se encontró...',
                    prefixIcon: Icons.description_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria.';
                    }
                    if (value.trim().length < 5) {
                      return 'La descripción debe tener al menos 5 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Structure ID (UUID)
                _buildFieldLabel('ID de la Estructura / Edificio (UUID) *'),
                TextFormField(
                  controller: _structureIdController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'Ej. a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
                    prefixIcon: Icons.apartment_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El ID de la estructura es obligatorio.';
                    }
                    if (!CreateLostObjectDto.isValidUuid(value)) {
                      return 'Debe ser un UUID válido (ej. a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Chips rápidos para presets de estructuras
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _presetStructures.entries.map((entry) {
                    return ActionChip(
                      avatar: const Icon(Icons.place_outlined, size: 14),
                      label: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        setState(() {
                          _structureIdController.text = entry.value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // URL de la foto
                _buildFieldLabel('URL Pública de la Foto *'),
                TextFormField(
                  controller: _photoUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    hint: 'https://dominio.com/foto.jpg',
                    prefixIcon: Icons.image_outlined,
                    helperText: 'Acepta URLs directas http:// o https://',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La URL de la foto es obligatoria.';
                    }
                    if (!CreateLostObjectDto.isValidAbsoluteUrl(value)) {
                      return 'Ingresa una URL absoluta válida (debe empezar con http:// o https://).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Vista previa de la imagen
                if (_previewUrl != null) _buildImagePreview(_previewUrl!),

                const SizedBox(height: 18),

                // Selector de Estado inicial
                _buildFieldLabel('Estado inicial'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.fieldBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LostObjectStatus>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: LostObjectStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.label} (${s.value})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botón enviar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.uctBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _isSubmitting ? 'Guardando objeto...' : 'Publicar Objeto Perdido',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildImagePreview(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey.shade100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 160,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.red.shade50,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'No se pudo cargar la imagen desde la URL provista.',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Vista Previa',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade900, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      helperMaxLines: 2,
      prefixIcon: Icon(prefixIcon, color: AppColors.subtitle, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.uctBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }
}
