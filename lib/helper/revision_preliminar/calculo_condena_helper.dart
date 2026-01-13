import 'package:cloud_firestore/cloud_firestore.dart';

int calcularDiasCumplidos({
  required Timestamp fechaCaptura,
  int diasRedimidos = 0,
}) {
  final hoy = DateTime.now();
  final captura = fechaCaptura.toDate();

  final diasFisicos = hoy.difference(captura).inDays;

  return diasFisicos + diasRedimidos;
}

double calcularPorcentajeCumplido({
  required int diasCumplidos,
  required int totalCondenaDias,
}) {
  if (totalCondenaDias == 0) return 0;
  return (diasCumplidos / totalCondenaDias) * 100;
}

