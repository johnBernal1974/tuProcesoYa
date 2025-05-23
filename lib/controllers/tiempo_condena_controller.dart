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

  int? mesesComputados;
  int? diasComputados;



  /// ✅ Método principal para calcular tiempos
  Future<void> calcularTiempo(String id) async {
    try {
      final pplData = await _pplProvider.getById(id);
      if (pplData == null) {
        debugPrint("❌ No se encontró información del PPL");
        return;
      }

      final DateTime? fechaCaptura = pplData.fechaCaptura;
      _mesesCondena = pplData.mesesCondena;
      _diasCondena = pplData.diasCondena;

      if (fechaCaptura == null || _mesesCondena == null || _diasCondena == null) {
        debugPrint("❌ Datos insuficientes para cálculo");
        return;
      }

      // 🔹 Obtener redenciones
      await calcularTotalRedenciones(id);
      debugPrint("📌 Días redimidos: $_totalDiasRedimidos");

      // 🔹 Total de días de condena
      final totalDiasCondena = (_mesesCondena! * 30) + _diasCondena!;

      // 🔹 Días efectivos de reclusión
      final diasEjecutados = await calcularDiasEjecutadosDesdeEstadias(id, fechaCaptura);

      // 🔹 Total computado = reclusión + redención
      final totalComputado = diasEjecutados + _totalDiasRedimidos.toInt();

      // 🔹 Ejecutado real (solo reclusión)
      mesesEjecutado = diasEjecutados ~/ 30;
      diasEjecutadoExactos = diasEjecutados % 30;

      // 🔹 Total computado en meses y días
      mesesComputados = totalComputado ~/ 30;
      diasComputados = totalComputado % 30;

      // 🔹 Tiempo restante
      final diasRestantes = totalDiasCondena - totalComputado;
      mesesRestante = diasRestantes ~/ 30;
      diasRestanteExactos = diasRestantes % 30;

      // 🔹 Porcentaje cumplido
      porcentajeEjecutado = (totalComputado / totalDiasCondena) * 100;

      notifyListeners();
      debugPrint("✅ Tiempo calculado con éxito");
      debugPrint("🔹 Reclusión efectiva: $mesesEjecutado meses y $diasEjecutadoExactos días");
      debugPrint("🔹 Redenciones: ${_totalDiasRedimidos.toInt()} días");
      debugPrint("🔹 Total computado: $mesesComputados meses y $diasComputados días");
      debugPrint("🔹 Porcentaje: ${porcentajeEjecutado?.toStringAsFixed(2)}%");
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

  /// ✅ Calcula la cantidad total de días en reclusión efectiva (excluye condicional/domiciliaria)
  Future<int> calcularDiasEjecutadosDesdeEstadias(String pplId, DateTime? fechaCaptura) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('estadias')
          .where('tipo', isEqualTo: 'Reclusión')
          .get();

      if (snapshot.docs.isEmpty) {
        if (fechaCaptura == null) return 0;
        final dias = DateTime.now().difference(fechaCaptura).inDays;
        debugPrint("📌 Usando fecha de captura, días ejecutados: $dias");
        return dias;
      }

      int totalDias = 0;
      final hoy = DateTime.now();

      for (var doc in snapshot.docs) {
        final entrada = (doc['fecha_ingreso'] as Timestamp).toDate();
        final salida = doc.data().containsKey('fecha_salida') && doc['fecha_salida'] != null
            ? (doc['fecha_salida'] as Timestamp).toDate()
            : hoy;

        totalDias += salida.difference(entrada).inDays;
      }

      debugPrint("📌 Total días de reclusión efectiva (estadías): $totalDias");
      return totalDias;
    } catch (e) {
      debugPrint("❌ Error al calcular días ejecutados desde estadías: $e");
      return 0;
    }
  }
}
