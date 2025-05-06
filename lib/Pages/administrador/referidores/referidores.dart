import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';

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
      content: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

              return GridView.builder(
                itemCount: referidores.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // ajusta según el tamaño de pantalla
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final ref = referidores[index];
                  final data = ref.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () => _mostrarReferidos(ref.id, data['nombre']),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nombre: ${data['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Celular: ${data['celular']}'),
                            Text('Ciudad: ${data['ciudad']}'),
                            Text('Código: ${data['codigo']}'),
                            Text('Identificación: ${data['identificacion']}'),
                            Text('Total referidos: ${data['totalReferidos'] ?? 0}'),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarReferidos(String referidorId, String nombreReferidor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Referidos de $nombreReferidor'),
          content: SizedBox(
            width: double.maxFinite,
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

                final referidos = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: referidos.length,
                  itemBuilder: (context, index) {
                    final ref = referidos[index].data() as Map<String, dynamic>;
                    final nombre = ref['nombre'] ?? '';
                    final apellido = ref['apellido'] ?? '';
                    final fecha = (ref['fechaRegistro'] as Timestamp?)?.toDate();
                    final fechaFormateada = fecha != null
                        ? DateFormat('d \'de\' MMMM \'de\' y, hh:mm a', 'es').format(fecha)
                        : 'Sin fecha';

                    return ListTile(
                      title: Text('$nombre $apellido'),
                      subtitle: Text('Registrado: $fechaFormateada'),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }
}
