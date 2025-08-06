import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class MisReferidosPage extends StatelessWidget {
  final String referidorId;

  const MisReferidosPage({
    Key? key,
    required this.referidorId,
  }) : super(key: key);

  final String nombreReferidor = 'Mis referidos';

  String _formatearFecha(DateTime fecha) {
    return DateFormat('d \'de\' MMMM \'de\' y', 'es').format(fecha);
  }

  Map<String, List<QueryDocumentSnapshot>> agruparPorSemana(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> agrupado = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = (data['fechaRegistro'] as Timestamp?)?.toDate();
      if (fecha == null) continue;

      final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));

      final clave = 'Semana entre el ${_formatearFecha(inicioSemana)} y el ${_formatearFecha(finSemana)}';
      agrupado.putIfAbsent(clave, () => []).add(doc);
    }

    return agrupado;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: nombreReferidor,
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
              return const Text("No tienes referidos registrados.");
            }

            final referidosDocs = snapshot.data!.docs;
            final referidosAgrupados = agruparPorSemana(referidosDocs);

            // Sacamos todos los idPpl
            final List<String> idsPpl = referidosDocs
                .map((doc) => (doc.data() as Map<String, dynamic>)['id'] as String)
                .toList();

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Ppl')
                  .where(FieldPath.documentId, whereIn: idsPpl)
                  .get(),
              builder: (context, snapshotPpl) {
                if (snapshotPpl.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // IDs de referidos que han pagado suscripción
                final Set<String> idsPagados = snapshotPpl.data!.docs
                    .where((doc) => doc.get('isPaid') == true)
                    .map((doc) => doc.id)
                    .toSet();

                // IDs de referidos con comisión ya pagada
                final Set<String> idsComisionPagada = referidosDocs
                    .where((doc) => (doc.data() as Map<String, dynamic>)['comisionPagada'] == true)
                    .map((doc) => doc.id)
                    .toSet();

                // Calcular totales
                final referidosPendientes = referidosDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data['id'];
                  return idsPagados.contains(id) && !(data['comisionPagada'] == true);
                }).length;

                final referidosPagadosComision = referidosDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data['id'];
                  return idsPagados.contains(id) && (data['comisionPagada'] == true);
                }).length;

                final int comisionPendiente = referidosPendientes * 2000;
                final int comisionPagadaTotal = referidosPagadosComision * 2000;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Cards de totales
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.green.shade50,
                            child: ListTile(
                              title: const Text(
                                'Comisión Pagada',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '\$${NumberFormat("#,##0", "es").format(comisionPagadaTotal)}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            color: Colors.orange.shade50,
                            child: ListTile(
                              title: const Text(
                                'Comisión Pendiente',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '\$${NumberFormat("#,##0", "es").format(comisionPendiente)}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Card superior actual
                    Container(
                      width: double.infinity,
                      child: Card(
                        color: Colors.white,
                        surfaceTintColor: blanco,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Comisión total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${NumberFormat("#,##0", "es").format(comisionPagadaTotal + comisionPendiente)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total de referidos: ${referidosDocs.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Lista por semanas
                    ...referidosAgrupados.entries.map((entry) {
                      final pagosSemana = entry.value
                          .where((doc) => idsPagados.contains((doc.data() as Map)['id']))
                          .length;
                      final totalSemana = pagosSemana * 2000;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Comisión total de esta semana: \$${NumberFormat("#,##0", "es").format(totalSemana)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cantidad de referidos: ${entry.value.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...entry.value.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombre = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}';
                            final fecha = (data['fechaRegistro'] as Timestamp?)?.toDate();
                            final fechaFormateada = fecha != null
                                ? DateFormat('d \'de\' MMMM \'de\' y, hh:mm a', 'es').format(fecha)
                                : 'Sin fecha';
                            final idPpl = data['id'];

                            final bool isPaid = idsPagados.contains(idPpl);
                            final bool comisionPagada = idsComisionPagada.contains(doc.id);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nombre: $nombre', style: const TextStyle(fontSize: 13)),
                                  Text(
                                    'Fecha registro: $fechaFormateada',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        isPaid ? Icons.check_circle : Icons.cancel,
                                        color: isPaid ? Colors.green : Colors.red,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isPaid
                                              ? 'Pagó la suscripción'
                                              : 'No ha pagado la suscripción',
                                          style: TextStyle(
                                            color: isPaid ? Colors.green : Colors.red,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (isPaid)
                                        Text(
                                          comisionPagada
                                              ? 'Comisión pagada'
                                              : 'Pendiente pago\nde comisión',
                                          style: TextStyle(
                                            color: comisionPagada ? Colors.green : Colors.orange,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                    ],
                                  ),
                                  Text(
                                    isPaid ? 'Comisión: \$2.000' : 'Comisión: \$0.000',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Divider(color: gris),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
