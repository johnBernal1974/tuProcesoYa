import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../providers/ppl_provider.dart';

class CalculoCondenaController with ChangeNotifier {
  int? tiempoCondena;
  int? mesesRestante;
  int? diasRestanteExactos;
  int? mesesEjecutado;
  int? diasEjecutadoExactos;
  double? porcentajeEjecutado;

  double _totalDiasRedimidos = 0.0; // 🔥 Variable privada para almacenar días redimidos

  double get totalDiasRedimidos => _totalDiasRedimidos; // 🔥 Getter para acceder a los días redimidos

  final PplProvider _pplProvider;

  CalculoCondenaController(this._pplProvider);

  Future<void> calcularTiempo(String id) async {
    try {
      final pplData = await _pplProvider.getById(id);
      if (pplData == null) {
        debugPrint("❌ No se encontró información del PPL");
        return;
      }

      final fechaCaptura = pplData.fechaCaptura;
      tiempoCondena = pplData.tiempoCondena;
      if (fechaCaptura == null || tiempoCondena == null) {
        debugPrint("❌ Datos insuficientes: fechaCaptura o tiempoCondena es null");
        return;
      }

      await calcularTotalRedenciones(id);
      debugPrint("📌 Días redimidos: $_totalDiasRedimidos");

      int condenaTotalDias = (tiempoCondena! * 30) - _totalDiasRedimidos.toInt();

      // 🔥 Condena ya cumplida o inválida
      if (condenaTotalDias <= 0) {
        porcentajeEjecutado = 100.0;
        mesesEjecutado = tiempoCondena; // se cumplió todo
        diasEjecutadoExactos = 0;
        mesesRestante = 0;
        diasRestanteExactos = 0;
        notifyListeners();
        return;
      }

      DateTime fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura.add(Duration(days: condenaTotalDias));
      final diferenciaRestante = fechaFinCondena.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura);

      mesesRestante = diferenciaRestante.inDays ~/ 30;
      diasRestanteExactos = diferenciaRestante.inDays % 30;
      mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
      diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;

      porcentajeEjecutado = (diferenciaEjecutado.inDays / condenaTotalDias) * 100;
      notifyListeners();

      debugPrint("✅ Cálculo actualizado: % ejecutado: $porcentajeEjecutado%");
    } catch (e) {
      debugPrint("❌ Error en calcularTiempo: $e");
    }
  }


  /// 🔥 Método para obtener la suma total de días redimidos
  Future<void> calcularTotalRedenciones(String pplId) async {
    try {
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('redenciones')
          .get();

      _totalDiasRedimidos = 0.0; // Reiniciar antes de sumar

      for (var doc in redencionesSnapshot.docs) {
        _totalDiasRedimidos += (doc['dias_redimidos'] as num).toDouble();
      }

      debugPrint("📌 Total de días redimidos para PPL $pplId: $_totalDiasRedimidos días");
      notifyListeners(); // 🔥 Notificar cambios
    } catch (e) {
      debugPrint("❌ Error obteniendo los días redimidos: $e");
      _totalDiasRedimidos = 0.0;
    }
  }
}
