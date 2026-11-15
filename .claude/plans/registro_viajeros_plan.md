# Plan — Registro de viajeros (RD 933/2021)

Fecha: 2026-11-15 · Rama: `features/registronuevo`

## Decisiones del usuario
1. El check-in lo sigue haciendo el **huésped online** (flujo actual).
2. Los 2.475 huéspedes antiguos **no se completan ni se separan**: quedan con
   `register_format = 'legacy'` y su `full_name` intacto.
3. **SES.HOSPEDAJES queda para el futuro** (sin alta ni credenciales). No se crean
   aún tablas `ses_*` ni Edge Functions.
4. Fotos de documentos **sin cambios** (marca COPIA + borrado 24 h).

## Fase 2 — Base de datos (migraciones escritas, pendientes de revisión)
| Migración | Contenido |
|---|---|
| `20261115110000_traveller_register_fields` | Campos legales en `guests`, menores en `booking_guests`, validadores puros |
| `20261115110100_traveller_entry_forms_signatures` | `traveller_entry_forms` + `guest_signatures`, inmutables, RLS |
| `20261115110200_traveller_register_rpcs` | `save_traveller_guest`, `traveller_register_issues`, `sign_traveller_entry_form`, `submit_traveller_checkin` |

Compatibilidad: **no se modifica ninguna RPC existente**. Las versiones antiguas
de la app siguen usando `insert_guest_for_booking` / `submit_guest_checkin`
y generan registros `legacy`. Cuando la nueva versión esté publicada, el
usuario sube `app_config.app_version.min` y en una migración posterior se
endurece `submit_guest_checkin`.

## Fase 3 — Wizard (Flutter)
Sustituye los pasos actuales por: ① Identificación (+ fotos existentes)
② Residencia y contacto ③ Revisión, parte y firma por huésped ≥14.
Validadores Dart espejo de los SQL, con tests unitarios.

## Fases 5/6 — Menores y firmas
Incluidas en las RPC de la Fase 2; la UI va en la Fase 3.

## Estado 2026-11-15
- Migraciones 110000, 110100, 110200, 120000 (interruptor por reserva, por defecto
  apagado: el método principal sigue siendo la foto) y 130000 (GRANT SELECT de la
  columna) **aplicadas** en producción.
- Panel: `TravellerFormToggleCard` en el detalle de reserva.
- Huésped: módulo `lib/features/guest/traveller_register/` (entidad, validadores
  espejo de SQL, reglas por pantalla, repositorio, BLoC y wizard de 3 pantallas).
  `CheckinScreen` lo muestra solo si `travellerFormEnabled`.
- Países: `lib/core/constants/countries.dart` generado desde CLDR (ICU de macOS),
  249 países ISO 3166-1 alfa-3 en es/en/de/fr/it/pt.
- Tests: 158 en verde, `dart analyze` sin avisos.

## Pendiente / futuro
- Probar en dispositivo real (móvil y web) con una reserva de prueba.
- Revisión por asesoría del texto de protección de datos (`guest_traveller_privacy_body`).
- Panel de administración del registro: ver partes y firmas por huésped (Fase 8).
- Purga a los 3 años desde el fin de la estancia (cron nuevo).
- Registro de accesos a fotos y limpieza de políticas duplicadas del bucket.
- PDF del parte (`traveller_entry_forms.pdf_path`).
- SES: mapeo de códigos (sexo, tipo doc, parentesco, país) contra los XSD oficiales.
- Umbrales legales (14 / 18 años, campos obligatorios) centralizados en
  `_traveller_guest_issues`: validar con asesoría.
