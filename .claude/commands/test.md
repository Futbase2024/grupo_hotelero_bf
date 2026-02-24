# Test Command

Ejecuta la suite de tests con verificación de coverage.

## Uso
```
/test [--feature=X] [--coverage]
```

## Ejemplos
```
/test                      # Todos los tests
/test --feature=ideas      # Solo tests de ideas
/test --coverage           # Con reporte de coverage
```

## Proceso Completo

```bash
# 1. Ejecutar tests
flutter test

# 2. Con coverage
flutter test --coverage

# 3. Ver resumen
lcov --summary coverage/lcov.info

# 4. Generar HTML (opcional)
genhtml coverage/lcov.info -o coverage/html
```

## Requisitos de Coverage

| Categoría | Mínimo |
|-----------|--------|
| Global | 85% |
| BLoCs | 90% |
| Repositories | 85% |
| Widgets | 75% |

## Test Específico

```bash
# Feature específica
flutter test test/unit/presentation/features/ideas/

# Archivo específico
flutter test test/unit/presentation/features/ideas/bloc/ideas_bloc_test.dart

# Watch mode
flutter test --watch
```
