import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../src/colors/colors.dart';

class SolicitudesBeneficioTablePage extends StatefulWidget {
  final String titulo;
  final String coleccion;

  const SolicitudesBeneficioTablePage({
    super.key,
    required this.titulo,
    required this.coleccion,
  });

  @override
  State<SolicitudesBeneficioTablePage> createState() => _SolicitudesBeneficioTablePageState();
}

class _SolicitudesBeneficioTablePageState extends State<SolicitudesBeneficioTablePage> {
  final _pplCache = <String, Future<DocumentSnapshot<Map<String, dynamic>>>>{};

  Future<DocumentSnapshot<Map<String, dynamic>>> _pplFuture(String pplId) {
    if (pplId.trim().isEmpty) {
      // Future “vacío” para no crashear
      return Future.value(
        FakeDocumentSnapshot<Map<String, dynamic>>({}, exists: false),
      );
    }
    return _pplCache.putIfAbsent(
      pplId,
          () => FirebaseFirestore.instance.collection('Ppl').doc(pplId).get(),
    );
  }

  Widget _pplCell({
    required String pplId,
    required Widget Function(Map<String, dynamic> ppl) builder,
  }) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _pplFuture(pplId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 60,
            height: 14,
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: blancoCards,
              color: Colors.grey, // ✅ correcto
            ),
          );

        }

        if (!snap.hasData || !(snap.data?.exists ?? false)) {
          return const Text('-', style: TextStyle(fontSize: 11));
        }

        final data = snap.data!.data() ?? {};
        return builder(data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection(widget.coleccion)
        .orderBy('fecha', descending: true);

    const gridColor = Color(0xFFB0B0B0); // gris medio

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.titulo),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 24 : 12,
                  vertical: 12,
                ),
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
                        constraints: BoxConstraints(
                          minWidth: isWide ? 1000 : constraints.maxWidth,
                        ),
                        child: SingleChildScrollView(
                          child: DataTable(
                            // ✅ CUADRÍCULA COMPLETA (interno + externo)
                            border: TableBorder.all(color: gridColor, width: 1),

                            // ✅ Grosor del divisor horizontal interno
                            dividerThickness: 1,

                            // ✅ Reduce espacio entre columnas
                            columnSpacing: 8,
                            horizontalMargin: 10,

                            headingRowHeight: 40,
                            dataRowMinHeight: 44,
                            dataRowMaxHeight: 56,

                            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),

                            columns: const [
                              DataColumn(
                                label: SizedBox(
                                  width: 95,
                                  child: Text('Estado', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 110,
                                  child: Text('No. seguimiento', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 220,
                                  child: Text('Solicitante', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 95,
                                  child: Text('NUI', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 75,
                                  child: Text('TD', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 150,
                                  child: Text('Fecha solicitud.', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 150,
                                  child: Text('Fecha revisión.', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                              DataColumn(
                                label: SizedBox(
                                  width: 160,
                                  child: Text('Fecha respuesta.', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                            rows: docs.map((d) {
                              final m = d.data() as Map<String, dynamic>;

                              final status = (m['status'] ?? '').toString();
                              final seguimiento = (m['numero_seguimiento'] ?? '').toString();

                              // ✅ ID del solicitante en la solicitud: "id"
                              final pplId = (m['idUser'] ?? '').toString();

                              // ✅ Fecha solicitud viene de "fecha"
                              final fechaSolicitud = _fmtDateTime(m['fecha']);
                              final fechaRevision = _fmtDateTime(m['fecha_revision']);
                              final fechaRespuesta = _fmtDateTime(m['fecha_respuesta']);

                              final estadoColor = _estadoColor(status);
                              final filaColor = _filaColor(status);

                              return DataRow(
                                color: MaterialStatePropertyAll(filaColor),
                                cells: [
                                  DataCell(
                                    Row(
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
                                        Expanded(
                                          child: Text(
                                            status,
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        seguimiento,
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  // ✅ Nombre desde Ppl
                                  DataCell(
                                    SizedBox(
                                      width: 220,
                                      child: _pplCell(
                                        pplId: pplId,
                                        builder: (ppl) {
                                          final nombre = (ppl['nombre_ppl'] ?? '').toString().trim();
                                          final apellido = (ppl['apellido_ppl'] ?? '').toString().trim();
                                          final full = ('$nombre $apellido').trim();
                                          return Text(
                                            full.isEmpty ? '-' : full,
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // ✅ NUI desde Ppl
                                  DataCell(
                                    SizedBox(
                                      width: 95,
                                      child: _pplCell(
                                        pplId: pplId,
                                        builder: (ppl) {
                                          final nui = (ppl['nui'] ?? '').toString().trim();
                                          return Text(
                                            nui.isEmpty ? '-' : nui,
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // ✅ TD desde Ppl
                                  DataCell(
                                    SizedBox(
                                      width: 75,
                                      child: _pplCell(
                                        pplId: pplId,
                                        builder: (ppl) {
                                          final td = (ppl['td'] ?? '').toString().trim();
                                          return Text(
                                            td.isEmpty ? '-' : td,
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        fechaSolicitud,
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: Text(
                                        fechaRevision.isEmpty ? 'Pendiente' : fechaRevision,
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  DataCell(
                                    SizedBox(
                                      width: 160,
                                      child: Text(
                                        fechaRespuesta.isEmpty ? 'Pendiente' : fechaRespuesta,
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
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
            ),
          );
        },
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
    if (s == 'solicitado') return const Color(0xFFFFF3CD);
    if (s == 'respondido' || s == 'enviado') return const Color(0xFFD4EDDA);
    if (s == 'vencido') return const Color(0xFFF8D7DA);
    if (s == 'retrasado') return const Color(0xFFD1ECF1);
    return Colors.white;
  }
}


class FakeDocumentSnapshot<T> implements DocumentSnapshot<T> {
  @override
  final T? _data;

  @override
  final bool exists;

  FakeDocumentSnapshot(this._data, {required this.exists});

  @override
  T? data() => _data;

  // ---- lo demás no se usa, pero toca implementarlo ----
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
