# 🧪 QA Validation Agent

> **ID**: AG-05  
> **Rol**: Quality Assurance y Testing  
> **Proyecto**: Content Engine App

---

## 🎯 Propósito

Garantizar la calidad del código mediante testing exhaustivo, validación de coverage mínimo del 85%, y verificación de estándares de código.

---

## 📋 Responsabilidades

1. **Crear tests unitarios** para BLoCs y Repositories
2. **Crear widget tests** para componentes UI
3. **Verificar coverage** mínimo 85%
4. **Validar linting** con dart analyze
5. **Revisar código** contra estándares
6. **Ejecutar hooks** obligatorios

---

## 🔴 HOOKS OBLIGATORIOS

### Post-Modificación (SIEMPRE)
```bash
dart fix --apply && dart analyze
```

### Pre-Commit
```bash
dart fix --apply && dart analyze && flutter test --coverage
```

### Post-Build-Runner
```bash
dart run build_runner build --delete-conflicting-outputs && dart fix --apply
```

---

## 🚫 PROHIBICIONES A VERIFICAR

### ❌ Métodos que Devuelven Widget

```dart
// ❌ RECHAZAR - Método que devuelve Widget
class SomePage extends StatelessWidget {
  Widget _buildHeader() { ... }  // ❌ FALLA QA
  Widget _buildList() { ... }    // ❌ FALLA QA
}

// ✅ APROBAR - Widgets como clases
class SomePageHeader extends StatelessWidget { ... }  // ✅ PASA QA
class SomePageList extends StatelessWidget { ... }    // ✅ PASA QA
```

**Regex para detectar:**
```regex
Widget\s+_build\w+\s*\(
```

### ❌ Material Widgets

```dart
// ❌ RECHAZAR
Scaffold, AppBar, FloatingActionButton, Card, ListTile,
TextField, AlertDialog, BottomSheet, CircularProgressIndicator,
MaterialApp, Material, InkWell, ElevatedButton, TextButton

// ✅ APROBAR
CupertinoPageScaffold, CupertinoNavigationBar, CupertinoButton,
CupertinoTextField, CupertinoAlertDialog, CupertinoActionSheet,
CupertinoActivityIndicator, CupertinoApp, CupertinoListTile
```

---

## 🧪 Estructura de Tests

```
test/
├── unit/
│   ├── data/
│   │   ├── models/
│   │   │   └── idea_model_test.dart
│   │   └── repositories/
│   │       └── ideas_repository_test.dart
│   └── presentation/
│       └── features/
│           └── ideas/
│               └── bloc/
│                   └── ideas_bloc_test.dart
├── widget/
│   └── presentation/
│       └── features/
│           └── ideas/
│               ├── page/
│               │   └── ideas_page_test.dart
│               └── widgets/
│                   ├── ideas_loaded_view_test.dart
│                   └── idea_card_test.dart
├── integration/
│   └── app_test.dart
├── mocks/
│   ├── mock_repositories.dart
│   └── mock_datasources.dart
└── fixtures/
    └── ideas_fixtures.dart
```

---

## 📝 Templates de Tests

### BLoC Test

```dart
// test/unit/presentation/features/ideas/bloc/ideas_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:content_engine_app/data/models/idea_model.dart';
import 'package:content_engine_app/domain/repositories/ideas_repository.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_bloc.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_event.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_state.dart';

import '../../../../mocks/mock_repositories.dart';
import '../../../../fixtures/ideas_fixtures.dart';

void main() {
  late MockIdeasRepository mockRepository;
  late IdeasBloc bloc;

  setUp(() {
    mockRepository = MockIdeasRepository();
    bloc = IdeasBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('IdeasBloc', () {
    test('initial state is IdeasState.initial()', () {
      expect(bloc.state, const IdeasState.initial());
    });

    group('LoadRequested', () {
      blocTest<IdeasBloc, IdeasState>(
        'emits [loading, loaded] when successful',
        build: () {
          when(() => mockRepository.getAll())
              .thenAnswer((_) async => IdeasFixtures.list);
          return bloc;
        },
        act: (bloc) => bloc.add(const IdeasEvent.loadRequested()),
        expect: () => [
          const IdeasState.loading(),
          IdeasState.loaded(items: IdeasFixtures.list),
        ],
        verify: (_) {
          verify(() => mockRepository.getAll()).called(1);
        },
      );

      blocTest<IdeasBloc, IdeasState>(
        'emits [loading, error] when fails',
        build: () {
          when(() => mockRepository.getAll())
              .thenThrow(Exception('Network error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const IdeasEvent.loadRequested()),
        expect: () => [
          const IdeasState.loading(),
          isA<IdeasState>().having(
            (s) => s.mapOrNull(error: (e) => e.message),
            'error message',
            contains('Network error'),
          ),
        ],
      );
    });

    group('CreateRequested', () {
      blocTest<IdeasBloc, IdeasState>(
        'calls repository.create and reloads',
        build: () {
          when(() => mockRepository.create(any()))
              .thenAnswer((_) async => IdeasFixtures.single);
          when(() => mockRepository.getAll())
              .thenAnswer((_) async => IdeasFixtures.list);
          return bloc;
        },
        act: (bloc) => bloc.add(
          IdeasEvent.createRequested(item: IdeasFixtures.single),
        ),
        verify: (_) {
          verify(() => mockRepository.create(IdeasFixtures.single)).called(1);
          verify(() => mockRepository.getAll()).called(1);
        },
      );
    });

    group('DeleteRequested', () {
      blocTest<IdeasBloc, IdeasState>(
        'calls repository.delete and reloads',
        build: () {
          when(() => mockRepository.delete(any()))
              .thenAnswer((_) async {});
          when(() => mockRepository.getAll())
              .thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) => bloc.add(
          const IdeasEvent.deleteRequested(id: 'test-id'),
        ),
        verify: (_) {
          verify(() => mockRepository.delete('test-id')).called(1);
          verify(() => mockRepository.getAll()).called(1);
        },
      );
    });
  });
}
```

### Repository Test

```dart
// test/unit/data/repositories/ideas_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:content_engine_app/data/datasources/remote/supabase_datasource.dart';
import 'package:content_engine_app/data/repositories/ideas_repository_impl.dart';

import '../../../mocks/mock_datasources.dart';
import '../../../fixtures/ideas_fixtures.dart';

void main() {
  late MockSupabaseDatasource mockDatasource;
  late IdeasRepositoryImpl repository;

  setUp(() {
    mockDatasource = MockSupabaseDatasource();
    repository = IdeasRepositoryImpl(datasource: mockDatasource);
  });

  group('IdeasRepositoryImpl', () {
    group('getAll', () {
      test('returns list of ideas from datasource', () async {
        when(() => mockDatasource.client.from('ideas').select())
            .thenAnswer((_) async => IdeasFixtures.jsonList);

        final result = await repository.getAll();

        expect(result, hasLength(IdeasFixtures.list.length));
        expect(result.first.id, IdeasFixtures.list.first.id);
      });

      test('throws when datasource fails', () async {
        when(() => mockDatasource.client.from('ideas').select())
            .thenThrow(Exception('DB Error'));

        expect(
          () => repository.getAll(),
          throwsException,
        );
      });
    });

    group('create', () {
      test('inserts and returns created idea', () async {
        when(() => mockDatasource.client
            .from('ideas')
            .insert(any())
            .select()
            .single())
            .thenAnswer((_) async => IdeasFixtures.singleJson);

        final result = await repository.create(IdeasFixtures.single);

        expect(result.id, IdeasFixtures.single.id);
      });
    });
  });
}
```

### Widget Test

```dart
// test/widget/presentation/features/ideas/widgets/ideas_loaded_view_test.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:content_engine_app/presentation/features/ideas/widgets/ideas_loaded_view.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_bloc.dart';

import '../../../../mocks/mock_blocs.dart';
import '../../../../fixtures/ideas_fixtures.dart';

void main() {
  late MockIdeasBloc mockBloc;

  setUp(() {
    mockBloc = MockIdeasBloc();
  });

  Widget buildTestWidget({required List<IdeaModel> items}) {
    return CupertinoApp(
      home: BlocProvider<IdeasBloc>.value(
        value: mockBloc,
        child: IdeasLoadedView(
          items: items,
          isRefreshing: false,
        ),
      ),
    );
  }

  group('IdeasLoadedView', () {
    testWidgets('renders empty view when items is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget(items: []));

      expect(find.byType(IdeasEmptyView), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets('renders list when items exist', (tester) async {
      await tester.pumpWidget(buildTestWidget(items: IdeasFixtures.list));

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(IdeaCard), findsNWidgets(IdeasFixtures.list.length));
    });

    testWidgets('shows refresh control', (tester) async {
      await tester.pumpWidget(buildTestWidget(items: IdeasFixtures.list));

      expect(find.byType(CupertinoSliverRefreshControl), findsOneWidget);
    });

    testWidgets('tapping card navigates to detail', (tester) async {
      await tester.pumpWidget(buildTestWidget(items: IdeasFixtures.list));

      await tester.tap(find.byType(IdeaCard).first);
      await tester.pumpAndSettle();

      // Verificar navegación
    });
  });
}
```

### Page Test

```dart
// test/widget/presentation/features/ideas/page/ideas_page_test.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:content_engine_app/presentation/features/ideas/page/ideas_page.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_bloc.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_state.dart';

import '../../../../mocks/mock_blocs.dart';
import '../../../../fixtures/ideas_fixtures.dart';

class MockIdeasBloc extends MockBloc<IdeasEvent, IdeasState>
    implements IdeasBloc {}

void main() {
  late MockIdeasBloc mockBloc;

  setUp(() {
    mockBloc = MockIdeasBloc();
  });

  Widget buildTestWidget() {
    return CupertinoApp(
      home: BlocProvider<IdeasBloc>.value(
        value: mockBloc,
        child: const IdeasPage(),
      ),
    );
  }

  group('IdeasPage', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockBloc.state).thenReturn(const IdeasState.loading());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('shows loaded view when loaded', (tester) async {
      when(() => mockBloc.state).thenReturn(
        IdeasState.loaded(items: IdeasFixtures.list),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(IdeasLoadedView), findsOneWidget);
    });

    testWidgets('shows error view when error', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const IdeasState.error(message: 'Test error'),
      );

      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('has add button in navigation bar', (tester) async {
      when(() => mockBloc.state).thenReturn(const IdeasState.initial());

      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });
  });
}
```

### Mocks

```dart
// test/mocks/mock_repositories.dart
import 'package:mocktail/mocktail.dart';
import 'package:content_engine_app/domain/repositories/ideas_repository.dart';

class MockIdeasRepository extends Mock implements IdeasRepository {}

// test/mocks/mock_blocs.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_bloc.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_event.dart';
import 'package:content_engine_app/presentation/features/ideas/bloc/ideas_state.dart';

class MockIdeasBloc extends MockBloc<IdeasEvent, IdeasState>
    implements IdeasBloc {}
```

### Fixtures

```dart
// test/fixtures/ideas_fixtures.dart
import 'package:content_engine_app/data/models/idea_model.dart';

class IdeasFixtures {
  static final single = IdeaModel(
    id: 'test-id-1',
    rawIdea: 'Test idea content',
    pillar: 'flutter_advanced',
    status: 'idea',
    priority: 5,
    createdAt: DateTime(2024, 1, 1),
  );

  static final list = [
    single,
    IdeaModel(
      id: 'test-id-2',
      rawIdea: 'Another test idea',
      pillar: 'claude_ai_practical',
      status: 'scripted',
      priority: 8,
      createdAt: DateTime(2024, 1, 2),
    ),
  ];

  static final singleJson = {
    'id': 'test-id-1',
    'raw_idea': 'Test idea content',
    'pillar': 'flutter_advanced',
    'status': 'idea',
    'priority': 5,
    'created_at': '2024-01-01T00:00:00.000Z',
  };

  static final jsonList = list.map((e) => e.toJson()).toList();
}
```

---

## 📊 Coverage Requirements

### Mínimo 85% Global

```bash
# Ejecutar tests con coverage
flutter test --coverage

# Verificar porcentaje
lcov --summary coverage/lcov.info

# Generar reporte HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Por Categoría

| Categoría | Mínimo |
|-----------|--------|
| BLoCs | 90% |
| Repositories | 85% |
| Models | 80% |
| Widgets | 75% |
| Utils/Helpers | 85% |

---

## ✅ Checklist de QA

### Pre-Merge
```
Código
□ dart fix --apply ejecutado
□ dart analyze sin errores
□ Sin métodos _buildX() que devuelvan Widget
□ Sin widgets Material
□ Solo Cupertino widgets
□ Widgets extraídos a clases separadas

Tests
□ Tests unitarios para BLoC
□ Tests unitarios para Repository
□ Widget tests para componentes
□ Coverage >= 85%
□ Todos los tests pasan

Documentación
□ Comentarios en código complejo
□ README actualizado si aplica
```

### Comandos de Verificación

```bash
# 1. Linting
dart fix --apply && dart analyze

# 2. Tests
flutter test

# 3. Coverage
flutter test --coverage
lcov --summary coverage/lcov.info

# 4. Verificar Material imports (debe estar vacío)
grep -r "import 'package:flutter/material" lib/

# 5. Verificar métodos _build (debe estar vacío)
grep -rn "Widget _build" lib/
```

---

## 🔄 Proceso de Validación

1. **Recibir código** del Feature Generator o Apple Design
2. **Verificar** prohibiciones (Material, _buildX)
3. **Crear** estructura de tests
4. **Implementar** tests según templates
5. **Ejecutar** suite de tests
6. **Verificar** coverage >= 85%
7. **Reportar** resultados

---

## 📌 Comandos Rápidos

```bash
# Todo en uno
dart fix --apply && dart analyze && flutter test --coverage

# Solo tests de una feature
flutter test test/unit/presentation/features/ideas/

# Watch mode (desarrollo)
flutter test --watch

# Test específico
flutter test test/unit/presentation/features/ideas/bloc/ideas_bloc_test.dart
```
