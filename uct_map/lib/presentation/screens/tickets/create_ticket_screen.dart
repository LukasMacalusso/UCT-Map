import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../domain/entities/app_permission.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/lost_object_dto.dart';
import '../../../data/models/report_dto.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';
import '../../../domain/entities/lost_object.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../../../domain/repositories/reports_repository.dart';
import '../lost_objects/widgets/lost_object_status_badge.dart';

/// Formulario para crear un nuevo Reporte / Ticket con soporte para Quejas/Reclamos
/// y vinculación interactiva con Objetos Perdidos (mediante selector con buscador o ID manual).
class CreateTicketScreen extends StatefulWidget {
  final ReportsRepository repository;
  final LostObjectsRepository? lostObjectsRepository;
  final String? initialLostObjectId;

  const CreateTicketScreen({
    super.key,
    required this.repository,
    this.lostObjectsRepository,
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

  late final LostObjectsRepository _lostObjectsRepository;

  LostObject? _selectedLostObject;
  bool _isManualIdInput = false;

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
    _lostObjectsRepository =
        widget.lostObjectsRepository ?? LostObjectsRepositoryImpl();

    if (widget.initialLostObjectId != null) {
      _lostObjectIdController.text = widget.initialLostObjectId!;
      _loadInitialObject(widget.initialLostObjectId!);
    }
  }

  Future<void> _loadInitialObject(String id) async {
    try {
      final res = await _lostObjectsRepository.getLostObjects();
      for (final item in res.items) {
        if (item.id == id && mounted) {
          setState(() {
            _selectedLostObject = item;
            if (_structureRefIdController.text.isEmpty) {
              _structureRefIdController.text = item.structureId;
            }
          });
          break;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _structureRefIdController.dispose();
    _lostObjectIdController.dispose();
    _complaintTitleController.dispose();
    _complaintDescriptionController.dispose();
    super.dispose();
  }

  void _showLostObjectPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _LostObjectPickerModal(
          repository: _lostObjectsRepository,
          selectedId: _lostObjectIdController.text.trim(),
          onSelected: (object) {
            setState(() {
              _selectedLostObject = object;
              _lostObjectIdController.text = object.id;
              // Si la estructura no se ha seleccionado, autocompletar con la del objeto:
              if (_structureRefIdController.text.trim().isEmpty) {
                _structureRefIdController.text = object.structureId;
              }
            });
          },
        );
      },
    );
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
      ticketType:
          AppPermission.manageReports.allows(
            ApiClientProvider.session.currentUser?.role,
          )
          ? _selectedTicketType
          : TicketStatus.pending,
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ApiClientProvider.session,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
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
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.uctBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El autor del reporte se asignará automáticamente desde tu sesión (Token JWT) por seguridad.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.ink,
                          ),
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
                      label: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        setState(() {
                          _structureRefIdController.text = entry.value;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                if (AppPermission.manageReports.allows(
                  ApiClientProvider.session.currentUser?.role,
                )) ...[
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
                ],
                // SECCIÓN: OBJETO PERDIDO ASOCIADO (SELECTOR INTERACTIVO)
                _buildFieldLabel('Objeto Perdido Asociado (Opcional)'),
                _buildLostObjectSelector(),
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
                              Icon(
                                Icons.report_problem_outlined,
                                color: AppColors.uctBlue,
                                size: 20,
                              ),
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
                            onChanged: (val) =>
                                setState(() => _includeComplaint = val),
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
                            hint:
                                'Detalla lo ocurrido, lugar, fecha y motivo...',
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
                                  setState(
                                    () => _selectedComplaintStatus = val,
                                  );
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
                      _isSubmitting
                          ? 'Registrando reporte...'
                          : 'Crear Reporte / Incidencia',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildLostObjectSelector() {
    if (_selectedLostObject != null) {
      // Tarjeta interactiva del objeto seleccionado con foto y detalles
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.network(
                      _selectedLostObject!.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedLostObject!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          LostObjectStatusBadge(
                            status: _selectedLostObject!.status,
                            isCompact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _selectedLostObject!.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${_selectedLostObject!.id}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          color: AppColors.hint,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  tooltip: 'Desvincular objeto',
                  onPressed: () {
                    setState(() {
                      _selectedLostObject = null;
                      _lostObjectIdController.clear();
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            InkWell(
              onTap: _showLostObjectPicker,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: AppColors.uctBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Cambiar por otro objeto',
                    style: TextStyle(
                      color: AppColors.uctBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón estilo tarjeta para abrir el buscador visual
        InkWell(
          onTap: _showLostObjectPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.uctBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.uctBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seleccionar objeto perdido...',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Toca para explorar la lista con fotos y buscar por nombre',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.hint,
                ),
              ],
            ),
          ),
        ),

        // Alternar entrada manual de ID
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _isManualIdInput = !_isManualIdInput),
              child: Text(
                _isManualIdInput
                    ? 'Ocultar entrada manual de ID'
                    : '¿Prefieres ingresar el ID manual?',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),

        // Campo de texto de respaldo
        if (_isManualIdInput || _lostObjectIdController.text.isNotEmpty)
          TextFormField(
            controller: _lostObjectIdController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              hint: 'Ej. 671fb2c58971f49673981234 (MongoDB ObjectId)',
              prefixIcon: Icons.link_rounded,
              helperText: 'Pega el ID del objeto si ya lo tienes a mano.',
            ),
          ),
      ],
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

/// Modal inferior interactivo con buscador en tiempo real para seleccionar un objeto perdido.
class _LostObjectPickerModal extends StatefulWidget {
  final LostObjectsRepository repository;
  final String? selectedId;
  final ValueChanged<LostObject> onSelected;

  const _LostObjectPickerModal({
    required this.repository,
    this.selectedId,
    required this.onSelected,
  });

  @override
  State<_LostObjectPickerModal> createState() => _LostObjectPickerModalState();
}

class _LostObjectPickerModalState extends State<_LostObjectPickerModal> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;
  String? _error;
  List<LostObject> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        _fetch(query.trim());
      }
    });
  }

  Future<void> _fetch([String? query]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await widget.repository.getLostObjects(
        filter: LostObjectFilterParams(
          title: query?.isNotEmpty == true ? query : null,
          pageSize: 10,
        ),
      );
      if (mounted) {
        setState(() {
          _items = res.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar los objetos perdidos.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 16),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.uctBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Seleccionar Objeto Perdido',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Buscador en tiempo real
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Buscar por título (ej. mochila, llaves)...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _fetch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.uctBlue),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.subtitle)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetch(_searchController.text),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se encontraron objetos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'No hay coincidencias para tu búsqueda o aún no se han registrado objetos perdidos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.subtitle),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _items[index];
        final isSelected = widget.selectedId == item.id;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Image.network(
                item.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.subtitle),
              ),
              const SizedBox(height: 2),
              Text(
                'ID: ${item.id}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  color: AppColors.hint,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LostObjectStatusBadge(status: item.status, isCompact: true),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.uctBlue,
                  size: 20,
                ),
              ],
            ],
          ),
          onTap: () {
            widget.onSelected(item);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
