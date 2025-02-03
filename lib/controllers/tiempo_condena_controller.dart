import 'package:flutter/cupertino.dart';

import '../providers/ppl_provider.dart';

class CalculoCondenaController with ChangeNotifier {
  int? tiempoCondena;
  int? mesesRestante;
  int? diasRestanteExactos;
  int? mesesEjecutado;
  int? diasEjecutadoExactos;
  double? porcentajeEjecutado;

  final PplProvider _pplProvider;

  CalculoCondenaController(this._pplProvider);

  Future<void> calcularTiempo(String id) async {
    final pplData = await _pplProvider.getById(id);
    if (pplData != null) {
      final fechaCaptura = pplData.fechaCaptura;
      tiempoCondena = pplData.tiempoCondena;
      final fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura?.add(Duration(days: tiempoCondena! * 30));

      final diferenciaRestante = fechaFinCondena?.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura!);

      mesesRestante = (diferenciaRestante!.inDays ~/ 30)!;
      diasRestanteExactos = diferenciaRestante.inDays % 30;

      mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
      diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;

      // Validaciones para beneficios
      porcentajeEjecutado = (diferenciaEjecutado.inDays / (tiempoCondena! * 30)) * 100;

      notifyListeners();
    }
  }
}