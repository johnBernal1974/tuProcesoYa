import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../providers/ppl_provider.dart';

class CalculoCondenaController with ChangeNotifier {
  int? _mesesCondena;
  int? _diasCondena;

  int? mesesRestante;
  int? diasRestanteExactos;
  int? mesesEjecutado;
  int? diasEjecutadoExactos;
  double? porcentajeEjecutado;

  double _totalDiasRedimidos = 0.0;

  final PplProvider _pplProvider;

  CalculoCondenaController(this._pplProvider);

  int? get mesesCondena => _mesesCondena;
  int? get diasCondena => _diasCondena;
  double get totalDiasRedimidos => _totalDiasRedimidos;

  /// ✅ Método principal para calcular tiempos
  Future<void> calcularTiempo(String id) async {
    try {
      final pplData = await _pplProvider.getById(id);
      if (pplData == null) {
        debugPrint("❌ No se encontró información del PPL");
        return;
      }

      final fechaCaptura = pplData.fechaCaptura;
      _mesesCondena = pplData.mesesCondena;
      _diasCondena = pplData.diasCondena;

      if (fechaCaptura == null || _mesesCondena == null || _diasCondena == null) {
        debugPrint("❌ Datos insuficientes para cálculo");
        return;
      }

      await calcularTotalRedenciones(id);
      debugPrint("📌 Días redimidos: $_totalDiasRedimidos");

      final totalDiasCondena = (_mesesCondena! * 30) + _diasCondena!;
      final condenaTotalDias = totalDiasCondena - _totalDiasRedimidos.toInt();

      if (condenaTotalDias <= 0) {
        porcentajeEjecutado = 100.0;
        mesesEjecutado = _mesesCondena;
        diasEjecutadoExactos = _diasCondena;
        mesesRestante = 0;
        diasRestanteExactos = 0;
        notifyListeners();
        return;
      }

      final fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura.add(Duration(days: condenaTotalDias));
      final diferenciaRestante = fechaFinCondena.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura);

      mesesRestante = diferenciaRestante.inDays ~/ 30;
      diasRestanteExactos = diferenciaRestante.inDays % 30;
      mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
      diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;

      porcentajeEjecutado = (diferenciaEjecutado.inDays / totalDiasCondena) * 100;

      notifyListeners();

      debugPrint("✅ Cálculo actualizado: % ejecutado: $porcentajeEjecutado%");
    } catch (e) {
      debugPrint("❌ Error en calcularTiempo: $e");
    }
  }

  /// ✅ Método para obtener la suma total de días redimidos
  Future<void> calcularTotalRedenciones(String pplId) async {
    try {
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('redenciones')
          .get();

      _totalDiasRedimidos = 0.0;

      for (var doc in redencionesSnapshot.docs) {
        _totalDiasRedimidos += (doc['dias_redimidos'] as num).toDouble();
      }

      debugPrint("📌 Total de días redimidos para PPL $pplId: $_totalDiasRedimidos días");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error obteniendo los días redimidos: $e");
      _totalDiasRedimidos = 0.0;
    }
  }

  /// ✅ Devuelve la condena total en meses (con decimales)
  double getCondenaEnMeses() {
    final meses = _mesesCondena ?? 0;
    final dias = _diasCondena ?? 0;
    return meses + (dias / 30);
  }
}
