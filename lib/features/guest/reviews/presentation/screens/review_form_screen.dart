import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/bloc/reviews_bloc.dart';
import '../../domain/entities/review_entity.dart';
import '../widgets/rating_stars.dart';

/// Pantalla para crear o editar una reseña
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.propertyId,
    this.guestId,
    this.propertyName,
    this.existingReview,
  });

  final String propertyId;
  final String? guestId;
  final String? propertyName;
  final ReviewEntity? existingReview;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();

  int _rating = 0;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _rating = widget.existingReview!.rating;
      _titleController.text = widget.existingReview!.title ?? '';
      _commentController.text = widget.existingReview!.comment;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar reseña' : 'Nueva reseña',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.gray900,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
        foregroundColor: isDark ? AppColors.white : AppColors.gray900,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ReviewsBloc, ReviewsState>(
          listener: (context, state) {
            if (state is ReviewCreated || state is ReviewsLoaded) {
              // Mostrar éxito y cerrar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditing ? 'Reseña actualizada' : 'Reseña publicada',
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/');
              }
            } else if (state is ReviewsError) {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is ReviewCreating || state is ReviewUpdating;

            return Stack(
              children: [
                _buildForm(isDark),
                if (isLoading || _isSubmitting) _LoadingOverlay(isDark: isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Mensaje de info
          _buildInfoCard(isDark),
          const SizedBox(height: 24),

          // Rating con estrellas
          _buildRatingSection(isDark),
          const SizedBox(height: 24),

          // Campo de título (opcional)
          _buildTitleField(isDark),
          const SizedBox(height: 16),

          // Campo de comentario
          _buildCommentField(isDark),
          const SizedBox(height: 32),

          // Botón de enviar
          _buildSubmitButton(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.gold.withValues(alpha: 0.1) : AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: isDark ? AppColors.gold : AppColors.goldDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tu reseña será pública y ayudará a otros huéspedes a tomar decisiones.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.gold : AppColors.goldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu valoración',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Toca las estrellas para puntuar',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray600,
          ),
        ),
        const SizedBox(height: 16),

        // Estrellas interactivas
        Center(
          child: RatingStars(
            rating: _rating,
            starSize: 40,
            spacing: 8,
            interactive: true,
            onRatingChanged: (rating) {
              setState(() => _rating = rating);
            },
          ),
        ),

        // Texto descriptivo del rating
        if (_rating > 0) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              _getRatingText(_rating),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingText(int rating) {
    return switch (rating) {
      1 => 'Muy malo',
      2 => 'Malo',
      3 => 'Regular',
      4 => 'Bueno',
      5 => 'Excelente',
      _ => '',
    };
  }

  Widget _buildTitleField(bool isDark) {
    return TextFormField(
      controller: _titleController,
      maxLength: 100,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: isDark ? AppColors.white : AppColors.gray900,
      ),
      decoration: InputDecoration(
        labelText: 'Título (opcional)',
        hintText: 'Resume tu experiencia en una frase',
        labelStyle: TextStyle(
          color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray600,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.silver.withValues(alpha: 0.5) : AppColors.gray400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.gray700 : AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.gray700 : AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.gray800 : AppColors.white,
        counterStyle: TextStyle(
          color: isDark ? AppColors.silver.withValues(alpha: 0.5) : AppColors.gray500,
        ),
      ),
    );
  }

  Widget _buildCommentField(bool isDark) {
    return TextFormField(
      controller: _commentController,
      maxLines: 6,
      minLines: 4,
      maxLength: 1000,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: isDark ? AppColors.white : AppColors.gray900,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Por favor, escribe un comentario';
        }
        if (value.trim().length < 10) {
          return 'El comentario debe tener al menos 10 caracteres';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Tu comentario *',
        hintText: 'Cuéntanos tu experiencia...',
        alignLabelWithHint: true,
        labelStyle: TextStyle(
          color: isDark ? AppColors.silver.withValues(alpha: 0.7) : AppColors.gray600,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.silver.withValues(alpha: 0.5) : AppColors.gray400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.gray700 : AppColors.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.gray700 : AppColors.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        filled: true,
        fillColor: isDark ? AppColors.gray800 : AppColors.white,
        counterStyle: TextStyle(
          color: isDark ? AppColors.silver.withValues(alpha: 0.5) : AppColors.gray500,
        ),
        errorStyle: const TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    final isValid = _rating > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !_isSubmitting ? _submitReview : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.black,
          disabledBackgroundColor: isDark ? AppColors.gray700 : AppColors.gray300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isEditing ? 'Guardar cambios' : 'Publicar reseña',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _submitReview() {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecciona una puntuación'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (isEditing) {
      // Actualizar reseña existente
      final updatedReview = widget.existingReview!.copyWith(
        rating: _rating,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        comment: _commentController.text.trim(),
      );
      context.read<ReviewsBloc>().add(ReviewsUpdate(review: updatedReview));
    } else {
      // Crear nueva reseña
      final review = ReviewEntity(
        id: const Uuid().v4(),
        propertyId: widget.propertyId,
        guestId: widget.guestId,
        rating: _rating,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        comment: _commentController.text.trim(),
        isVerified: true, // Se verificará en el backend
        createdAt: DateTime.now(),
      );
      context.read<ReviewsBloc>().add(ReviewsCreate(review: review));
    }
  }
}

/// Overlay de carga
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blackWithAlpha50,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.gray800 : AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 16),
              Text(
                'Guardando...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.white : AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
