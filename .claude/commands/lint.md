# Lint Command

Ejecuta el proceso completo de linting y análisis.

## Uso
```
/lint
```

## Proceso

Ejecuta secuencialmente:

```bash
# 1. Aplicar fixes automáticos
dart fix --apply

# 2. Analizar código
dart analyze

# 3. Verificar formato
dart format --output=none --set-exit-if-changed lib/
```

## Verificaciones Adicionales

- Busca métodos `_buildX()` que devuelvan Widget (PROHIBIDO)
- Busca imports de Material (PROHIBIDO)
- Verifica que solo hay Cupertino widgets

## Comandos de Detección

```bash
# Detectar _build methods (debe estar vacío)
grep -rn "Widget _build" lib/

# Detectar Material imports (debe estar vacío)
grep -r "import 'package:flutter/material" lib/
```
