# Skill: Debug con MCP Dart

Flujos de debugging usando las herramientas del MCP de Dart/Flutter.

---

## Herramientas Disponibles

| Herramienta | Descripción |
|-------------|-------------|
| `launch_app` | Inicia la app Flutter y retorna su DTD URI |
| `stop_app` | Detiene la app |
| `list_devices` | Lista dispositivos disponibles |
| `list_running_apps` | Ver apps en ejecución |
| `hot_reload` | Aplicar cambios manteniendo estado |
| `hot_restart` | Aplicar cambios reiniciando estado |
| `get_runtime_errors` | Obtener errores recientes |
| `get_widget_tree` | Obtener árbol de widgets |
| `get_selected_widget` | Info del widget seleccionado |
| `get_app_logs` | Ver logs de la app |

---

## Flujo 1: Iniciar Sesión de Debug

```
1. list_devices                    # Ver dispositivos disponibles
2. launch_app device: [device_id]  # Iniciar app en dispositivo
3. get_app_logs                    # Verificar que inició correctamente
```

---

## Flujo 2: Iteración Rápida de UI

```
1. Editar código del widget
2. hot_reload                      # Aplicar cambios
3. get_widget_tree                 # Verificar estructura
4. Repetir hasta satisfecho
```

**Cuándo usar hot_restart en lugar de hot_reload:**
- Cambios en `initState()`
- Cambios en constructores
- Cambios en código de inicialización
- Cuando hot_reload no refleja los cambios

---

## Flujo 3: Debug de Errores Visuales

```
1. get_runtime_errors              # Ver errores actuales
2. Analizar el error:
   - RenderFlex overflow → Ajustar constraints
   - Null check operator → Verificar nullability
   - Build errors → Revisar widget tree
3. Corregir código
4. hot_reload
5. get_runtime_errors              # Verificar que se resolvió
```

---

## Flujo 4: Inspección de Widgets

```
1. get_widget_tree                 # Ver árbol completo
2. Buscar el widget problemático
3. get_selected_widget             # Info detallada (si está seleccionado en DevTools)
```

**Qué buscar en el widget tree:**
- Jerarquía Material 3 correcta (Scaffold → AppBar → Body)
- No hay widgets Cupertino donde no deberían
- Estructura de layouts (Column, Row, Stack)
- Presencia de LoadingOverlay, FMEmptyState, etc.

---

## Flujo 5: Verificar Paridad Mobile-Desktop

```
1. list_devices                    # Ver dispositivos
2. launch_app device: [mobile]     # Iniciar en mobile
3. launch_app device: [desktop]    # Iniciar en desktop (otra instancia)
4. get_widget_tree                 # Comparar ambos
```

**Qué comparar:**
- Mismos estados (empty, loading, error, loaded)
- Mismas acciones disponibles
- Mismos datos mostrados

---

## Flujo 6: Debug de Estado de BLoC

```
1. get_app_logs                    # Ver eventos del BLoC
2. Buscar:
   - Eventos emitidos
   - Estados transicionados
   - Errores en handlers
3. Corregir lógica
4. hot_restart                     # Reiniciar para limpiar estado
5. get_app_logs                    # Verificar flujo correcto
```

---

## Flujo 7: Finalizar Sesión

```
1. stop_app                        # Detener app
2. list_running_apps               # Verificar que se detuvo
```

---

## Errores Comunes y Soluciones

### RenderFlex Overflow
```
get_runtime_errors  # Identificar widget
```
**Solución:** Envolver en `Expanded`, `Flexible`, o `SingleChildScrollView`

### Null Check Operator Used on Null Value
```
get_app_logs  # Ver stack trace
```
**Solución:** Verificar nullability, usar `?.` o manejar el caso null

### Widget Build Errors
```
get_widget_tree  # Identificar widget padre problemático
```
**Solución:** Revisar constraints, tipos de datos, rebuilds innecesarios

### Hot Reload No Funciona
```
hot_restart  # Forzar reinicio completo
```
**Causa:** Cambios en `initState`, constructores, o static fields

---

## Tips

1. **Mantén la app corriendo** durante todo el desarrollo para aprovechar hot_reload
2. **Usa `get_runtime_errors` frecuentemente** para detectar problemas temprano
3. **Verifica el widget tree** después de cambios significativos en la UI
4. **Combina con `analyze_files`** para detectar errores estáticos además de runtime
5. **Documenta errores encontrados** en el reporte de validación

---

## Integración con Otros Agentes

| Agente | Cuándo Usar Este Skill |
|--------|------------------------|
| UIDesignerAgent | Durante desarrollo de layouts y widgets |
| QAValidatorAgent | Validación runtime en paso final |
| FeatureBuilderAgent | Debug de lógica de BLoC |
