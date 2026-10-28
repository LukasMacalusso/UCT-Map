import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/lost_object_dto.dart';
import '../../../data/models/report_dto.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/repositories/reports_repository.dart';

/// Formulario para crear un nuevo Reporte / Ticket con soporte para Quejas/Reclamos
/// y vinculación opcional con Objetos Perdidos.
class CreateTicketScreen extends StatefulWidget {
  final ReportsRepository repository;
  final String? initialLostObjectId;

  const CreateTicketScreen({
    super.key,
    required this.repository,
    this.initialLostObjectId,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();

  final _structureRefIdController = TextEditingController();
  final _lostObjectIdController = TextEditingController();
  final _complaintTitleController = TextEditingController();
  final _complaintDescriptionController = TextEditingController();

  TicketStatus _selectedTicketType = TicketStatus.pending;
  ComplaintStatus _selectedComplaintStatus = ComplaintStatus.claim;
  bool _includeComplaint = true;
  bool _isActive = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Map<String, String> _presetStructures = {
    'Biblioteca Central': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
    'Edificio Aulario': 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e',
    'Gimnasio Techado': 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialLostObjectId != null) {
      _lostObjectIdController.text = widget.initialLostObjectId!;
    }
  }

  @override
  void dispose() {
    _structureRefIdController.dispose();
    _lostObjectIdController.dispose();
    _complaintTitleController.dispose();
    _complaintDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    CreateComplaintDto? complaintDto;
    if (_includeComplaint) {
      complaintDto = CreateComplaintDto(
        title: _complaintTitleController.text.trim(),
        description: _complaintDescriptionController.text.trim(),
        status: _selectedComplaintStatus,
      );
    }

    final dto = CreateReportDto(
      structureRefId: _structureRefIdController.text.trim(),
      ticketType: _selectedTicketType,
      isActive: _isActive,
      reportedAt: DateTime.now(),
      lostObjectId: _lostObjectIdController.text.trim().isNotEmpty
          ? _lostObjectIdController.text.trim()
          : null,
      complaint: complaintDto,
    );

    try {
      final response = await widget.repository.createReport(dto);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reporte registrado con éxito (ID: ${response.id})',
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
        message = 'Ocurrió un error inesperado al registrar el reporte.';
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
          'Crear Reporte / Incidencia',
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
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.uctBlue, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El autor del reporte se asignará automáticamente desde tu sesión (Token JWT) por seguridad.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ID Estructura
                _buildFieldLabel('ID de la Estructura / Edificio (UUID) *'),
                TextFormField(
                  controller: _structureRefIdController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'Ej. a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
                    prefixIcon: Icons.apartment_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'El ID de la estructura es obligatorio.';
                    }
                    if (!CreateLostObjectDto.isValidUuid(val)) {
                      return 'Debe ser un formato UUID válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Chips de atajos de edificios
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _presetStructures.entries.map((entry) {
                    return ActionChip(
                      avatar: const Icon(Icons.place_outlined, size: 14),
                      label: Text(entry.key, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        setState(() {
                          _structureRefIdController.text = entry.value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Tipo de Ticket / Estado inicial
                _buildFieldLabel('Tipo de Ticket (Estado Inicial)'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.fieldBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TicketStatus>(
                      value: _selectedTicketType,
                      isExpanded: true,
                      items: TicketStatus.values.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.label} (${s.value})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedTicketType = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ID de Objeto Perdido asociado (opcional)
                _buildFieldLabel('ID de Objeto Perdido Asociado (Opcional)'),
                TextFormField(
                  controller: _lostObjectIdController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hint: 'Ej. 671fb2c58971f49673981234 (MongoDB ObjectId)',
                    prefixIcon: Icons.link_rounded,
                    helperText: 'Vincular este reporte con un objeto previamente registrado.',
                  ),
                ),
                const SizedBox(height: 20),

                // Sección de Queja / Reclamo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.report_problem_outlined,
                                  color: AppColors.uctBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Detalles de la Queja / Reclamo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _includeComplaint,
                            activeColor: AppColors.uctBlue,
                            onChanged: (val) => setState(() => _includeComplaint = val),
                          ),
                        ],
                      ),
                      if (_includeComplaint) ...[
                        const Divider(height: 24),

                        // Título de Queja
                        _buildFieldLabel('Título de la Queja / Reclamo *'),
                        TextFormField(
                          controller: _complaintTitleController,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: 'Ej. Reclamo de pertenencia olvidada',
                            prefixIcon: Icons.title_rounded,
                          ),
                          validator: (val) {
                            if (!_includeComplaint) return null;
                            if (val == null || val.trim().isEmpty) {
                              return 'El título de la queja es obligatorio.';
                            }
                            if (val.trim().length < 3) {
                              return 'Debe tener al menos 3 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Descripción de Queja
                        _buildFieldLabel('Descripción de la Queja *'),
                        TextFormField(
                          controller: _complaintDescriptionController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            hint: 'Detalla lo ocurrido, lugar, fecha y motivo...',
                            prefixIcon: Icons.description_outlined,
                          ),
                          validator: (val) {
                            if (!_includeComplaint) return null;
                            if (val == null || val.trim().isEmpty) {
                              return 'La descripción es obligatoria.';
                            }
                            if (val.trim().length < 5) {
                              return 'Debe tener al menos 5 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Estado de la Queja
                        _buildFieldLabel('Tipo de Queja (ComplaintStatus)'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.fieldBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ComplaintStatus>(
                              value: _selectedComplaintStatus,
                              isExpanded: true,
                              items: ComplaintStatus.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text('${s.label} (${s.value})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedComplaintStatus = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Botón Enviar
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
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSubmitting ? 'Registrando reporte...' : 'Crear Reporte / Incidencia',
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
