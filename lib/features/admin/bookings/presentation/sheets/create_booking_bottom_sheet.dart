import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/bloc/bloc.dart';
import '../../../domain/repositories/admin_panel_repository.dart';
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
  bool isLoadingUnits = true;
  String? unitsError;

  String? selectedUnitId;
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int numAdults = 2;
  int numChildren = 0;
  List<int> childrenAges = [];

  @override
  void initState() {
    super.initState();
    Debug.log('initState - BottomSheet inicializado');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUnits();
    });
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
        if (isLoadingUnits)
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
                Text('Cargando alojamientos...', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
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
        else if (units.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Text('No hay alojamientos disponibles', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
          )
        else
          DropdownButtonFormField<String>(
            style: const TextStyle(color: AppColors.white),
            dropdownColor: AppColors.darkSurface,
            decoration: buildInputDecoration('Alojamiento', Icons.apartment_outlined).copyWith(
              hintText: 'Selecciona un alojamiento',
              hintStyle: const TextStyle(color: AppColors.gray500),
              helperText: checkInDate != null && checkOutDate != null
                  ? 'Los alojamientos en rojo no están disponibles'
                  : 'Selecciona fechas para ver disponibilidad',
              helperStyle: TextStyle(fontSize: 11, color: AppColors.getTextSecondaryColor(context)),
            ),
            items: units.map((unitWithAvail) {
              final unit = unitWithAvail.unit;
              final isAvailable = unitWithAvail.isAvailable;
              return DropdownMenuItem<String>(
                value: unit.id,
                enabled: isAvailable || checkInDate == null,
                child: Text(
                  '${isAvailable || checkInDate == null ? "✓" : "✗"} ${unit.name}${!isAvailable && checkInDate != null ? " (Ocupado)" : ""}',
                  style: TextStyle(
                    color: isAvailable || checkInDate == null ? AppColors.white : AppColors.gray500,
                    decoration: isAvailable || checkInDate == null ? null : TextDecoration.lineThrough,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedUnitId = value),
            validator: (value) => value == null ? 'Selecciona un alojamiento' : null,
          ),
        const SizedBox(height: 12),
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
            Text('Niños (0-13 años)', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
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
                      items: List.generate(14, (i) => DropdownMenuItem(value: i, child: Text('$i ${i == 1 ? 'año' : 'años'}'))),
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
      ],
    );
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
          if (checkOutDate != null && checkOutDate!.isBefore(picked)) checkOutDate = null;
        } else {
          checkOutDate = picked;
        }
      });
      loadUnits();
    }
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
    if (selectedUnitId == null) {
      Debug.log('submitForm - Falta alojamiento');
      setState(() => error = 'Selecciona un alojamiento');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      Debug.log('submitForm - Llamando a createBooking');

      // Obtener el propertyId de la unidad seleccionada
      final selectedUnitWithAvail = units.firstWhere(
        (u) => u.unit.id == selectedUnitId,
        orElse: () => units.first,
      );
      final propertyId = selectedUnitWithAvail.unit.propertyId;

      final bookingResult = await widget.repository.createBooking(
        unitId: selectedUnitId!,
        guestFirstName: firstNameController.text.trim(),
        guestLastName: lastNameController.text.trim(),
        guestEmail: emailController.text.trim(),
        guestPhone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : null,
        checkInDate: checkInDate!,
        checkOutDate: checkOutDate!,
        numGuests: numAdults + numChildren,
        staffNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
        propertyId: propertyId,
      );

      Debug.log('submitForm - Reserva creada: ${bookingResult.bookingCode}');
      setState(() {
        result = bookingResult;
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
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Widget buildStep2() {
    if (result == null) return const Center(child: Text('Error: No hay resultado'));

    final selectedUnit = units.firstWhere((u) => u.unit.id == selectedUnitId, orElse: () => units.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text('Reserva creada para', style: TextStyle(fontSize: 13, color: AppColors.getTextSecondaryColor(context))),
          const SizedBox(height: 4),
          Text(
            '${firstNameController.text} ${lastNameController.text}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkBorder)),
            child: Column(
              children: [
                buildSummaryRow('Alojamiento', selectedUnit.unit.name),
                const Divider(color: AppColors.darkBorder),
                buildSummaryRow('Entrada', checkInDate != null ? DateFormat('dd/MM/yyyy').format(checkInDate!) : ''),
                const Divider(color: AppColors.darkBorder),
                buildSummaryRow('Salida', checkOutDate != null ? DateFormat('dd/MM/yyyy').format(checkOutDate!) : ''),
                const Divider(color: AppColors.darkBorder),
                buildSummaryRow('Adultos', '$numAdults'),
                if (numChildren > 0) ...[
                  const Divider(color: AppColors.darkBorder),
                  buildSummaryRow('Niños', '$numChildren (${childrenAges.take(numChildren).join(", ")} años)'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          BfCodeDisplayWidget(code: result!.bookingCode, checkInDate: checkInDate, checkOutDate: checkOutDate),
          const SizedBox(height: 24),
          buildEmailStatusCard(),
          const SizedBox(height: 24),
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
              child: const Text('Entendido', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: resetForm,
            child: Text('Crear otra reserva', style: TextStyle(color: AppColors.getTextSecondaryColor(context))),
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
      selectedUnitId = null;
      checkInDate = null;
      checkOutDate = null;
      numAdults = 2;
      numChildren = 0;
      childrenAges = [];
    });
    loadUnits();
  }
}
