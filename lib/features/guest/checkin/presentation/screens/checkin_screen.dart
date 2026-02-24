import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bf_stay/core/theme/app_colors.dart';
import 'package:bf_stay/core/theme/app_theme.dart';
import 'package:bf_stay/core/theme/responsive.dart';

/// Pantalla de Check-in para huéspedes
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentNumberController = TextEditingController();
  DateTime? _birthDate;
  String? _documentType;
  bool _termsAccepted = false;

  final List<String> _documentTypes = ['DNI', 'Pasaporte', 'NIE', 'Otros'];

  final List<_StepInfo> _steps = [
    _StepInfo(icon: Icons.person_outline, title: 'Personal'),
    _StepInfo(icon: Icons.badge_outlined, title: 'Documento'),
    _StepInfo(icon: Icons.info_outline, title: 'Adicional'),
    _StepInfo(icon: Icons.check_circle_outline, title: 'Confirmar'),
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              context.go('/guest');
            }
          },
        ),
        title: const Text('Check-in Online'),
      ),
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: (context) => _buildMobileLayout(context),
          tablet: (context) => _buildTabletLayout(context),
          desktop: (context) => _buildDesktopLayout(context),
        ),
      ),
    );
  }

  /// Layout móvil: stepper vertical tradicional
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        _buildLinearProgressIndicator(),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(context.contentPaddingHorizontal),
            child: Form(
              key: _formKey,
              child: _buildCurrentStep(),
            ),
          ),
        ),
        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  /// Layout tablet: stepper horizontal con contenido centrado
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        // Horizontal stepper
        _buildHorizontalStepper(context),
        // Content
        Expanded(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing32),
                child: Form(
                  key: _formKey,
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
        ),
        // Navigation buttons
        _buildNavigationButtons(),
      ],
    );
  }

  /// Layout desktop: dos columnas con stepper a la izquierda
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left panel - Stepper
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            border: Border(
              right: BorderSide(color: AppColors.border),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing24),
                  child: Text(
                    'Progreso del Check-in',
                    style: TextStyle(
                      fontSize: ResponsiveFontSize.titleMedium(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildVerticalStepper(context),
                ),
              ],
            ),
          ),
        ),
        // Right panel - Content
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing48),
                      child: Form(
                        key: _formKey,
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                ),
              ),
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinearProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppColors.gold
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < 3) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHorizontalStepper(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_steps.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final step = _steps[index];

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepCircle(context, index, isCompleted, isCurrent, step),
              if (index < _steps.length - 1)
                Container(
                  width: 40,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isCompleted ? AppColors.gold : AppColors.border,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepCircle(
    BuildContext context,
    int index,
    bool isCompleted,
    bool isCurrent,
    _StepInfo step,
  ) {
    Color bgColor;
    Color iconColor;
    Color textColor;

    if (isCompleted) {
      bgColor = AppColors.success;
      iconColor = Colors.white;
      textColor = AppColors.textPrimary;
    } else if (isCurrent) {
      bgColor = AppColors.gold;
      iconColor = Colors.white;
      textColor = AppColors.gold;
    } else {
      bgColor = AppColors.border;
      iconColor = AppColors.textSecondary;
      textColor = AppColors.textSecondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : step.icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.title,
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodySmall(context),
            color: textColor,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalStepper(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;
        final step = _steps[index];
        final isLast = index == _steps.length - 1;

        Color bgColor;
        Color iconColor;

        if (isCompleted) {
          bgColor = AppColors.success;
          iconColor = Colors.white;
        } else if (isCurrent) {
          bgColor = AppColors.gold;
          iconColor = Colors.white;
        } else {
          bgColor = AppColors.border;
          iconColor = AppColors.textSecondary;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : step.icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 48,
                    color: isCompleted ? AppColors.gold : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  step.title,
                  style: TextStyle(
                    fontSize: ResponsiveFontSize.bodyMedium(context),
                    color: isCurrent ? AppColors.gold : AppColors.textSecondary,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildDocumentStep();
      case 2:
        return _buildAdditionalInfoStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Ingresa tus datos personales tal como aparecen en tu documento',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Two columns on tablet/desktop
        if (context.isMobile) ...[
          _buildTextField(_firstNameController, 'Nombre *', Icons.person_outline),
          const SizedBox(height: AppTheme.spacing16),
          _buildTextField(_lastNameController, 'Apellidos *', Icons.person_outline),
        ] else
          Row(
            children: [
              Expanded(
                child: _buildTextField(_firstNameController, 'Nombre *', Icons.person_outline),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _buildTextField(_lastNameController, 'Apellidos *', Icons.person_outline),
              ),
            ],
          ),
        const SizedBox(height: AppTheme.spacing16),

        _buildTextField(_emailController, 'Email *', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: AppTheme.spacing16),
        _buildTextField(_phoneController, 'Teléfono *', Icons.phone_outlined, keyboardType: TextInputType.phone),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: keyboardType == TextInputType.emailAddress
          ? TextCapitalization.none
          : TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor completa este campo';
            }
            if (label.contains('Email') && !value.contains('@')) {
              return 'Por favor ingresa un email válido';
            }
            return null;
          },
    );
  }

  Widget _buildDocumentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documento de Identidad',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Ingresa los datos de tu documento de identidad',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Two columns on tablet/desktop
        if (context.isMobile) ...[
          _buildDocumentTypeDropdown(),
          const SizedBox(height: AppTheme.spacing16),
          _buildTextField(_documentNumberController, 'Número de documento *', Icons.numbers),
        ] else
          Row(
            children: [
              Expanded(child: _buildDocumentTypeDropdown()),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _buildTextField(_documentNumberController, 'Número de documento *', Icons.numbers),
              ),
            ],
          ),
        const SizedBox(height: AppTheme.spacing16),

        // Birth Date
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 6570)),
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(const Duration(days: 6570)),
              locale: const Locale('es'),
            );
            if (date != null) {
              setState(() => _birthDate = date);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Fecha de nacimiento *',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              _birthDate != null
                  ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                  : 'Seleccionar fecha',
              style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Document Upload
        _buildDocumentUpload(context),
      ],
    );
  }

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _documentType,
      decoration: const InputDecoration(
        labelText: 'Tipo de documento *',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      items: _documentTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _documentType = value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona un tipo de documento';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentUpload(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing16, tablet: AppTheme.spacing24)),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: context.responsive(mobile: 40.0, tablet: 48.0),
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Subir foto del documento',
            style: TextStyle(
              fontSize: ResponsiveFontSize.bodyMedium(context),
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          OutlinedButton(
            onPressed: () {
              // TODO: Implement document upload
            },
            child: const Text('Seleccionar archivo'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Adicional',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Algunos datos adicionales para mejorar tu estadía',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Placeholder for additional questions
        Container(
          padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing16, tablet: AppTheme.spacing24)),
          decoration: BoxDecoration(
            color: AppColors.goldWithAlpha10,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.gold,
                size: context.responsive(mobile: 28.0, tablet: 32.0),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'En esta sección se incluirían preguntas adicionales como preferencias de habitación, necesidades especiales, etc.',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.bodyMedium(context),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmación',
          style: TextStyle(
            fontSize: ResponsiveFontSize.headlineSmall(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Revisa tus datos y acepta los términos para completar el check-in',
          style: TextStyle(
            fontSize: ResponsiveFontSize.bodyMedium(context),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Summary card
        Container(
          padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing12, tablet: AppTheme.spacing16)),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de datos',
                style: TextStyle(
                  fontSize: ResponsiveFontSize.titleMedium(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(),
              _buildSummaryRow('Nombre', '${_firstNameController.text} ${_lastNameController.text}'),
              _buildSummaryRow('Email', _emailController.text),
              _buildSummaryRow('Teléfono', _phoneController.text),
              _buildSummaryRow('Documento', '$_documentType: ${_documentNumberController.text}'),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing24),

        // Terms checkbox
        CheckboxListTile(
          value: _termsAccepted,
          onChanged: (value) {
            setState(() => _termsAccepted = value ?? false);
          },
          title: Text(
            'Acepto los términos y condiciones',
            style: TextStyle(fontSize: ResponsiveFontSize.bodyMedium(context)),
          ),
          subtitle: Text(
            'Y la política de privacidad',
            style: TextStyle(fontSize: ResponsiveFontSize.bodySmall(context)),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),

        // Signature placeholder
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'Firma',
          style: TextStyle(
            fontSize: ResponsiveFontSize.titleSmall(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          height: context.responsive(mobile: 100.0, tablet: 120.0),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Center(
            child: Text(
              'Área de firma',
              style: TextStyle(
                fontSize: ResponsiveFontSize.bodyMedium(context),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.responsive(mobile: 80.0, tablet: 100.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveFontSize.bodyMedium(context),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveFontSize.bodyMedium(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(context.responsive(mobile: AppTheme.spacing12, tablet: AppTheme.spacing16)),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: context.isDesktop ? 500 : double.infinity),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: Text(
                        'Atrás',
                        style: TextStyle(fontSize: ResponsiveFontSize.labelLarge(context)),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    child: Text(
                      _currentStep == 3 ? 'Completar' : 'Continuar',
                      style: TextStyle(fontSize: ResponsiveFontSize.labelLarge(context)),
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

  void _handleNext() {
    if (_currentStep < 3) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      // Final step - complete check-in
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar los términos y condiciones'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // TODO: Submit check-in data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in completado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/guest');
    }
  }
}

class _StepInfo {
  final IconData icon;
  final String title;

  const _StepInfo({required this.icon, required this.title});
}
