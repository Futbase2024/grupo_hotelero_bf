# AmbuTrack Web - Project Context

> **Contexto específico del proyecto para desarrollo de AmbuTrack Web**

---

## Project Overview

**AmbuTrack Web** es una aplicación web diseñada para la gestión integral de servicios de ambulancias y emergencias médicas.

### Misión
> Facilitar la gestión diaria de servicios de ambulancias y emergencias médicas.

### Visión
> Convertirse en el sistema de referencia para la gestión de servicios médicos de emergencia.

---

## Target User

### Perfil Principal
- **Rol:** Coordinadores de servicios de ambulancias
- **Edad:** 30-60 años
- **Ubicación:** España
- **Contexto:** Trabaja en centros de salud, hospitales, bases de ambulancias
- **Horario:** Turnos rotativos (mañana, tarde, noche, fines de semana)

### Usuarios Secundarios
- Despachadores médicos
- Personal sanitario (conductores, técnicos)
- Gestores de flota
- Administradores

### Pain Points
- Dificultad para trackear ambulancias en tiempo real
- Comunicación fragmentada (teléfono, WhatsApp, radio)
- Gestión manual de stock y equipamiento
- Dificultad para planificar servicios
- Tracking manual de mantenimiento e ITV
- Gestión dispersa de personal y turnos

### Contexto de Uso
- **Horario:** 24/7 (turnos rotativos)
- **Lugares:** Centro de coordinación, ambulancia, hospital
- **Condiciones:** Alta presión, decisiones rápidas, multi-tasking
- **Dispositivos:** Desktop (centro), Tablet (ambulancia), Mobile (campo)

---

## Design Principles for AmbuTrack

### 1. Profesionalidad ante todo
Cada pantalla debe responder: "¿Cómo esto ayuda a gestionar emergencias mejor?"

### 2. Claridad visual
Información crítica visible de un vistazo. Colores semánticos para estados.

### 3. Accesibilidad en condiciones adversas
Alto contraste para entornos con poca luz. Touch targets grandes para uso con guantes.

### 4. Velocidad de operación
Las tareas críticas (asignar servicio, trackear ambulancia) deben ser de 1-2 clics.

### 5. Lenguaje visual médico
Usar colores y metáforas del sector: azul médico, verde salud, rojo emergencia.

### 6. Información en tiempo real
Mostrar datos actualizados con indicadores de sync.

---

## Features & Priority

| Feature | Priority | Status | Platform |
|---------|----------|--------|----------|
| Dashboard | P0 | 🎨 Diseñado | Web + Tablet |
| Flota de ambulancias | P0 | 🎨 Diseñado | Web |
| Personal sanitario | P0 | 🎨 Diseñado | Web |
| Planificación de servicios | P0 | 🎨 Diseñado | Web |
| Tracking GPS | P1 | 📋 Pendiente | Web + Mobile |
| Mantenimiento e ITV | P1 | 🎨 Diseñado | Web |
| Almacén y stock | P2 | 🎨 Diseñado | Web |
| Tablas maestras | P2 | 🎨 Diseñado | Web |
| Informes y analytics | P3 | 📋 Pendiente | Web |
| Configuración | P3 | 📋 Pendiente | Web |

---

## Technical Stack

- **Framework:** Flutter (web + future mobile)
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Real-Time)
- **Design System:** Material Design 3 + Custom tokens
- **Icons:** Material Icons + Custom medical icons
- **State:** BLoC pattern
- **Database:** PostgreSQL (via Supabase)
- **Auth:** Supabase Auth

---

## Terminology (Spanish)

| English | Spanish (UI) |
|---------|--------------|
| Dashboard | Panel Principal / Inicio |
| Fleet | Flota / Ambulancias |
| Vehicles | Vehículos |
| Staff | Personal |
| Drivers | Conductores |
| Paramedics | Técnicos / Sanitarios |
| Services | Servicios |
| Shifts | Turnos |
| Schedule | Planificación |
| Maintenance | Mantenimiento |
| Inspection | ITV / Inspección |
| Inventory | Inventario / Stock |
| Warehouse | Almacén |
| Suppliers | Proveedores |
| Available | Disponible |
| In Service | En servicio |
| Maintenance | Mantenimiento |
| Out of Service | Fuera de servicio |
| Emergency | Emergencia |
| High Priority | Alta prioridad |
| Medium Priority | Media prioridad |
| Low Priority | Baja prioridad |

---

## Common Screen Patterns

### List Screen (Vehículos, Personal, Servicios)
1. Search bar (sticky top)
2. Filter chips (horizontal scroll)
3. Card list or data table (vertical scroll)
4. FAB for create action
5. Pull to refresh
6. Empty state if no items

### Detail Screen (Vehículo, Personal, Servicio)
1. App bar with back + actions
2. Header (photo, primary info) - collapsible
3. Tab bar for sections
4. Tab content
5. Optional bottom action bar

### Form Screen (Add/Edit)
1. App bar with cancel + save
2. Form sections with headers
3. Validation inline
4. Save button (sticky bottom or top-right)

### Service Assignment Screen
1. Service info (header)
2. Available vehicles list
3. Available personnel list
4. Assign button (sticky bottom)
5. Real-time sync indicator

---

## Content Examples (For Mockups)

### Vehicle Names (Spanish)
- AMB-001 (Base Centro)
- AMB-002 (Base Norte)
- UVI-001 (Unidad Vida Intensiva)
- SVB-001 (Soporte Vital Básico)
- HELI-001 (Helicóptero medicalizado)

### Personnel Names (Spanish)
- María García López
- Juan Rodríguez Martínez
- Carmen Fernández Sánchez
- Pedro Díaz Ruiz
- Ana Torres Jiménez

### Service Locations
- Hospital Universitario
- Centro de Salud Centro
- Residencia Mayores San José
- Polideportivo Municipal
- Aeropuerto Internacional

### Status Examples
- Disponible
- En servicio
- Mantenimiento programado
- Fuera de servicio
- Emergencia activa

---

## Responsive Behavior

### Mobile (< 600px)
- Full-width cards
- FAB for primary action
- Swipe gestures enabled
- Bottom navigation

### Tablet (600-1023px)
- Grid layout (2 columns)
- Larger touch targets
- Side navigation

### Desktop (≥ 1024px)
- Data tables with pagination
- Sidebar navigation (expanded)
- Master-detail views
- Hover states
- Keyboard shortcuts

---

## Color Usage Guidelines

### Status Colors

| Estado | Color | Uso |
|--------|-------|-----|
| Disponible | Verde | Ambulancia lista para asignar |
| En servicio | Azul | Ambulancia en servicio activo |
| Mantenimiento | Amarillo | Ambulancia en taller/ITV |
| Inactivo | Gris | Ambulancia no disponible |
| Emergencia | Rojo | Alerta crítica, emergencia activa |

### Priority Colors

| Prioridad | Color | Uso |
|-----------|-------|-----|
| Alta | Naranja | Servicios urgentes |
| Media | Amarillo oscuro | Servicios normales |
| Baja | Verde | Servicios no urgentes |

---

**Última actualización:** 2025-02-09
