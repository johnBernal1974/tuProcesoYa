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

      // 🔥 Obtener los días redimidos
      double diasRedimidos = await calcularTotalRedenciones(id);
      debugPrint("📌 Días redimidos: $diasRedimidos");

      // 🔥 Aplicar los días redimidos a la condena total
      int condenaTotalDias = (tiempoCondena! * 30) - diasRedimidos.toInt();
      if (condenaTotalDias < 0) condenaTotalDias = 0; // Evitar valores negativos

      DateTime fechaActual = DateTime.now();
      final fechaFinCondena = fechaCaptura.add(Duration(days: condenaTotalDias));
      final diferenciaRestante = fechaFinCondena.difference(fechaActual);
      final diferenciaEjecutado = fechaActual.difference(fechaCaptura);

      mesesRestante = (diferenciaRestante.inDays ~/ 30);
      diasRestanteExactos = diferenciaRestante.inDays % 30;
      mesesEjecutado = diferenciaEjecutado.inDays ~/ 30;
      diasEjecutadoExactos = diferenciaEjecutado.inDays % 30;

      // 🔥 Calcular porcentaje ejecutado con redenciones aplicadas
      porcentajeEjecutado = (diferenciaEjecutado.inDays / condenaTotalDias) * 100;
      if (condenaTotalDias == 0) porcentajeEjecutado = 100; // Si la condena es 0, se cumplió todo

      debugPrint("✅ Cálculo de condena actualizado:");
      debugPrint("   - Condena total (descontando redenciones): $condenaTotalDias días");
      debugPrint("   - Meses ejecutados: $mesesEjecutado - Días ejecutados: $diasEjecutadoExactos");
      debugPrint("   - Meses restantes: $mesesRestante - Días restantes: $diasRestanteExactos");
      debugPrint("   - Porcentaje ejecutado: ${porcentajeEjecutado!.toStringAsFixed(1)}%");

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error en calcularTiempo: $e");
    }
  }
  /// 🔥 Método para obtener la suma total de días redimidos
  Future<double> calcularTotalRedenciones(String pplId) async {
    try {
      QuerySnapshot redencionesSnapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('redenciones')
          .get();

      double totalDiasRedimidos = 0.0;
      for (var doc in redencionesSnapshot.docs) {
        totalDiasRedimidos += (doc['dias_redimidos'] as num).toDouble();
      }

      debugPrint("📌 Total de días redimidos para PPL $pplId: $totalDiasRedimidos días");
      return totalDiasRedimidos;
    } catch (e) {
      debugPrint("❌ Error obteniendo los días redimidos: $e");
      return 0.0; // Retornar 0 si hay error
    }
  }
}