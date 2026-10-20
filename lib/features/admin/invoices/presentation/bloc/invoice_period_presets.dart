/// Atajos de periodo para filtrar facturas por fecha de emisión.
/// Todas las fechas son días completos (sin hora) y el rango es inclusivo.
enum InvoicePeriodPreset {
  thisMonth('Este mes'),
  lastMonth('Mes anterior'),
  q1('T1'),
  q2('T2'),
  q3('T3'),
  q4('T4'),
  thisYear('Este año'),
  lastYear('Año anterior');

  const InvoicePeriodPreset(this.label);
  final String label;

  /// Devuelve (inicio, fin) del atajo tomando [now] como referencia.
  /// Los trimestres son siempre del año de [now].
  (DateTime, DateTime) range(DateTime now) {
    final year = now.year;
    return switch (this) {
      thisMonth => (DateTime(year, now.month), _lastDayOfMonth(year, now.month)),
      lastMonth => (
          DateTime(year, now.month - 1),
          _lastDayOfMonth(year, now.month - 1),
        ),
      q1 => (DateTime(year, 1), _lastDayOfMonth(year, 3)),
      q2 => (DateTime(year, 4), _lastDayOfMonth(year, 6)),
      q3 => (DateTime(year, 7), _lastDayOfMonth(year, 9)),
      q4 => (DateTime(year, 10), _lastDayOfMonth(year, 12)),
      thisYear => (DateTime(year), DateTime(year, 12, 31)),
      lastYear => (DateTime(year - 1), DateTime(year - 1, 12, 31)),
    };
  }

  /// `DateTime` normaliza el mes 0 a diciembre del año anterior,
  /// y el día 0 del mes siguiente es el último día del mes.
  static DateTime _lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0);
}
