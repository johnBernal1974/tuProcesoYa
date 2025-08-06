import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import '../../../commons/admin_provider.dart';
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

            final referidosDocs = snapshot.data!.docs;
            final referidosAgrupados = agruparPorSemana(referidosDocs);

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

                final Set<String> idsPagados = snapshotPpl.data!.docs
                    .where((doc) => doc.get('isPaid') == true)
                    .map((doc) => doc.id)
                    .toSet();

                final Set<String> idsComisionPagada = referidosDocs
                    .where((doc) => (doc.data() as Map<String, dynamic>)['comisionPagada'] == true)
                    .map((doc) => doc.id)
                    .toSet();

                // Referidos que han pagado la suscripción pero aún no tienen comisión pagada
                final referidosPendientes = referidosDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data['id'];
                  final pagado = idsPagados.contains(id);
                  final comisionPagada = data['comisionPagada'] == true;
                  return pagado && !comisionPagada;
                }).toList();

                final int comisionPendiente = referidosPendientes.length * 2000;

                // Referidos que ya tienen comisión pagada
                final referidosPagadosComision = referidosDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = data['id'];
                  final pagado = idsPagados.contains(id);
                  final comisionPagada = data['comisionPagada'] == true;
                  return pagado && comisionPagada;
                }).toList();

                final int comisionPagadaTotal = referidosPagadosComision.length * 2000;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cards superiores de totales
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

                      // Lista por semanas
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

                            // Detalle de cada referido
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
                                          IconButton(
                                            icon: Icon(
                                              comisionPagada
                                                  ? Icons.verified
                                                  : Icons.attach_money,
                                              color: comisionPagada
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                            tooltip: comisionPagada
                                                ? 'Comisión ya pagada'
                                                : 'Marcar comisión como pagada',
                                            onPressed: comisionPagada
                                                ? null
                                                : () async {
                                              final confirmar = await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor: blanco,
                                                  title: const Text("Confirmar pago de comisión"),
                                                  content: Text(
                                                    "¿Deseas marcar esta comisión como pagada para $nombre?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context).pop(false),
                                                      child: const Text("Cancelar"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context).pop(true),
                                                      child: const Text("Confirmar"),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmar == true) {
                                                final adminNombre = AdminProvider().adminFullName ?? 'desconocido'; // Aquí tomas el nombre del admin logueado
                                                final referidoNombre = nombre; // Ya lo tienes
                                                const monto = 2000;

                                                // 🔹 1. Actualizar comisión en el documento del referido
                                                await FirebaseFirestore.instance
                                                    .collection('referidores')
                                                    .doc(referidorId)
                                                    .collection('referidos')
                                                    .doc(doc.id)
                                                    .update({'comisionPagada': true});

                                                // 🔹 2. Registrar pago en colección de auditoría
                                                await FirebaseFirestore.instance.collection('pagos_comisiones').add({
                                                  'referidorId': referidorId,
                                                  'referidorNombre': nombreReferidor,
                                                  'referidoId': doc.id,
                                                  'referidoNombre': referidoNombre,
                                                  'monto': monto,
                                                  'fechaPago': FieldValue.serverTimestamp(),
                                                  'adminNombre': adminNombre,
                                                });

                                                // 🔹 3. Mostrar confirmación
                                                if(context.mounted){
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Comisión de $monto pagada y registrada correctamente.'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              }
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
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
