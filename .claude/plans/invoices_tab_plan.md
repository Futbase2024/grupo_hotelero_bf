# Plan: Tab de Facturación Profesional

## Resumen
Crear un nuevo tab en el admin dashboard para generar facturas profesionales vinculadas a reservas, visible solo para administradores.

## Requisitos
- **Relación**: Facturas vinculadas a reservas existentes
- **Datos**: Factura completa con datos fiscales españoles
- **Visibilidad**: Solo para usuarios con rol admin

---

## Fase 1: Base de Datos (Supabase)

### 1.1 Tabla `invoices`
```sql
CREATE TABLE public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,  -- Format: BF-2026-0001
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES public.properties(id),

  -- Datos del emisor (empresa)
  issuer_name TEXT NOT NULL,           -- Nombre empresa
  issuer_nif TEXT NOT NULL,            -- NIF/CIF emisor
  issuer_address TEXT,                 -- Dirección fiscal
  issuer_city TEXT,
  issuer_postal_code TEXT,

  -- Datos del cliente (huésped)
  client_name TEXT NOT NULL,           -- Nombre/Razón social
  client_nif TEXT,                     -- NIF/CIF cliente (opcional)
  client_email TEXT,
  client_phone TEXT,
  client_address TEXT,
  client_city TEXT,
  client_postal_code TEXT,

  -- Detalles de la factura
  issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date DATE,
  concept TEXT NOT NULL,               -- Descripción del servicio
  period_start DATE,                   -- Periodo facturado
  period_end DATE,

  -- Líneas de factura (JSONB array)
  -- [{"description": "Alojamiento 2 noches", "quantity": 1, "unit_price": 150.00, "tax_rate": 10}]
  line_items JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- Totales
  subtotal_excluding_tax NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax_base NUMERIC(12,2) NOT NULL DEFAULT 0,
  tax_rate NUMERIC(5,2) NOT NULL DEFAULT 10,  -- IVA (10% alojamientos)
  tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  total_including_tax NUMERIC(12,2) NOT NULL DEFAULT 0,

  -- Estado
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'issued', 'paid', 'cancelled')),
  issued_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,

  -- Metadatos
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID REFERENCES auth.users(id),

  -- Índices
  CONSTRAINT valid_invoice_number CHECK (invoice_number ~ '^BF-\d{4}-\d{4}$')
);

-- Índices
CREATE INDEX idx_invoices_booking_id ON public.invoices(booking_id);
CREATE INDEX idx_invoices_property_id ON public.invoices(property_id);
CREATE INDEX idx_invoices_status ON public.invoices(status);
CREATE INDEX idx_invoices_issue_date ON public.invoices(issue_date);
CREATE INDEX idx_invoices_invoice_number ON public.invoices(invoice_number);

-- RLS
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
```

### 1.2 Función para generar número de factura
```sql
CREATE OR REPLACE FUNCTION public.generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  v_year INT := EXTRACT(YEAR FROM CURRENT_DATE);
  v_next_num INT;
  v_invoice_number TEXT;
BEGIN
  -- Obtener siguiente número secuencial del año
  SELECT COALESCE(MAX(CAST(SPLIT_PART(invoice_number, '-', 3) AS INT)), 0) + 1
  INTO v_next_num
  FROM public.invoices
  WHERE invoice_number LIKE 'BF-' || v_year || '-%';

  v_invoice_number := 'BF-' || v_year || '-' || LPAD(v_next_num::TEXT, 4, '0');
  RETURN v_invoice_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 1.3 Trigger para updated_at
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_invoices_updated_at
BEFORE UPDATE ON public.invoices
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
```

---

## Fase 2: Dominio (Entities)

### 2.1 `InvoiceEntity` (lib/features/admin/domain/entities/invoice_entity.dart)
```dart
@freezed
class InvoiceEntity with _$InvoiceEntity {
  const factory InvoiceEntity({
    required String id,
    required String invoiceNumber,
    required String bookingId,
    required String propertyId,

    // Emisor
    required String issuerName,
    required String issuerNif,
    String? issuerAddress,
    String? issuerCity,
    String? issuerPostalCode,

    // Cliente
    required String clientName,
    String? clientNif,
    String? clientEmail,
    String? clientPhone,
    String? clientAddress,
    String? clientCity,
    String? clientPostalCode,

    // Fechas
    required DateTime issueDate,
    DateTime? dueDate,
    required String concept,
    DateTime? periodStart,
    DateTime? periodEnd,

    // Líneas y totales
    required List<InvoiceLineItem> lineItems,
    required double subtotalExcludingTax,
    required double taxBase,
    required double taxRate,
    required double taxAmount,
    required double totalIncludingTax,

    // Estado
    required InvoiceStatus status,
    DateTime? issuedAt,
    DateTime? paidAt,
    DateTime? cancelledAt,
    String? cancellationReason,

    String? notes,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) = _InvoiceEntity;
}

@freezed
class InvoiceLineItem with _$InvoiceLineItem {
  const factory InvoiceLineItem({
    required String description,
    required int quantity,
    required double unitPrice,
    required double taxRate,
  }) = _InvoiceLineItem;
}

enum InvoiceStatus { draft, issued, paid, cancelled }
```

---

## Fase 3: BLoC y Estado

### 3.1 Eventos
- `InvoicesLoadRequested` - Cargar facturas
- `InvoicesFilterChanged` - Cambiar filtro de estado
- `InvoicesSearchChanged` - Buscar por número/cliente
- `InvoiceCreateRequested` - Crear nueva factura
- `InvoiceUpdateRequested` - Actualizar factura
- `InvoiceIssueRequested` - Emitir factura (cambiar a issued)
- `InvoiceMarkPaidRequested` - Marcar como pagada
- `InvoiceCancelRequested` - Cancelar factura

### 3.2 Estado
```dart
@freezed
class InvoicesState with _$InvoicesState {
  const factory InvoicesState({
    @Default([]) List<InvoiceEntity> invoices,
    @Default(false) bool isLoading,
    String? error,
    String? statusFilter,
    String? searchQuery,
    InvoiceEntity? selectedInvoice,
  }) = _InvoicesState;
}
```

---

## Fase 4: UI (Widgets)

### 4.1 `InvoicesTab` (lib/features/admin/dashboard/presentation/widgets/invoices_tab.dart)
- Header con título
- Filter chips: Todas, Borrador, Emitidas, Pagadas, Canceladas
- Search bar (número factura, cliente)
- Lista de facturas con:
  - Número de factura
  - Cliente
  - Fecha emisión
  - Total
  - Badge de estado
- FAB para crear nueva factura

### 4.2 `InvoiceListTile` - Card de factura en lista
### 4.3 `CreateInvoiceBottomSheet` - Formulario de creación
- Selector de reserva (con búsqueda)
- Auto-completado de datos del huésped
- Líneas de factura (añadir/eliminar)
- Cálculo automático de totales
- Vista previa antes de guardar

### 4.4 `InvoiceDetailScreen` - Detalle de factura
- Todos los datos de la factura
- Acciones según estado:
  - Draft: Editar, Emitir, Eliminar
  - Issued: Marcar pagada, Cancelar, Descargar PDF
  - Paid: Descargar PDF
  - Cancelled: Ver motivo

---

## Fase 5: Integración en Admin Dashboard

### 5.1 Modificar `admin_dashboard_screen.dart`
- Añadir `InvoicesTab()` a la lista de tabs
- Añadir item "Facturas" al BottomNavigationBar (icon: `Icons.receipt_long`)
- Mantener visibilidad solo para admin

### 5.2 Orden de tabs
1. Resumen
2. Reservas
3. Check-ins
4. **Facturas** (nuevo, solo admin)
5. Alojamientos (solo admin)

---

## Archivos a Crear/Modificar

### Nuevos
1. `lib/features/admin/domain/entities/invoice_entity.dart`
2. `lib/features/admin/domain/entities/invoice_line_item.dart`
3. `lib/features/admin/invoices/presentation/bloc/invoices_bloc.dart`
4. `lib/features/admin/invoices/presentation/bloc/invoices_event.dart`
5. `lib/features/admin/invoices/presentation/bloc/invoices_state.dart`
6. `lib/features/admin/invoices/presentation/widgets/invoices_tab.dart`
7. `lib/features/admin/invoices/presentation/widgets/invoice_list_tile.dart`
8. `lib/features/admin/invoices/presentation/widgets/create_invoice_bottom_sheet.dart`
9. `lib/features/admin/invoices/presentation/screens/invoice_detail_screen.dart`
10. `lib/features/admin/invoices/presentation/widgets/line_items_editor.dart`
11. `lib/features/admin/domain/repositories/invoices_repository.dart`
12. `lib/features/admin/data/repositories/invoices_repository_impl.dart`

### Modificar
1. `lib/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart` - Añadir tab
2. `lib/features/admin/domain/bloc/admin_dashboard_bloc.dart` - Añadir carga de facturas
3. `lib/features/admin/domain/bloc/admin_dashboard_state.dart` - Añadir estado de facturas
4. `lib/features/admin/domain/bloc/admin_dashboard_event.dart` - Añadir eventos de facturas
5. `lib/core/di/injection.dart` - Registrar repositorio
6. `lib/core/router/app_router.dart` - Añadir ruta detalle factura

---

## Orden de Implementación

1. ✅ Crear plan (este archivo)
2. ⬜ Ejecutar migración en Supabase (tablas, funciones, triggers)
3. ⬜ Crear entity de factura
4. ⬜ Crear repositorio (contrato + implementación)
5. ⬜ Crear BLoC de facturas
6. ⬜ Crear widgets del tab (InvoicesTab, InvoiceListTile)
7. ⬜ Crear bottom sheet de creación de factura
8. ⬜ Modificar admin_dashboard_screen para añadir tab
9. ⬜ Crear pantalla de detalle de factura
10. ⬜ Ejecutar `dart fix --apply && dart analyze`
11. ⬜ Testing

---

## Notas Técnicas

- **IVA Alojamientos turísticos**: 10% (reducido en España)
- **Formato número factura**: BF-AAAA-NNNN (ej: BF-2026-0001)
- **Estados**: draft → issued → paid / cancelled
- **PDF**: Futura implementación con paquete `pdf` o `syncfusion_flutter_pdf`
