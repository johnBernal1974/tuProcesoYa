import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SolicitudesBeneficioTablePage extends StatelessWidget {
  final String titulo;
  final String coleccion;

  const SolicitudesBeneficioTablePage({
    super.key,
    required this.titulo,
    required this.coleccion,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection(coleccion)
        .orderBy('fecha_solicitud', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Center(child: Text('No hay solicitudes.'));
            }

            final docs = snap.data!.docs;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Estado')),
                      DataColumn(label: Text('No. seguimiento')),
                      DataColumn(label: Text('Nombre del solicitante')),
                      DataColumn(label: Text('Identificación')),
                      DataColumn(label: Text('TD')),
                      DataColumn(label: Text('Fecha solicitud')),
                      DataColumn(label: Text('Fecha de revisión')),
                      DataColumn(label: Text('Fecha de respuesta')),
                    ],
                    rows: docs.map((d) {
                      final m = d.data() as Map<String, dynamic>;

                      final status = (m['status'] ?? '').toString();
                      final seguimiento = (m['numero_seguimiento'] ?? '').toString();
                      final nombre = (m['nombre_solicitante'] ?? '').toString();
                      final identificacion = (m['identificacion'] ?? '').toString();
                      final td = (m['td'] ?? '').toString();

                      final fechaSolicitud = _fmtDateTime(m['fecha_solicitud']);
                      final fechaRevision = _fmtDateTime(m['fecha_revision']);
                      final fechaRespuesta = _fmtDateTime(m['fecha_respuesta']);

                      final estadoColor = _estadoColor(status);
                      final filaColor = _filaColor(status);

                      return DataRow(
                        color: MaterialStatePropertyAll(filaColor),
                        cells: [
                          DataCell(Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: estadoColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status),
                            ],
                          )),
                          DataCell(Text(seguimiento)),
                          DataCell(Text(nombre)),
                          DataCell(Text(identificacion)),
                          DataCell(Text(td)),
                          DataCell(Text(fechaSolicitud)),
                          DataCell(Text(fechaRevision.isEmpty ? 'Pendiente' : fechaRevision)),
                          DataCell(Text(fechaRespuesta.isEmpty ? 'Pendiente' : fechaRespuesta)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String _fmtDateTime(dynamic v) {
    if (v == null) return '';
    DateTime? dt;
    if (v is Timestamp) dt = v.toDate();
    if (v is DateTime) dt = v;
    if (dt == null) return '';

    final f = DateFormat('dd-MM-yyyy · h:mm a', 'es_CO');
    return f.format(dt);
  }

  static Color _estadoColor(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'solicitado') return Colors.amber;
    if (s == 'respondido' || s == 'enviado') return Colors.green;
    if (s == 'vencido') return Colors.red;
    if (s == 'retrasado') return Colors.blue;
    return Colors.grey;
  }

  static Color _filaColor(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'solicitado') return const Color(0xFFFFF3CD); // amarillo suave
    if (s == 'respondido' || s == 'enviado') return const Color(0xFFD4EDDA); // verde suave
    if (s == 'vencido') return const Color(0xFFF8D7DA); // rojo suave
    if (s == 'retrasado') return const Color(0xFFD1ECF1); // azul suave
    return Colors.white;
  }
}
