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
  int? tiempoCondena; // Tiempo total de condena en meses
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
      tiempoCondena = totalDiasCondena ~/ 30;


      // 🔹 Días efectivos de reclusión
      final diasEjecutados = await calcularDiasEfectivosDesdeEstadias(id, fechaCaptura);

      // 🔹 Total computado = reclusión + redención
      final totalComputado = diasEjecutados + _totalDiasRedimidos.toInt();

      // 🔹 Ejecutado real (solo reclusión)
      mesesEjecutado = diasEjecutados ~/ 30;
      diasEjecutadoExactos = diasEjecutados % 30;

      // 🔹 Total computado en meses y días
      mesesComputados = totalComputado ~/ 30;
      diasComputados = totalComputado % 30;

      // 🔹 Tiempo restante
      var diasRestantes = totalDiasCondena - totalComputado;
      if (diasRestantes <= 0) {
        // ✅ Ya cumplió o superó la condena
        diasRestantes = 0;
        mesesRestante = 0;
        diasRestanteExactos = 0;
        porcentajeEjecutado = 100.0;
      } else {
        mesesRestante = diasRestantes ~/ 30;
        diasRestanteExactos = diasRestantes % 30;
        porcentajeEjecutado = (totalComputado / totalDiasCondena) * 100;
      }

      if (porcentajeEjecutado! > 100) {
        porcentajeEjecutado = 100.0;
      }

      notifyListeners();
      debugPrint("✅ Tiempo calculado con éxito");
      debugPrint("🔹 Reclusión efectiva: $mesesEjecutado meses y $diasEjecutadoExactos días");
      debugPrint("🔹 Redenciones: ${_totalDiasRedimidos.toInt()} días");
      debugPrint("🔹 Total computado: $mesesComputados meses y $diasComputados días");
      debugPrint("🔹 Porcentaje: ${porcentajeEjecutado?.toStringAsFixed(2)}%");
      debugPrint("🔹 Dias restantes: $diasRestantes");
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
  Future<int> calcularDiasEfectivosDesdeEstadias(String pplId, DateTime? fechaCaptura) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(pplId)
          .collection('estadias')
          .get();

      if (snapshot.docs.isEmpty) {
        if (fechaCaptura == null) return 0;
        return DateTime.now().difference(fechaCaptura).inDays;
      }

      // 🔹 Tipos presentes
      final tiposPresentes = snapshot.docs
          .map((doc) => doc.data()['tipo'] as String)
          .toSet();

      // 🔹 Ordenar estadías por ingreso
      final listaEstadiasOrdenadas = snapshot.docs
          .map((doc) => doc.data())
          .toList()
        ..sort((a, b) {
          final ingresoA = (a['fecha_ingreso'] as Timestamp).toDate();
          final ingresoB = (b['fecha_ingreso'] as Timestamp).toDate();
          return ingresoA.compareTo(ingresoB);
        });

      // 🔹 Detectar revocatorias según las reglas
      bool excluirDomiciliaria = false;
      bool excluirCondicional = false;

      for (int i = 0; i < listaEstadiasOrdenadas.length - 2; i++) {
        final tipo1 = listaEstadiasOrdenadas[i]['tipo'];
        final tipo2 = listaEstadiasOrdenadas[i + 1]['tipo'];
        final tipo3 = listaEstadiasOrdenadas[i + 2]['tipo'];

        if (tipo1 == 'Reclusión' && tipo2 == 'Domiciliaria' && tipo3 == 'Reclusión') {
          excluirDomiciliaria = true;
        }

        if (tipo1 == 'Reclusión' && tipo2 == 'Condicional' && tipo3 == 'Reclusión') {
          excluirCondicional = true;
        }

        if (i <= listaEstadiasOrdenadas.length - 4) {
          final tipo4 = listaEstadiasOrdenadas[i + 3]['tipo'];
          if (tipo1 == 'Reclusión' &&
              tipo2 == 'Domiciliaria' &&
              tipo3 == 'Condicional' &&
              tipo4 == 'Reclusión') {
            excluirDomiciliaria = false; // ✅ SE INCLUYE
            excluirCondicional = true;   // ❌ SE EXCLUYE
          }
        }
      }

      // 🔹 Definir tipos a sumar
      Set<String> tiposQueSuman = {};

      if (tiposPresentes.contains('Reclusión')) {
        tiposQueSuman.add('Reclusión');
      }
      if (tiposPresentes.contains('Domiciliaria') && !excluirDomiciliaria) {
        tiposQueSuman.add('Domiciliaria');
      }
      if (tiposPresentes.contains('Condicional') && !excluirCondicional) {
        tiposQueSuman.add('Condicional');
      }

      // 🔹 Calcular días efectivos
      int totalDiasEfectivos = 0;
      final hoy = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tipo = data['tipo'] as String;
        if (tiposQueSuman.contains(tipo)) {
          final ingreso = (data['fecha_ingreso'] as Timestamp).toDate();
          final salida = data['fecha_salida'] != null
              ? (data['fecha_salida'] as Timestamp).toDate()
              : hoy;
          totalDiasEfectivos += salida.difference(ingreso).inDays;
        }
      }

      debugPrint("✅ Total días efectivos para PPL $pplId (tipos sumados: $tiposQueSuman): $totalDiasEfectivos");
      return totalDiasEfectivos;
    } catch (e) {
      debugPrint("❌ Error calculando días efectivos: $e");
      return 0;
    }
  }

}
