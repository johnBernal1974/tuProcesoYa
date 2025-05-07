import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../../commons/main_layaout.dart';

class AdminReferidosPorReferidorPage extends StatelessWidget {
  final String referidorId;
  final String nombreReferidor;

  const AdminReferidosPorReferidorPage({
    Key? key,
    required this.referidorId,
    required this.nombreReferidor,
  }) : super(key: key);

  String _formatearFecha(DateTime fecha) {
    return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(fecha);
  }

  // Devuelve un mapa: semanaInicio => lista de referidos de esa semana
  Map<String, List<QueryDocumentSnapshot>> agruparPorSemana(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> agrupado = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = (data['fechaRegistro'] as Timestamp?)?.toDate();
      if (fecha == null) continue;

      final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final clave = '**Semana entre el ${_formatearFecha(inicioSemana)} y el ${_formatearFecha(finSemana)}**';

      agrupado.putIfAbsent(clave, () => []).add(doc);
    }

    return agrupado;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Referidos de $nombreReferidor',
      content: Container(
        width: MediaQuery.of(context).size.width >= 1000 ? 900 : double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('referidores')
              .doc(referidorId)
              .collection('referidos')
              .orderBy('fechaRegistro', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No hay referidos registrados.");
            }

            final referidosAgrupados = agruparPorSemana(snapshot.data!.docs);

            return LayoutBuilder(
              builder: (context, constraints) {
                final esEscritorio = constraints.maxWidth > 600;

                if (esEscritorio) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: referidosAgrupados.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                entry.key.replaceAll('**', ''),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            DataTable(
                              columns: const [
                                DataColumn(label: Text('Nombre')),
                                DataColumn(label: Text('Fecha de Registro')),
                                DataColumn(label: Text('Estado de Pago')),
                              ],
                              rows: entry.value.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final nombre = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}';
                                final fecha = (data['fechaRegistro'] as Timestamp?)?.toDate();
                                final fechaFormateada = fecha != null
                                    ? DateFormat('d \'de\' MMMM \'de\' y, hh:mm a', 'es').format(fecha)
                                    : 'Sin fecha';
                                final userId = data['userId'];

                                return DataRow(cells: [
                                  DataCell(Text(nombre, style: const TextStyle(fontSize: 13))),
                                  DataCell(Text(fechaFormateada, style: const TextStyle(fontSize: 13))),
                                  DataCell(
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection('Ppl').doc(userId).get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          );
                                        }

                                        if (!snapshot.hasData || !snapshot.data!.exists) {
                                          return const Icon(Icons.help_outline, color: Colors.grey);
                                        }

                                        final isPaid = snapshot.data!.get('isPaid') ?? false;
                                        return Icon(
                                          isPaid ? Icons.check_circle : Icons.cancel,
                                          color: isPaid ? Colors.green : Colors.red,
                                        );
                                      },
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return ListView(
                    children: referidosAgrupados.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              entry.key.replaceAll('**', ''),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          ...entry.value.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombre = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}';
                            final fecha = (data['fechaRegistro'] as Timestamp?)?.toDate();
                            final fechaFormateada = fecha != null
                                ? DateFormat('d \'de\' MMMM \'de\' y, hh:mm a', 'es').format(fecha)
                                : 'Sin fecha';
                            final userId = data['userId'];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nombre: $nombre', style: const TextStyle(fontSize: 13)),
                                  Text(fechaFormateada, style: const TextStyle(fontSize: 13)),
                                  Row(
                                    children: [
                                      const Text('Pago: ', style: TextStyle(fontSize: 13)),
                                      FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance.collection('Ppl').doc(userId).get(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            );
                                          }

                                          if (!snapshot.hasData || !snapshot.data!.exists) {
                                            return const Icon(Icons.help_outline, color: Colors.grey);
                                          }

                                          final isPaid = snapshot.data!.get('isPaid') ?? false;
                                          return Icon(
                                            isPaid ? Icons.check_circle : Icons.cancel,
                                            color: isPaid ? Colors.green : Colors.red,
                                            size: 18,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(color: gris),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
