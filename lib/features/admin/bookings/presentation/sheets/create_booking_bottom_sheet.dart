import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/router/app_router.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
import '../../../domain/services/email_service.dart';
import '../../../shared/widgets/admin_widgets.dart';

// ignore: avoid_classes_with_only_static_members
class Debug {
  static void log(String message) {
    debugPrint('🟢 [CreateBooking] $message');
  }

  static void error(String message, [Object? error]) {
    debugPrint('🔴 [CreateBooking] $message');
    if (error != null) {
      debugPrint('🔴 [CreateBooking] Error: $error');
    }
  }
}

class CreateBookingBottomSheet extends StatefulWidget {
  final AdminPanelRepository repository;
  final AdminDashboardBloc dashboardBloc;

  const CreateBookingBottomSheet({
    super.key,
    required this.repository,
    required this.dashboardBloc,
  });

  static Future<void> show(
    BuildContext context, {
    required AdminPanelRepository repository,
    required AdminDashboardBloc dashboardBloc,
  }) {
    Debug.log('show() - Iniciando showModalBottomSheet');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        Debug.log('show() - Builder ejecutado');
        return CreateBookingBottomSheet(
          repository: repository,
          dashboardBloc: dashboardBloc,
        );
      },
    );
  }

  @override
  State<CreateBookingBottomSheet> createState() => CreateBookingBottomSheetState();
}

class CreateBookingBottomSheetState extends State<CreateBookingBottomSheet> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  int currentStep = 0;
  bool isLoading = false;
  String? error;
  CreateBookingResult? result;

  List<UnitWithAvailability> units = [];
  bool isLoadingUnits = false;
  String? unitsError;

  /// Si el check-in de la reserva se validará automáticamente al enviarlo
  bool autoValidateCheckin = false;

  /// Lista de IDs de unidades seleccionadas (soporte multi-unidad, 1-9 habitaciones)
  List<String> selectedUnitIds = [];
  DateTime? checkInDate;
  DateTime? checkOutDate;

  /// Getter para compatibilidad: devuelve la primera unidad seleccionada
  String? get selectedUnitId => selectedUnitIds.isNotEmpty ? selectedUnitIds.first : null;
  int numAdults = 2;
  int numChildren = 0;
  List<int> childrenAges = [];

  @override
  void initState() {
    super.initState();
    Debug.log('initState - BottomSheet inicializado');
    // No cargamos unidades hasta que se seleccionen las fechas
  }

  Future<void> loadUnits() async {
    setState(() {
      isLoadingUnits = true;
      unitsError = null;
    });

    try {
      Debug.log('loadUnits - Cargando todas las unidades...');
      final loadedUnits = await widget.repository.listUnitsWithAvailability(
        propertyId: null,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
      );
      Debug.log('loadUnits - ${loadedUnits.length} unidades cargadas');
      loadedUnits.sort((a, b) => a.unit.name.compareTo(b.unit.name));
      setState(() {
        units = loadedUnits;
        isLoadingUnits = false;
      });
    } catch (e) {
      Debug.error('loadUnits - Error al cargar unidades', e);
      setState(() {
        unitsError = e.toString();
        isLoadingUnits = false;
      });
    }
  }

  @override
  void dispose() {
    Debug.log('dispose - BottomSheet destruido');
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Debug.log('build - Construyendo BottomSheet (step: $currentStep)');
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.85 + bottomPadding,
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          buildHeader(),
          Expanded(
            child: currentStep == 0 ? buildStep1() : buildStep2(),
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                currentStep == 0 ? 'Nueva reserva' : 'Reserva creada',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: AppColors.white),
              ),
              const SizedBox(height: 4),
              Text(
                currentStep == 0
                    ? 'Introduce los datos del huésped y la reserva'
                    : 'El código ha sido generado y enviado',
                style: TextStyle(fontSize: 13, color: AppColors.getTextSecondaryColor(context)),
              ),
            ],
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.gold, size: 24),
          ),
        ),
      ],
    );
  }

  Widget buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionHeader('Datos del huésped'),
            const SizedBox(height: 12),
            buildGuestFields(),
            const SizedBox(height: 24),
            buildSectionHeader('Reserva'),
            const SizedBox(height: 12),
            buildBookingFields(),
            const SizedBox(height: 24),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                      )
                    : const Text('Crear reserva y enviar código', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.getTextSecondaryColor(context),
        letterSpacing: 1,
      ),
    );
  }

  Widget buildGuestFields() {
    return Column(
      children: [
        TextFormField(
          controller: firstNameController,
          style: const TextStyle(color: AppColors.white),
          textCapitalization: TextCapitalization.words,
          decoration: buildInputDecoration('Nombre', Icons.person_outline),
          validator: (value) => value == null || value.isEmpty ? 'El nombre es obligatorio' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: lastNameController,
          style: const TextStyle(color: AppColors.white),
          textCapitalization: TextCapitalization.words,
          decoration: buildInputDecoration('Apellidos', Icons.person_outline),
          validator: (value) => value == null || value.isEmpty ? 'Los apellidos son obligatorios' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          style: const TextStyle(color: AppColors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: buildInputDecoration('Email del huésped', Icons.email_outlined).copyWith(
            helperText: 'El código BF se enviará automáticamente a este email',
            helperStyle: TextStyle(fontSize: 11, color: AppColors.getTextSecondaryColor(context)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'El email es obligatorio';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Introduce un email válido';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: phoneController,
          style: const TextStyle(color: AppColors.white),
          keyboardType: TextInputType.phone,
          decoration: buildInputDecoration('Teléfono (opcional)', Icons.phone_outlined),
        ),
      ],
    );
  }

  Widget buildBookingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PRIMERO: Fechas
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => selectDate(true),
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(color: AppColors.white),
                    decoration: buildInputDecoration('Entrada', Icons.calendar_today).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today, color: AppColors.gray500, size: 18),
                    ),
                    controller: TextEditingController(
                      text: checkInDate != null ? DateFormat('dd/MM/yyyy').format(checkInDate!) : '',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => selectDate(false),
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(color: AppColors.white),
                    decoration: buildInputDecoration('Salida', Icons.calendar_today).copyWith(
                      suffixIcon: const Icon(Icons.calendar_today, color: AppColors.gray500, size: 18),
                    ),
                    controller: TextEditingController(
                      text: checkOutDate != null ? DateFormat('dd/MM/yyyy').format(checkOutDate!) : '',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // SEGUNDO: Alojamiento (solo si hay fechas seleccionadas)
        if (checkInDate == null || checkOutDate == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.getTextSecondaryColor(context), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecciona las fechas para ver alojamientos disponibles',
                    style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
                  ),
                ),
              ],
            ),
          )
        else if (isLoadingUnits)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
                const SizedBox(width: 12),
                Text('Buscando alojamientos disponibles...', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
              ],
            ),
          )
        else if (unitsError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al cargar alojamientos', style: const TextStyle(color: AppColors.error))),
                TextButton(onPressed: loadUnits, child: const Text('Reintentar')),
              ],
            ),
          )
        else if (units.where((u) => u.isAvailable).isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_busy, color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay alojamientos disponibles para las fechas seleccionadas',
                    style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment_outlined, color: AppColors.gray500, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Alojamientos disponibles',
                    style: TextStyle(
                      color: AppColors.getTextSecondaryColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: selectedUnitIds.isNotEmpty ? AppColors.gold : AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${selectedUnitIds.length}/9 seleccionados',
                      style: TextStyle(
                        color: selectedUnitIds.isNotEmpty ? AppColors.black : AppColors.gray500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: units.where((u) => u.isAvailable).length,
                  itemBuilder: (context, index) {
                    final availableUnits = units.where((u) => u.isAvailable).toList();
                    final unitWithAvail = availableUnits[index];
                    final unit = unitWithAvail.unit;
                    final isSelected = selectedUnitIds.contains(unit.id);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          if (unit.unitType == 'hotel_room') {
                            // Hotel: eliminar cualquier apartamento previo y añadir
                            selectedUnitIds.removeWhere((id) {
                              final u = units.firstWhere((u) => u.unit.id == id);
                              return u.unit.unitType != 'hotel_room';
                            });
                            if (selectedUnitIds.length < 9) {
                              selectedUnitIds.add(unit.id);
                            }
                          } else {
                            // Apartamento: solo selección única, limpiar todo
                            selectedUnitIds
                              ..clear()
                              ..add(unit.id);
                          }
                        } else {
                          selectedUnitIds.remove(unit.id);
                        }
                      }),
                      title: Text(
                        unit.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.gold : AppColors.white,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _translateUnitType(unit.unitType),
                        style: TextStyle(
                          color: AppColors.getTextSecondaryColor(context),
                          fontSize: 12,
                        ),
                      ),
                      secondary: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.gold : AppColors.gray500,
                      ),
                      activeColor: AppColors.gold,
                      checkColor: AppColors.gold,
                      tileColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    );
                  },
                ),
              ),
              if (selectedUnitIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selecciona al menos un alojamiento',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.person_outline, color: AppColors.gray500, size: 20),
            const SizedBox(width: 8),
            Text('Adultos', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
            const Spacer(),
            buildCounter(
              value: numAdults,
              min: 1,
              max: 20,
              onDecrement: () => setState(() => numAdults--),
              onIncrement: () => setState(() => numAdults++),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.child_care_outlined, color: AppColors.gray500, size: 20),
            const SizedBox(width: 8),
            Text('Niños (0-17 años)', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
            const Spacer(),
            buildCounter(
              value: numChildren,
              min: 0,
              max: 10,
              onDecrement: () {
                setState(() {
                  numChildren--;
                  if (childrenAges.length > numChildren) childrenAges.removeLast();
                });
              },
              onIncrement: () {
                setState(() {
                  numChildren++;
                  if (childrenAges.length < numChildren) childrenAges.add(5);
                });
              },
            ),
          ],
        ),
        if (numChildren > 0) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              '* Los menores de 14 años no requieren documentación',
              style: TextStyle(color: AppColors.getTextSecondaryColor(context), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(numChildren, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Text('Niño ${index + 1}', style: TextStyle(color: AppColors.getTextSecondaryColor(context), fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: childrenAges.length > index ? childrenAges[index] : 5,
                      style: const TextStyle(color: AppColors.white, fontSize: 14),
                      dropdownColor: AppColors.darkSurface,
                      decoration: InputDecoration(
                        labelText: 'Edad',
                        labelStyle: const TextStyle(color: AppColors.gray500, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: AppColors.darkSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
                      ),
                      items: List.generate(18, (i) => DropdownMenuItem(value: i, child: Text('$i ${i == 1 ? 'año' : 'años'}'))),
                      onChanged: (value) {
                        setState(() {
                          while (childrenAges.length <= index) {
                            childrenAges.add(5);
                          }
                          childrenAges[index] = value ?? 5;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: notesController,
          style: const TextStyle(color: AppColors.white),
          maxLines: 3,
          decoration: buildInputDecoration('Notas internas (opcional)', Icons.note_outlined),
        ),
        const SizedBox(height: 12),
        buildAutoValidateTile(),
      ],
    );
  }

  /// Interruptor para que el check-in de esta reserva se valide solo al enviarlo
  Widget buildAutoValidateTile() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: autoValidateCheckin ? AppColors.gold : AppColors.darkBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 20,
            color: autoValidateCheckin ? AppColors.gold : AppColors.gray500,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-validar check-in',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'El check-in del huésped se validará solo, sin revisión manual',
                  style: TextStyle(color: AppColors.gray500, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          Switch(
            value: autoValidateCheckin,
            activeThumbColor: AppColors.black,
            activeTrackColor: AppColors.gold,
            inactiveThumbColor: AppColors.gray400,
            inactiveTrackColor: AppColors.darkBackground,
            onChanged: (value) => setState(() => autoValidateCheckin = value),
          ),
        ],
      ),
    );
  }

  String _translateUnitType(String unitType) {
    switch (unitType) {
      case 'apartment':
        return 'Apartamento';
      case 'hotel_room':
        return 'Habitación de hotel';
      case 'room':
        return 'Habitación';
      default:
        return unitType;
    }
  }

  Widget buildCounter({required int value, required int min, required int max, required VoidCallback onDecrement, required VoidCallback onIncrement}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.gold), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > min ? onDecrement : null,
            icon: Icon(Icons.remove, color: value > min ? AppColors.gold : AppColors.gray500),
          ),
          SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.white))),
          IconButton(
            onPressed: value < max ? onIncrement : null,
            icon: Icon(Icons.add, color: value < max ? AppColors.gold : AppColors.gray500),
          ),
        ],
      ),
    );
  }

  InputDecoration buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.gray500),
      prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error)),
    );
  }

  Future<void> selectDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? now : (checkInDate ?? now).add(const Duration(days: 1)),
      firstDate: isCheckIn ? now : (checkInDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.darkSurface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
          if (checkOutDate != null && checkOutDate!.isBefore(picked)) {
            checkOutDate = null;
          }
        } else {
          checkOutDate = picked;
        }
        // Limpiar alojamientos seleccionados cuando cambian las fechas
        selectedUnitIds = [];
      });
      // Solo cargar unidades si ambas fechas están seleccionadas
      if (checkInDate != null && checkOutDate != null) {
        loadUnits();
      }
    }
  }

  String _parseBookingError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('no_overlapping_bookings') ||
        msg.contains('exclusion constraint') ||
        msg.contains('ya existe una reserva') ||
        msg.contains('fechas solapadas') ||
        msg.contains('conflicts with key')) {
      return 'Ya existe una reserva para este alojamiento en las fechas seleccionadas. '
          'Cambia las fechas o el alojamiento.';
    }
    if (msg.contains('exception:')) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'Error al crear la reserva. Inténtalo de nuevo.';
  }

  Future<void> submitForm() async {
    Debug.log('submitForm - Iniciando envío del formulario');
    if (!formKey.currentState!.validate()) {
      Debug.log('submitForm - Validación fallida');
      return;
    }
    if (checkInDate == null || checkOutDate == null) {
      Debug.log('submitForm - Faltan fechas');
      setState(() => error = 'Selecciona las fechas de entrada y salida');
      return;
    }
    if (selectedUnitIds.isEmpty) {
      Debug.log('submitForm - Falta alojamiento');
      setState(() => error = 'Selecciona al menos un alojamiento');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      Debug.log('submitForm - Llamando a createBooking con ${selectedUnitIds.length} unidades');

      // Obtener el propertyId de la primera unidad seleccionada
      final firstUnitWithAvail = units.firstWhere(
        (u) => u.unit.id == selectedUnitIds.first,
        orElse: () => units.first,
      );
      final propertyId = firstUnitWithAvail.unit.propertyId;

      final bookingResult = await widget.repository.createBooking(
        unitIds: selectedUnitIds, // Multi-unidad: pasar lista de IDs
        guestFirstName: firstNameController.text.trim(),
        guestLastName: lastNameController.text.trim(),
        guestEmail: emailController.text.trim(),
        guestPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        checkInDate: checkInDate!,
        checkOutDate: checkOutDate!,
        numGuests: numAdults + numChildren,
        numAdults: numAdults,
        numChildren: numChildren,
        childrenAges: childrenAges.take(numChildren).toList(),
        staffNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
        propertyId: propertyId,
      );

      Debug.log('submitForm - Reserva creada: ${bookingResult.bookingCode}');

      // Auto-validación del check-in: se aplica sobre la reserva ya creada
      if (autoValidateCheckin) {
        try {
          await widget.repository.setBookingAutoValidateCheckin(
            bookingId: bookingResult.bookingId,
            enabled: true,
          );
          Debug.log('submitForm - Auto-validación de check-in activada');
        } catch (e) {
          // No bloquear el alta: la reserva ya existe y el flag se puede
          // activar después desde el detalle de la reserva
          Debug.error('submitForm - Error activando auto-validación (no crítico)', e);
        }
      }

      // Enviar email al huésped con el código de acceso
      bool emailSent = false;
      if (emailController.text.trim().isNotEmpty) {
        try {
          Debug.log('submitForm - Enviando email al huésped: ${emailController.text.trim()}');

          // Obtener nombres de todas las unidades seleccionadas
          final selectedUnitNames = selectedUnitIds.map((id) {
            final unit = units.firstWhere((u) => u.unit.id == id, orElse: () => units.first);
            return unit.unit.name;
          }).join(', ');

          emailSent = await EmailService().sendBookingCreatedEmail(
            toEmail: emailController.text.trim(),
            guestName: '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
            propertyName: 'BF Stay',
            unitName: selectedUnitNames, // Multi-unidad: todos los nombres
            checkinDate: checkInDate!,
            checkoutDate: checkOutDate!,
            bookingCode: bookingResult.bookingCode,
            numGuests: numAdults + numChildren,
            bookingId: bookingResult.bookingId,
            unitId: selectedUnitIds.first, // Primera unidad para compatibilidad
          );
          Debug.log('submitForm - Email enviado: $emailSent');
        } catch (e) {
          // No bloquear el flujo si el email falla
          Debug.error('submitForm - Error enviando email (no crítico)', e);
          emailSent = false;
        }
      }

      // Crear resultado actualizado con el estado real del envío de email
      final updatedResult = CreateBookingResult(
        bookingId: bookingResult.bookingId,
        bookingCode: bookingResult.bookingCode,
        keyboxCode: bookingResult.keyboxCode,
        emailSent: emailSent,
        emailError: emailSent ? null : 'No se pudo enviar el email',
        simulated: bookingResult.simulated,
      );

      setState(() {
        result = updatedResult;
        currentStep = 1;
        isLoading = false;
      });

      if (mounted) {
        Debug.log('submitForm - Refrescando lista de reservas');
        widget.dashboardBloc.add(const AdminDashboardBookingsLoadRequested());
      }
    } catch (e, stackTrace) {
      Debug.error('submitForm - Error al crear reserva', e);
      debugPrint('🔴 StackTrace: $stackTrace');
      setState(() {
        error = _parseBookingError(e);
        isLoading = false;
      });
    }
  }

  Widget buildStep2() {
    if (result == null) return const Center(child: Text('Error: No hay resultado'));

    final selectedUnit = units.firstWhere((u) => u.unit.id == selectedUnitId, orElse: () => units.first);
    final nights = checkInDate != null && checkOutDate != null
        ? checkOutDate!.difference(checkInDate!).inDays
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Icono de éxito
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),

          // Título
          Text(
            'Reserva creada',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'para ${firstNameController.text} ${lastNameController.text}',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 24),

          // TARJETA PROFESIONAL CLICKEABLE
          _BookingSuccessCard(
            unitName: selectedUnit.unit.name,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
            nights: nights,
            numAdults: numAdults,
            numChildren: numChildren,
            childrenAges: childrenAges.take(numChildren).toList(),
            bookingCode: result!.bookingCode,
            keyboxCode: result!.keyboxCode,
            onTap: () {
              Navigator.of(context).pop();
              context.push(
                AppRoutes.adminBookingDetail.replaceFirst(':bookingId', result!.bookingId),
              );
            },
          ),
          const SizedBox(height: 20),

          // Widget de códigos
          BfCodeDisplayWidget(
            code: result!.bookingCode,
            keyboxCode: result!.keyboxCode,
            checkInDate: checkInDate,
            checkOutDate: checkOutDate,
          ),
          const SizedBox(height: 16),

          // Estado del email
          buildEmailStatusCard(),
          const SizedBox(height: 24),

          // Botón principal
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Crear otra reserva
          TextButton(
            onPressed: resetForm,
            child: Text(
              'Crear otra reserva',
              style: TextStyle(color: AppColors.getTextSecondaryColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.white)),
        ],
      ),
    );
  }

  Widget buildEmailStatusCard() {
    final emailResult = result!;

    if (emailResult.emailSent) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Código enviado a ${emailController.text}', style: const TextStyle(fontSize: 13, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'El huésped recibirá instrucciones en su bandeja de entrada',
                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondaryColor(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No se pudo enviar el email automáticamente', style: TextStyle(fontSize: 13, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'El código está creado. Compártelo manualmente.',
                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondaryColor(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  void resetForm() {
    setState(() {
      currentStep = 0;
      result = null;
      error = null;
      firstNameController.clear();
      lastNameController.clear();
      emailController.clear();
      phoneController.clear();
      notesController.clear();
      selectedUnitIds = [];
      checkInDate = null;
      checkOutDate = null;
      numAdults = 2;
      numChildren = 0;
      childrenAges = [];
      autoValidateCheckin = false;
      units = [];
      unitsError = null;
    });
    // No cargamos unidades hasta que se seleccionen las fechas
  }
}

/// Widget de tarjeta profesional para mostrar la reserva creada exitosamente
/// Al pulsar navega a los detalles de la reserva
class _BookingSuccessCard extends StatelessWidget {
  const _BookingSuccessCard({
    required this.unitName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.nights,
    required this.numAdults,
    required this.numChildren,
    required this.childrenAges,
    required this.bookingCode,
    required this.keyboxCode,
    required this.onTap,
  });

  final String unitName;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int nights;
  final int numAdults;
  final int numChildren;
  final List<int> childrenAges;
  final String bookingCode;
  final String keyboxCode;
  final VoidCallback onTap;

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gold.withValues(alpha: 0.15),
                AppColors.darkSurface,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // HEADER PRINCIPAL
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unitName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  color: AppColors.gold,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Ver detalles completos',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.gold,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // CUERPO CON INFORMACIÓN
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // FILA DE FECHAS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Check-in
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.login_rounded,
                                    color: AppColors.black,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ENTRADA',
                                  style: TextStyle(
                                    color: AppColors.getTextSecondaryColor(context),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(checkInDate),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Separador con noches
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$nights',
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  nights == 1 ? 'NOCHE' : 'NOCHES',
                                  style: const TextStyle(
                                    color: AppColors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Check-out
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.black,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SALIDA',
                                  style: TextStyle(
                                    color: AppColors.getTextSecondaryColor(context),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(checkOutDate),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Huéspedes
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: const Icon(
                              Icons.people_rounded,
                              color: AppColors.black,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$numAdults ${numAdults == 1 ? "adulto" : "adultos"}',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (numChildren > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '$numChildren ${numChildren == 1 ? "niño" : "niños"}${childrenAges.isNotEmpty ? " (${childrenAges.join(', ')} años)" : ""}',
                                    style: TextStyle(
                                      color: AppColors.getTextSecondaryColor(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
