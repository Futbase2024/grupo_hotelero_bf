# New Feature Command

Genera una feature completa siguiendo la arquitectura del proyecto.

## Uso
```
/new-feature [nombre] [--pillar=X]
```

## Ejemplo
```
/new-feature scripts --pillar=content
```

## Proceso

1. Lee `.claude/CLAUDE.md` para contexto
2. Delega a `AG-01 (Feature Generator)`
3. Coordina con `AG-02 (Apple Design)` para UI
4. Finaliza con `AG-05 (QA)` para tests

## Output

Genera todos los archivos de la feature:
- Model (Freezed)
- Repository contract + impl
- BLoC + Events + States
- Page + Widgets separados
- Routes (GoRouteData)
- Tests base

## Post-Proceso

```bash
dart run build_runner build --delete-conflicting-outputs
dart fix --apply
dart analyze
```
