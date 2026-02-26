import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/injection.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../domain/bloc/house_rules_bloc.dart';
import '../../domain/entities/house_rule_entity.dart';
import '../../domain/repositories/house_rules_repository.dart';
import '../widgets/house_rule_card.dart';

/// Pantalla de normas de la casa para huéspedes
class HouseRulesScreen extends StatelessWidget {
  const HouseRulesScreen({
    super.key,
    this.propertyId,
  });

  final String? propertyId;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDarkMode(context);

    return BlocProvider(
      create: (context) => HouseRulesBloc(
        houseRulesRepository: getIt<HouseRulesRepository>(),
      )..add(HouseRulesStarted(propertyId: propertyId)),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.black : AppColors.gray50,
        appBar: AppBar(
          title: Text(
            'Normas de la Casa',
            style: TextStyle(
              color: isDark ? AppColors.gold : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          backgroundColor: isDark ? AppColors.black : AppColors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.gold : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          top: false,
          child: _HouseRulesBody(propertyId: propertyId),
        ),
      ),
    );
  }
}

/// Body de la pantalla con acceso al BLoC
class _HouseRulesBody extends StatelessWidget {
  const _HouseRulesBody({this.propertyId});

  final String? propertyId;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HouseRulesBloc, HouseRulesState>(
      listener: (context, state) {
        if (state is HouseRulesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is HouseRulesInitial || state is HouseRulesLoading) {
          return const _LoadingView();
        }

        if (state is HouseRulesError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => _onRetry(context),
          );
        }

        if (state is HouseRulesLoaded) {
          return _LoadedView(
            rules: state.rules,
            groupedRules: state.groupedRules,
          );
        }

        return const _LoadingView();
      },
    );
  }

  void _onRetry(BuildContext context) {
    context.read<HouseRulesBloc>().add(
          HouseRulesLoadRequested(propertyId: propertyId),
        );
  }
}

/// Vista de carga
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.gold,
      ),
    );
  }
}

/// Vista de error
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error al cargar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textOnGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista con datos cargados
class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.rules,
    required this.groupedRules,
  });

  final List<HouseRuleEntity> rules;
  final Map<String, List<HouseRuleEntity>> groupedRules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const _EmptyView();
    }

    // Orden de categorías: safety, noise, cleanliness, general
    final categoryOrder = ['safety', 'noise', 'cleanliness', 'general'];
    final sortedCategories = categoryOrder
        .where((c) => groupedRules.containsKey(c))
        .toList();

    // Añadir categorías que no están en el orden predefinido
    final otherCategories =
        groupedRules.keys.where((c) => !categoryOrder.contains(c)).toList();
    sortedCategories.addAll(otherCategories);

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () async {
        context.read<HouseRulesBloc>().add(
              const HouseRulesRefreshRequested(),
            );
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: sortedCategories.length,
        itemBuilder: (context, categoryIndex) {
          final category = sortedCategories[categoryIndex];
          final categoryRules = groupedRules[category]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de categoría
              HouseRuleCategoryHeader(
                category: category,
                ruleCount: categoryRules.length,
              ),

              // Normas de la categoría
              ...categoryRules.map(
                (rule) => HouseRuleCard(rule: rule),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Vista vacía
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.getHouseRuleIconBackground(context),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rule_outlined,
                size: 40,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay normas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este alojamiento no tiene normas registradas',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
