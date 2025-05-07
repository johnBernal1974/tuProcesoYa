import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/Pages/administrador/referidores/ver_referidos.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class AdminReferidoresPage extends StatefulWidget {
  const AdminReferidoresPage({Key? key}) : super(key: key);

  @override
  State<AdminReferidoresPage> createState() => _AdminReferidoresPageState();
}

class _AdminReferidoresPageState extends State<AdminReferidoresPage> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Referidores',
      content: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          return Container(
            width: isDesktop ? 1000 : double.infinity,
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.topCenter,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('referidores').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay referidores registrados."));
                }

                final referidores = snapshot.data!.docs;

                if (isDesktop) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nombre')),
                        DataColumn(label: Text('Código')),
                        DataColumn(label: Text('Celular')),
                        DataColumn(label: Text('Ciudad')),
                        DataColumn(label: Text('Identificación')),
                        DataColumn(label: Text('Total Referidos')),
                      ],
                      rows: referidores.map((ref) {
                        final data = ref.data() as Map<String, dynamic>;
                        final nombre = data['nombre'] ?? '';

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(nombre),
                              onTap: () => _mostrarReferidos(ref.id, nombre),
                            ),
                            DataCell(
                              Text(data['codigo'] ?? ''),
                              onTap: () => _mostrarReferidos(ref.id, nombre),
                            ),
                            DataCell(
                              Text(data['celular'] ?? ''),
                              onTap: () => _mostrarReferidos(ref.id, nombre),
                            ),
                            DataCell(
                              Text(data['ciudad'] ?? ''),
                              onTap: () => _mostrarReferidos(ref.id, nombre),
                            ),
                            DataCell(
                              Text(data['identificacion'] ?? ''),
                              onTap: () => _mostrarReferidos(ref.id, nombre),
                            ),
                            DataCell(
                              Text('${data['totalReferidos'] ?? 0}'),
                              onTap: () => _mostrarReferidos(ref.id, nombre),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  return Center(
                    child: ListView.builder(
                      itemCount: referidores.length,
                      itemBuilder: (context, index) {
                        final ref = referidores[index];
                        final data = ref.data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () => _mostrarReferidos(ref.id, data['nombre']),
                          child: Card(
                            surfaceTintColor: blanco,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nombre: ${data['nombre']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text('Código: ${data['codigo']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text('Celular: ${data['celular']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text('Ciudad: ${data['ciudad']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text('Identificación: ${data['identificacion']}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                  Text('Total referidos: ${data['totalReferidos'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  void _mostrarReferidos(String referidorId, String nombreReferidor) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminReferidosPorReferidorPage(
          referidorId: referidorId,
          nombreReferidor: nombreReferidor,
        ),
      ),
    );
  }
}
