import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../commons/main_layaout.dart';

class HistorialPagosComisionesPage extends StatefulWidget {
  const HistorialPagosComisionesPage({Key? key}) : super(key: key);

  @override
  State<HistorialPagosComisionesPage> createState() => _HistorialPagosComisionesPageState();
}

class _HistorialPagosComisionesPageState extends State<HistorialPagosComisionesPage> {
  String filtroReferidor = '';

  String _formatearFecha(Timestamp timestamp) {
    final fecha = timestamp.toDate();
    return DateFormat('d/MM/yyyy hh:mm a', 'es').format(fecha);
  }

  String _claveSemana(DateTime fecha) {
    final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
    final finSemana = inicioSemana.add(const Duration(days: 6));
    return 'Semana del ${DateFormat('d MMM', 'es').format(inicioSemana)} al ${DateFormat('d MMM', 'es').format(finSemana)}';
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial de Pagos de Comisiones',
      content: Container(
        width: MediaQuery.of(context).size.width >= 1000 ? 1200 : double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Filtros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Referidor',
                      labelStyle: const TextStyle(color: Colors.black87),
                      isDense: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade600, width: 1.5),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filtroReferidor = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📋 Tabla de historial
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pagos_comisiones')
                    .orderBy('fechaPago', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text("No hay pagos registrados.");
                  }

                  var pagos = snapshot.data!.docs;

                  // Filtro por nombre de referidor
                  if (filtroReferidor.isNotEmpty) {
                    pagos = pagos.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombreReferidor = (data['referidorNombre'] ?? '').toString().toLowerCase();
                      return nombreReferidor.contains(filtroReferidor);
                    }).toList();
                  }

                  // Calcular total general
                  final totalPagos = pagos.fold<int>(
                    0,
                        (sum, doc) => sum + ((doc['monto'] ?? 0) as int),
                  );

                  // Agrupar por semana
                  final Map<String, int> totalesPorSemana = {};
                  for (var doc in pagos) {
                    final data = doc.data() as Map<String, dynamic>;
                    final fechaPago = (data['fechaPago'] as Timestamp).toDate();
                    final claveSemana = _claveSemana(fechaPago);
                    final monto = (data['monto'] ?? 0) as int;
                    totalesPorSemana[claveSemana] = (totalesPorSemana[claveSemana] ?? 0) + monto;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Tarjeta Total General
                      Card(
                        color: Colors.green.shade50,
                        child: ListTile(
                          title: const Text('Total de Pagos Realizados', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('\$${NumberFormat("#,##0", "es").format(totalPagos)}'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 🔹 Totales por semana
                      ...totalesPorSemana.entries.map((entry) {
                        return Card(
                          color: Colors.blue.shade50,
                          child: ListTile(
                            title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Total pagado: \$${NumberFormat("#,##0", "es").format(entry.value)}'),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // 🔹 Tabla de detalle
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Fecha Pago', style: TextStyle(fontSize: 12))),
                              DataColumn(label: Text('Referidor', style: TextStyle(fontSize: 12))),
                              DataColumn(label: Text('Referido', style: TextStyle(fontSize: 12))),
                              DataColumn(label: Text('Monto', style: TextStyle(fontSize: 12))),
                              DataColumn(label: Text('Pagado por', style: TextStyle(fontSize: 12))),
                            ],
                            rows: pagos.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DataRow(
                                cells: [
                                  DataCell(Text(_formatearFecha(data['fechaPago']), style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(data['referidorNombre'] ?? 'N/A', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(data['referidoNombre'] ?? 'N/A', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text('\$${NumberFormat("#,##0", "es").format(data['monto'] ?? 0)}', style: const TextStyle(fontSize: 12))),
                                  DataCell(Text(data['adminNombre'] ?? 'N/A', style: const TextStyle(fontSize: 12))),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
