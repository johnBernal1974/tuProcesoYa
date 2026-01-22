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

                              final fechaBase = _toDate(m['fecha'])!;
                              final fechaRevision = _toDate(m['fecha_revision_inpec']);
                              final fechaRespuesta = _toDate(m['fecha_respuesta_inpec']);

                              final estadoColor = _estadoColor(
                                status: status,
                                fechaBase: fechaBase,
                                fechaRevision: fechaRevision,
                                fechaRespuesta: fechaRespuesta,
                              );


                              return DataRow(
                                cells: [
                                  DataCell(
                                    Padding(
                                      padding: EdgeInsets.zero,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 15,
                                            height: 15,
                                            decoration: BoxDecoration(
                                              color: estadoColor, // 🔥 el estado se comunica solo con el punto
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              status,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
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

                                          final documento = (ppl['numero_documento_ppl'] ?? '')
                                              .toString()
                                              .trim();

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                full.isEmpty ? '-' : full,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 2),
                                              RichText(
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                text: documento.isEmpty
                                                    ? const TextSpan(
                                                  text: '-',
                                                  style: TextStyle(fontSize: 12, color: Colors.black),
                                                )
                                                    : TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: 'No. Identificación: ',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: documento,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.w700, // 🔥 solo el número en negrilla
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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

                                  _celdaEstadoPorTiempo(
                                    fechaBase: fechaBase,
                                    fechaNodo: m['fecha_revision_inpec'],
                                    horasLimite: 48,
                                    width: 150,
                                  ),

                                  _celdaEstadoPorTiempo(
                                    fechaBase: fechaBase,
                                    fechaNodo: m['fecha_respuesta_inpec'],
                                    horasLimite: 96,
                                    width: 160,
                                  ),


                                  // DataCell(
                                  //   SizedBox(
                                  //     width: 150,
                                  //     child: Text(
                                  //       fechaRevision.isEmpty ? 'Pendiente' : fechaRevision,
                                  //       style: const TextStyle(fontSize: 11),
                                  //       overflow: TextOverflow.ellipsis,
                                  //     ),
                                  //   ),
                                  // ),
                                  //
                                  // DataCell(
                                  //   SizedBox(
                                  //     width: 160,
                                  //     child: Text(
                                  //       fechaRespuesta.isEmpty ? 'Pendiente' : fechaRespuesta,
                                  //       style: const TextStyle(fontSize: 11),
                                  //       overflow: TextOverflow.ellipsis,
                                  //     ),
                                  //   ),
                                  // ),
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

  Color _estadoColor({
    required String status,
    required DateTime fechaBase,
    DateTime? fechaRevision,
    DateTime? fechaRespuesta,
  }) {
    final s = status.trim().toLowerCase();

    // 1️⃣ Solicitado siempre amarillo
    if (s == 'solicitado') {
      return Colors.amber;
    }

    final paso48 = _pasoTiempo(fechaBase, 48);
    final paso96 = _pasoTiempo(fechaBase, 96);

    final tieneRevision = fechaRevision != null;
    final tieneRespuesta = fechaRespuesta != null;

    // 4️⃣ VENCIDO (rojo)
    if ((paso48 && !tieneRevision) || (paso96 && !tieneRespuesta)) {
      return Colors.red;
    }

    // 3️⃣ RETRASADO (azul)
    if ((paso48 && tieneRevision) || (paso96 && tieneRespuesta)) {
      return Colors.blue;
    }

    // 2️⃣ OK / EN TIEMPO (verde)
    if (tieneRevision && tieneRespuesta && !paso48 && !paso96) {
      return Colors.green;
    }

    // fallback
    return Colors.grey;
  }


  //helpers de filtrado de estados de envio


  DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
  bool _pasoTiempo(DateTime base, int horas) {
    return DateTime.now().difference(base).inHours > horas;
  }

  bool _vencioDesde(DateTime? fechaBase, int horasLimite) {
    if (fechaBase == null) return false;
    final limite = fechaBase.add(Duration(hours: horasLimite));
    return DateTime.now().isAfter(limite);
  }

  DataCell _celdaEstadoPorTiempo({
    required DateTime? fechaBase,
    required dynamic fechaNodo,        // m['fecha_revision'] o m['fecha_respuesta']
    required int horasLimite,          // 48 o 96
    required double width,
  }) {
    final dtNodo = _toDate(fechaNodo);
    final tieneDato = dtNodo != null;

    final vencido = _vencioDesde(fechaBase, horasLimite);

    Color bg;
    String texto;

    if (vencido) {
      bg = const Color(0xFFF8D7DA); // rojo suave
      texto = tieneDato ? _fmtDateTime(dtNodo) : 'Vencido';
    } else {
      if (!tieneDato) {
        bg = const Color(0xFFFFF3CD); // amarillo suave
        texto = 'Pendiente';
      } else {
        bg = Colors.white;
        texto = _fmtDateTime(dtNodo);
      }
    }

    return DataCell(
      Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
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
