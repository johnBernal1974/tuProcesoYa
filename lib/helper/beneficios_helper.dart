enum BeneficioTipo { permiso72, domiciliaria, condicional, extincion }

String tituloBeneficio(BeneficioTipo t) {
  switch (t) {
    case BeneficioTipo.permiso72:
      return '72 horas';
    case BeneficioTipo.domiciliaria:
      return 'Prisión domiciliaria';
    case BeneficioTipo.condicional:
      return 'Libertad condicional';
    case BeneficioTipo.extincion:
      return 'Extinción de la pena';
  }
}

String campoBeneficio(BeneficioTipo t) {
  switch (t) {
    case BeneficioTipo.permiso72:
      return 'permiso72_cumplido';
    case BeneficioTipo.domiciliaria:
      return 'domiciliaria_cumplida';
    case BeneficioTipo.condicional:
      return 'libertad_condicional_cumplida';
    case BeneficioTipo.extincion:
      return 'extincion_pena_cumplida';
  }
}

/// ✅ Devuelve el beneficio MÁS ALTO que cumple la persona.
/// Orden: Extinción > Condicional > Domiciliaria > 72
BeneficioTipo? beneficioMasAlto(Map<String, dynamic> data) {
  final bool ext = data[campoBeneficio(BeneficioTipo.extincion)] == true;
  final bool con = data[campoBeneficio(BeneficioTipo.condicional)] == true;
  final bool dom = data[campoBeneficio(BeneficioTipo.domiciliaria)] == true;
  final bool h72 = data[campoBeneficio(BeneficioTipo.permiso72)] == true;

  if (ext) return BeneficioTipo.extincion;
  if (con) return BeneficioTipo.condicional;
  if (dom) return BeneficioTipo.domiciliaria;
  if (h72) return BeneficioTipo.permiso72;
  return null; // no cumple ninguno
}

bool cumpleBeneficio(Map<String, dynamic> data, BeneficioTipo tipo) {
  return data[campoBeneficio(tipo)] == true;
}

/// Texto "Desde hace X" o "Faltan X"
String textoEstadoBeneficio(
    Map<String, dynamic> data,
    BeneficioTipo tipo,
    ) {
  final bool cumple = data[campoBeneficio(tipo)] == true;

  final int diasCumplidos = (data['dias_cumplidos'] ?? 0) as int;
  final int totalCondena = (data['total_condena_dias'] ?? 0) as int;

  double porcentajeRequerido;
  switch (tipo) {
    case BeneficioTipo.permiso72:
      porcentajeRequerido = 33.33;
      break;
    case BeneficioTipo.domiciliaria:
      porcentajeRequerido = 50;
      break;
    case BeneficioTipo.condicional:
      porcentajeRequerido = 60;
      break;
    case BeneficioTipo.extincion:
      porcentajeRequerido = 100;
      break;
  }

  final int diasUmbral = (totalCondena * (porcentajeRequerido / 100)).round();

  if (cumple) {
    int desde = diasCumplidos - diasUmbral;
    if (desde < 0) desde = 0;
    return 'Desde hace ${_formatearDias(desde)}';
  } else {
    int faltan = diasUmbral - diasCumplidos;
    if (faltan < 0) faltan = 0;
    return 'Faltan ${_formatearDias(faltan)}';
  }
}

String _formatearDias(int dias) {
  if (dias <= 0) return '0 días';
  final meses = dias ~/ 30;
  final resto = dias % 30;
  if (meses > 0 && resto > 0) return '$meses meses y $resto días';
  if (meses > 0) return '$meses meses';
  return '$resto días';
}

List<BeneficioTipo> beneficiosHasta(BeneficioTipo top) {
  switch (top) {
    case BeneficioTipo.permiso72:
      return [BeneficioTipo.permiso72];
    case BeneficioTipo.domiciliaria:
      return [BeneficioTipo.permiso72, BeneficioTipo.domiciliaria];
    case BeneficioTipo.condicional:
      return [BeneficioTipo.permiso72, BeneficioTipo.domiciliaria, BeneficioTipo.condicional];
    case BeneficioTipo.extincion:
      return [BeneficioTipo.permiso72, BeneficioTipo.domiciliaria, BeneficioTipo.condicional, BeneficioTipo.extincion];
  }
}

