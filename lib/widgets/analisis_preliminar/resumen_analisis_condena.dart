import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResumenAnalisisCondenaWidget extends StatefulWidget {
  final String docId;

  const ResumenAnalisisCondenaWidget({
    super.key,
    required this.docId,
  });

  @override
  State<ResumenAnalisisCondenaWidget> createState() => _ResumenAnalisisCondenaWidgetState();
}

class _ResumenAnalisisCondenaWidgetState extends State<ResumenAnalisisCondenaWidget> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  int _refreshTick = 0;

  void _refrescar() => setState(() => _refreshTick++);

  String _formatearMesesDias(int totalDias) {
    if (totalDias <= 0) return '0 días';
    final int meses = totalDias ~/ 30;
    final int dias = totalDias % 30;
    if (meses > 0 && dias > 0) return '$meses meses y $dias días';
    if (meses > 0) return '$meses meses';
    return '$dias días';
  }

  bool _esPantallaGrande(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final _ = _refreshTick;

    final ref = FirebaseFirestore.instance
        .collection('analisis_condena_ppl')
        .doc(widget.docId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Resumen actualizado'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('No se encontró el análisis.'));
          }

          final data = snap.data!.data() as Map<String, dynamic>;

          // ✅ BASE
          final fechaCaptura = (data['fecha_captura'] as Timestamp).toDate();
          final int totalCondenaDias = (data['total_condena_dias'] ?? 0) as int;
          final int diasRedimidos = (data['dias_redimidos'] ?? 0) as int;

          // ✅ DINÁMICO HOY
          final now = DateTime.now();
          int diasEjecutados = now
              .difference(DateTime(fechaCaptura.year, fechaCaptura.month, fechaCaptura.day))
              .inDays;
          if (diasEjecutados < 0) diasEjecutados = 0;

          final int diasCumplidos = diasEjecutados + diasRedimidos;

          int diasRestantes = totalCondenaDias - diasCumplidos;
          if (diasRestantes < 0) diasRestantes = 0;

          double porcentajeCumplido = 0;
          if (totalCondenaDias > 0) {
            porcentajeCumplido = (diasCumplidos / totalCondenaDias) * 100;
          }

          // ✅ helper de beneficio: calcula diferencia vs umbral
          int _diferenciaVsUmbral(double porcentajeReq) {
            final int diasUmbral = (totalCondenaDias * (porcentajeReq / 100)).round();
            return diasCumplidos - diasUmbral; // >=0 cumple
          }

          final diff72 = _diferenciaVsUmbral(33.33);
          final diffDomic = _diferenciaVsUmbral(50.0);
          final diffCond = _diferenciaVsUmbral(60.0);
          final diffExt = _diferenciaVsUmbral(100.0);

          // datos para cabecera
          final nombres = (data['nombres'] ?? '').toString();
          final apellidos = (data['apellidos'] ?? '').toString();
          final td = (data['td'] ?? '').toString();
          final nui = (data['nui'] ?? '').toString();
          final delito = (data['delito'] ?? '').toString();
          final delitoExcluido = (data['delito_excluido_beneficios'] ?? false) == true;

          // ✅ Caja centrada en PC
          final bool pc = _esPantallaGrande(context);
          final double maxWidth = pc ? 720 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, // ✅ fondo blanco
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300), // ✅ borde gris claro
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Encabezado
                      Text(
                        'Fecha de actualización: ${_dateFormat.format(now)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),

                      _filaDato('Nombre', '$nombres $apellidos'),
                      _filaDato('TD / NUI', '${td.isEmpty ? '—' : td} · ${nui.isEmpty ? '—' : nui}'),
                      _filaDato('Delito', '$delito${delitoExcluido ? ' (excluido de beneficios)' : ''}'),
                      _filaDato('Fecha de captura', _dateFormat.format(fechaCaptura)),
                      const Divider(height: 24),

                      // ---- Resumen cálculos
                      _filaDato('Condena total', _formatearMesesDias(totalCondenaDias)),
                      _filaDato('Días ejecutados (a hoy)', _formatearMesesDias(diasEjecutados)),
                      _filaDato('Días redimidos', _formatearMesesDias(diasRedimidos)),
                      _filaDato('Condena total cumplida', _formatearMesesDias(diasCumplidos)),
                      _filaDato('Condena restante', _formatearMesesDias(diasRestantes)),
                      _filaDato('% cumplido', '${porcentajeCumplido.toStringAsFixed(2)}%'),

                      const SizedBox(height: 16),
                      const Divider(height: 24),

                      // ---- Beneficios (con iconos + días)
                      const Text(
                        'Beneficios según porcentaje cumplido',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      _beneficioRow(
                        titulo: 'Permiso administrativo de hasta 72 horas',
                        porcentajeReq: 33.33,
                        diferencia: diff72,
                      ),
                      _beneficioRow(
                        titulo: 'Prisión domiciliaria',
                        porcentajeReq: 50.0,
                        diferencia: diffDomic,
                      ),
                      _beneficioRow(
                        titulo: 'Libertad condicional',
                        porcentajeReq: 60.0,
                        diferencia: diffCond,
                      ),
                      _beneficioRow(
                        titulo: 'Extinción de la pena',
                        porcentajeReq: 100.0,
                        diferencia: diffExt,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _filaDato(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 250,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(valor.trim().isEmpty ? '—' : valor, style: const TextStyle(
              fontSize: 11
            )),
          ),
        ],
      ),
    );
  }


  Widget _beneficioRow({
    required String titulo,
    required double porcentajeReq,
    required int diferencia,
  }) {
    final bool cumplido = diferencia >= 0;

    final IconData icono = cumplido ? Icons.check_circle : Icons.cancel;
    final Color colorIcono = cumplido ? Colors.green : Colors.red;

    final String textoExtra = cumplido
        ? 'Desde hace ${_formatearMesesDias(diferencia)}'
        : 'Faltan ${_formatearMesesDias(-diferencia)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: colorIcono, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requiere: ${porcentajeReq.toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  textoExtra,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cumplido ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
