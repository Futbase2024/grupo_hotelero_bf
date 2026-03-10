# Plan: Tab de Marketing en Admin Panel

> **Fecha**: 2026-03-09
> **Prioridad**: Alta
> **Estimación**: Feature completa

---

## 🎯 Objetivo

Crear un nuevo tab de **Marketing** en el panel de administración que incluya:

1. **Panel Admin de Marketing** - Métricas y KPIs
2. **Sistema de Campañas** - Crear, editar, activar campañas
3. **Automatizaciones** - Reglas automáticas de comunicación
4. **CRM de Huéspedes** - Gestión de huéspedes con tags y segmentos

---

## 📊 Estructura de la Base de Datos (Supabase)

### Tablas Necesarias

```sql
-- 1. Campañas de Marketing
CREATE TABLE marketing_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL CHECK (type IN ('email', 'push', 'sms', 'whatsapp')),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'active', 'paused', 'completed')),
    target_audience JSONB DEFAULT '{}',
    content JSONB DEFAULT '{}',
    schedule_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- 2. Automatizaciones
CREATE TABLE marketing_automations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    trigger_event TEXT NOT NULL,
    trigger_conditions JSONB DEFAULT '{}',
    action_type TEXT NOT NULL CHECK (action_type IN ('email', 'push', 'sms', 'whatsapp')),
    action_content JSONB DEFAULT '{}',
    delay_minutes INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CRM - Huéspedes con tags
CREATE TABLE marketing_guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES guests(id),
    email TEXT,
    phone TEXT,
    tags TEXT[] DEFAULT '{}',
    segments TEXT[] DEFAULT '{}',
    total_bookings INT DEFAULT 0,
    total_spent DECIMAL(10,2) DEFAULT 0,
    last_contact_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Historial de comunicaciones
CREATE TABLE marketing_communications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    guest_id UUID REFERENCES guests(id),
    campaign_id UUID REFERENCES marketing_campaigns(id),
    type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Segmentos de huéspedes
CREATE TABLE marketing_segments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    criteria JSONB DEFAULT '{}',
    guest_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 📁 Estructura de Archivos

```
lib/features/admin/marketing/
├── data/
│   ├── models/
│   │   ├── campaign_model.dart
│   │   ├── automation_model.dart
│   │   ├── marketing_guest_model.dart
│   │   └── segment_model.dart
│   └── repositories/
│       └── marketing_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── campaign_entity.dart
│   │   ├── automation_entity.dart
│   │   ├── marketing_guest_entity.dart
│   │   └── segment_entity.dart
│   └── repositories/
│       └── marketing_repository.dart
└── presentation/
    ├── bloc/
    │   ├── marketing_bloc.dart
    │   ├── marketing_event.dart
    │   └── marketing_state.dart
    ├── screens/
    │   ├── campaign_detail_screen.dart
    │   ├── automation_detail_screen.dart
    │   └── guest_crm_screen.dart
    └── widgets/
        ├── marketing_tab.dart          <-- Tab principal
        ├── campaigns_section.dart
        ├── automations_section.dart
        ├── crm_section.dart
        ├── metrics_overview.dart
        ├── campaign_card.dart
        ├── automation_card.dart
        └── guest_card.dart
```

---

## 🎨 Diseño del Tab Marketing

### Layout Principal (Marketing Tab)

```
┌─────────────────────────────────────────────────────────────┐
│  📊 MARKETING                                    [+ Campaña] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐          │
│  │ 📧 156  │ │ 📱 89   │ │ 💬 42   │ │ 📱 234  │          │
│  │ Emails  │ │ Push    │ │ SMS     │ │ WhatsApp│          │
│  │ enviados│ │ enviados│ │ enviados│ │ enviados│          │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘          │
│                                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│  🎯 CAMPañAS ACTIVAS                              Ver todo →│
│  ┌───────────────────────────────────────────────────────┐ │
│  │ 📧 Bienvenida Huéspedes                               │ │
│  │    Activa • 234 enviados • 45% apertura               │ │
│  └───────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ 📱 Recordatorio Check-out                             │ │
│  │    Programada • Mañana 10:00                          │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│  ⚡ AUTOMATIZACIONES                               Ver todo →│
│  ┌───────────────────────────────────────────────────────┐ │
│  │ ✓ Bienvenida automática al hacer check-in             │ │
│  │   Email • Sin delay                                   │ │
│  └───────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ ✓ Recordatorio check-out (24h antes)                  │ │
│  │   Push • 24h delay                                    │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                             │
│  👥 CRM HUÉSPEDES                                 Ver todo →│
│  ┌───────────────────────────────────────────────────────┐ │
│  │ 👤 Juan García                               ⭐ VIP    │ │
│  │    5 reservas • 1,250€ total • Último: hace 2 sem.    │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
│  💰 Coste Servicios                                        │
│  ┌───────────────────────────────────────────────────────┐ │
│  │ Brevo:     Gratis hasta 300/día                       │ │
│  │ Firebase:  Gratis                                     │ │
│  │ Supabase:  Ya contratado                              │ │
│  │ ─────────────────────────────────────────────────────  │ │
│  │ TOTAL:     0€/mes                                     │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 Checklist de Implementación

### Fase 1: Infraestructura
- [ ] Crear tablas en Supabase (marketing_campaigns, marketing_automations, marketing_guests, marketing_communications, marketing_segments)
- [ ] Crear entidades en `domain/entities/`
- [ ] Crear modelos en `data/models/`
- [ ] Crear contrato repository en `domain/repositories/`
- [ ] Crear implementación repository en `data/repositories/`

### Fase 2: BLoC
- [ ] Crear MarketingEvent
- [ ] Crear MarketingState
- [ ] Crear MarketingBloc

### Fase 3: UI - Tab Principal
- [ ] Crear `marketing_tab.dart` (vista principal)
- [ ] Crear `metrics_overview.dart` (KPIs)
- [ ] Crear `campaigns_section.dart`
- [ ] Crear `automations_section.dart`
- [ ] Crear `crm_section.dart`

### Fase 4: Integración
- [ ] Modificar `admin_dashboard_screen.dart` para agregar tab
- [ ] Modificar `AdminDashboardBloc` si es necesario
- [ ] Registrar en DI

### Fase 5: Funcionalidades Avanzadas
- [ ] Pantalla de detalle de campaña
- [ ] Pantalla de detalle de automatización
- [ ] Pantalla CRM de huéspedes
- [ ] Crear/Editar campañas
- [ ] Crear/Editar automatizaciones

---

## 🔗 Servicios Externos (Coste 0€)

| Servicio | Uso | Coste |
|----------|-----|-------|
| **Brevo** | Emails transaccionales | Gratis hasta 300/día |
| **Firebase Cloud Messaging** | Push notifications | Gratis |
| **Supabase** | Base de datos | Ya contratado |

**Total mensual: 0€**

---

## ⚠️ Notas Importantes

1. El tab será **solo visible para Admin** (no para Staff)
2. Usar `AppColors` para todo el diseño
3. Seguir el patrón de BLoC existente
4. Los widgets deben ser responsivos
5. Implementar pull-to-refresh en listas
