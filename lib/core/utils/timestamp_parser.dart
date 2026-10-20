/// Parsea un timestamp de Supabase (siempre UTC) y lo convierte a hora local.
/// Si el string no tiene sufijo 'Z' ni offset, se asume UTC.
DateTime parseUtcTimestamp(String timestamp) {
  final dt = DateTime.parse(timestamp);
  return dt.isUtc ? dt.toLocal() : DateTime.parse('${timestamp}Z').toLocal();
}
