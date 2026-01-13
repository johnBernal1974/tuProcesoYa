
//HELPER PARA CREAR EL ID  CON EL NUMERO DEL DOCUMENTO

String buildPplId({
  required String tipoDocumento,
  required String numeroDocumento,
}) {
  final t = tipoDocumento.trim().toUpperCase();
  final n = numeroDocumento.trim().replaceAll(RegExp(r'\s+'), '');

  String tipoCorto;
  if (t.contains('CIUDAD')) {
    tipoCorto = 'CC';
  } else if (t.contains('EXTRAN')) {
    tipoCorto = 'CE';
  } else {
    tipoCorto =
        t.replaceAll(RegExp(r'[^A-Z0-9]'), '').substring(0, 3);
  }

  return '${tipoCorto}_$n';
}
