# Plan: Impresión de facturas + Facturas por periodo

> Fecha: 2026-10-18 · Rama: `feature/novedades`
> Alcance: módulo `lib/features/admin/invoices/` (solo admin)

## 🎯 Objetivos

1. **Generar un PDF con todas las facturas de un periodo** (fecha inicio → fecha fin), con **1 factura por página**, para imprimir, descargar o compartir.
2. **Ver un listado de facturas por periodo** en pantalla (no en PDF), con totales (base, IVA, total) y desglose por estado.
3. Arreglar los problemas que salieron al revisar la impresión individual.

## 🗺️ Flujo propuesto

```
Tab Facturas
 ┌─────────────────────────────────────────────┐
 │ Facturas                   [📅 Por periodo] │ ← NUEVO botón en el header
 └─────────────────────────────────────────────┘
                    │
                    ▼
 ┌─────────────────────────────────────────────┐
 │  Facturas por periodo  (BottomSheet)        │
 │                                             │
 │  Atajos: [Este mes] [Mes anterior]          │
 │          [T1] [T2] [T3] [T4] [Año actual]   │
 │  Desde: 01/03/2026   Hasta: 31/07/2026  📅  │ ← showDateRangePicker
 │                                             │
 │  Estados:  ☑ Emitidas  ☑ Pagadas            │
 │            ☐ Anuladas  ☐ Borradores         │
 │                                             │
 │  ▸ 40 facturas · Total 12.430,50 €          │ ← vista previa en vivo
 │                                             │
 │  [ 📋 Ver listado ]  [ 🖨 PDF (40 págs.) ]  │
 └─────────────────────────────────────────────┘
        │                        │
        ▼                        ▼
 InvoicesPeriodScreen     Acciones del PDF:
 (listado en pantalla)     Imprimir · Compartir · Descargar
```

### Pantalla de listado (`InvoicesPeriodScreen`)

```
┌──────────────────────────────────────────────┐
│ ←  Facturas 01/03/2026 – 31/07/2026    [🖨] │
├──────────────────────────────────────────────┤
│ ┌──────────┐┌──────────┐┌──────────┐         │
│ │ 40       ││ Base     ││ Total    │  KPIs   │
│ │ facturas ││ 10.273 € ││ 12.430 € │  (Row + │
│ └──────────┘└──────────┘└──────────┘ Expanded│
│ IVA: 2.157 € · Pagadas 35 · Pendientes 5     │
├──────────────────────────────────────────────┤
│ MARZO 2026 ······················ 2.310,00 € │ ← agrupado por mes
│  F-2026/0012  15/03  JUAN PÉREZ   245,00 € ● │
│  F-2026/0013  18/03  ACME S.L.    520,00 € ● │
│ ABRIL 2026 ······················ 3.050,00 € │
│  ...                                         │
└──────────────────────────────────────────────┘
  Tocar una fila → InvoiceDetailScreen (como ya existe)
  [🖨] del AppBar → mismo PDF multipágina
```

## 📐 Decisiones de diseño

| Tema | Decisión | Motivo |
|---|---|---|
| Fecha que filtra | `issue_date` (fecha de emisión) | Es la fecha fiscal; ya hay índice `idx_invoices_issue_date` |
| Rango | Inclusivo: `issue_date >= inicio` y `issue_date <= fin` | El usuario espera que el 31/07 entre |
| Estados por defecto | Emitidas + Pagadas | Son las facturas fiscalmente válidas |
| Anuladas/Borradores | Opcionales, con **marca de agua** "ANULADA" / "BORRADOR" | Evita imprimir por error un borrador como si fuera válido |
| Orden | Por `invoice_number` ascendente | Numeración correlativa = orden lógico para la gestoría |
| Páginas | 1 factura = 1 página (`pw.Page`, igual que ahora) | Lo pedido; se reutiliza el diseño actual sin cambiarlo |
| Portada / resumen | Opcional: 1.ª página con el resumen del periodo (nº, base, IVA, total) | Útil para la gestoría; se activa con un check |
| Datos | Consulta nueva a Supabase por rango (no se filtra en memoria) | No depende de que el listado esté cargado; escala bien |
| Tabla/vista | `invoices` (no existe vista en Supabase, verificado) | Regla de comprobar vistas |
| Límite | Aviso si hay más de 150 facturas | Generar el PDF en el hilo principal puede tardar |
| Nombre de archivo | `Facturas_2026-03-01_a_2026-07-31.pdf` | Fácil de identificar |

## 🧱 Cambios por archivo

### Fase 1 — Datos

- **[domain] `invoices_repository.dart`**: añadir
  `Future<List<InvoiceEntity>> getByIssueDateRange({required DateTime start, required DateTime end, Set<InvoiceStatus>? statuses});`
- **[data] `invoices_repository_impl.dart`**: implementación con `.gte('issue_date')`, `.lte('issue_date')`, `.inFilter('status', ...)` y `.order('invoice_number')`, usando el mismo `select` con `bookings(...)` que ya tiene `getAll()`.

### Fase 2 — Servicio PDF (`invoice_pdf_service.dart`)

- Extraer la construcción de la página a `_addInvoicePage(pw.Document, InvoiceEntity)`.
- `generateInvoicePdf(invoice)` pasa a usar ese método (sin cambio visual).
- **NUEVO** `generateInvoicesBatchPdf(List<InvoiceEntity>, {DateTimeRange range, bool includeSummary})`:
  carga fuentes y logo **una sola vez** → portada opcional → 1 página por factura.
- **NUEVO** `printInvoicesBatch(...)`, `shareInvoicesBatch(...)` y `saveInvoicesBatchToFile(...)`, que reutilizan la lógica actual de share/save.
- **Marca de agua** diagonal "BORRADOR"/"ANULADA" mediante `pw.Stack` en `_buildPageContent` cuando el estado sea draft o cancelled. Se aplica también a la impresión individual.

### Fase 3 — BLoC nuevo `invoices_period_bloc` (Equatable, igual que `InvoicesBloc`)

`lib/features/admin/invoices/presentation/bloc/invoices_period_{bloc,event,state}.dart`

- Eventos: `PeriodRangeChanged(start, end)`, `PeriodStatusesChanged(set)`, `PeriodLoadRequested`, `PeriodPdfRequested(action: print|share|download, includeSummary)`.
- Estado: `start`, `end`, `statuses`, `invoices`, `isLoading`, `isGeneratingPdf`, `error`, y getters calculados: `count`, `totalBase`, `totalTax`, `totalAmount`, `invoicesByMonth`, `countByStatus`.
- Se mantiene separado de `InvoicesBloc` para no mezclar el filtro del periodo con el del listado principal.

### Fase 4 — UI

- **NUEVO** `widgets/period_selector_sheet.dart`: atajos (mes, trimestres, año), rango personalizado, checks de estado, contador en vivo y los 2 botones. `SafeArea(top: false)`.
- **NUEVO** `screens/invoices_period_screen.dart`: KPIs (`IntrinsicHeight` + `Row` + `Expanded`, iconos en `AppColors.primary`/gold), listado agrupado por mes y botón de imprimir en el AppBar. `SafeArea`.
- **NUEVO** widgets separados (sin `_buildX`): `period_kpi_row.dart`, `period_month_header.dart`, `period_invoice_row.dart` (badge de estado con `Align` + `IntrinsicWidth`).
- `invoices_tab.dart`: botón **"Por periodo"** en el header.
- Overlay de carga mientras se genera el PDF ("Generando 40 facturas…").

### Fase 5 — Arreglos de la impresión individual

| # | Problema | Arreglo |
|---|---|---|
| 1 | El botón "Generar PDF" en realidad imprime | Renombrar a **"Imprimir"** con icono `Icons.print_outlined` |
| 3 | Borradores/anuladas sin marca | Marca de agua (Fase 2) |
| 4 | "Copiar enlace" no copia nada | Quitar la opción y dejar una sola "Compartir PDF"; Email/WhatsApp ya usan el share nativo en móvil |
| 5 | En iOS, "Descargar" guarda en una carpeta oculta | Abrir el share sheet con "Guardar en Archivos" (alternativa: `UIFileSharingEnabled` en Info.plist) |
| 6 | Errores con SnackBar | Diálogo profesional de error (el proyecto no tiene `CeInfoDialog`: se crea uno compartido en `lib/shared/widgets/` o se usa el que indiques) |
| 8 | Clave `admin_invoice_generate_pdf` duplicada en `app_es.arb` | Eliminar la duplicada y revisar el resto de ARB |

### Fase 6 — l10n

Textos nuevos en `app_es/en/de/... .arb`: `admin_invoice_print`, `admin_invoices_period_title`, `admin_invoices_period_view_list`, `admin_invoices_period_pdf(count)`, presets (`this_month`, `last_month`, `quarter(n)`, `this_year`), `admin_invoices_period_empty`, `admin_invoices_period_generating(count)` y los de KPIs.
Tras editar las ARB: `flutter gen-l10n` (**pedir autorización**).

### Fase 7 — Tests

- `test/features/admin/invoices/invoices_period_bloc_test.dart`: carga OK y error, cambio de rango y estados, totales y agrupación por mes.
- `test/features/admin/invoices/invoice_pdf_service_test.dart`: el PDF por lotes tiene N páginas (o N+1 con portada) y una lista vacía lanza error controlado.
- Repositorio: mock de `InvoicesRepository` con mocktail.

## ✅ Verificación

1. `dart fix --apply && dart analyze` sin warnings (**pedir autorización**).
2. `flutter test` (**pedir autorización**).
3. Prueba manual: T1 con varias facturas → PDF de N páginas, una factura por página; listado con totales que cuadran con la suma de las facturas; las anuladas, si se incluyen, salen con marca de agua.

## ❓ Preguntas abiertas

1. ¿Incluir **portada con resumen** en el PDF por lotes? (Propuesta: sí, opcional).
2. ¿Las **anuladas** deben salir por defecto en el PDF para la gestoría? (Propuesta: no; solo si se marca el check).
3. ¿Quieres también **exportar el listado** (no las facturas) a PDF o CSV/Excel para la gestoría? (Fuera del alcance actual; sería fácil añadirlo después).
4. ¿Filtrar también por **alojamiento** (`property_id`)? (Propuesta: dejarlo para una fase 2).

## 📁 Resumen de archivos

| Acción | Archivo |
|---|---|
| ✏️ | `lib/features/admin/domain/repositories/invoices_repository.dart` |
| ✏️ | `lib/features/admin/data/repositories/invoices_repository_impl.dart` |
| ✏️ | `lib/features/admin/invoices/data/services/invoice_pdf_service.dart` |
| ✏️ | `lib/features/admin/invoices/presentation/screens/invoice_detail_screen.dart` |
| ✏️ | `lib/features/admin/invoices/presentation/widgets/invoices_tab.dart` |
| ✏️ | `lib/l10n/app_*.arb` |
| ➕ | `lib/features/admin/invoices/presentation/bloc/invoices_period_{bloc,event,state}.dart` |
| ➕ | `lib/features/admin/invoices/presentation/screens/invoices_period_screen.dart` |
| ➕ | `lib/features/admin/invoices/presentation/widgets/period_selector_sheet.dart` |
| ➕ | `lib/features/admin/invoices/presentation/widgets/period_kpi_row.dart` |
| ➕ | `lib/features/admin/invoices/presentation/widgets/period_month_header.dart` |
| ➕ | `lib/features/admin/invoices/presentation/widgets/period_invoice_row.dart` |
| ➕ | `test/features/admin/invoices/invoices_period_bloc_test.dart` |
| ➕ | `test/features/admin/invoices/invoice_pdf_service_test.dart` |
