import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../commons/main_layaout.dart';

class HomeAdministradorPage extends StatefulWidget {
  const HomeAdministradorPage({super.key});

  @override
  State<HomeAdministradorPage> createState() => _HomeAdministradorPageState();
}

class _HomeAdministradorPageState extends State<HomeAdministradorPage> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Panel de administración',
      content: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [

              const Text('Personal PPL registrado'),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: _firebaseFirestore.collection('Ppl').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Align(
                      alignment: Alignment.centerLeft, // Alinea la tabla a la izquierda
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          showCheckboxColumn: false,
                          horizontalMargin: 0, // Reduce el margen horizontal
                          columnSpacing: 25, // Aumenta el espacio entre columnas
                          dataRowMinHeight : 30, // Ajusta la altura de cada fila
                          headingRowHeight: 30, // Ajusta la altura de la fila de títulos
                          columns: const [
                            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold),)),
                            DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold),)),
                            DataColumn(label: Text('Apellido', style: TextStyle(fontWeight: FontWeight.bold),)),
                            DataColumn(label: Text('Identificación', style: TextStyle(fontWeight: FontWeight.bold),)),
                          ],
                          rows: snapshot.data!.docs.map((doc) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Center(
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getColor(doc.get('status')),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text('${doc.get('nombre_ppl')}')),
                                DataCell(Text('${doc.get('apellido_ppl')}')),
                                DataCell(Text(doc.get('numero_documento_ppl').toString())),
                              ],
                              onSelectChanged: (bool? selected) {
                                if (selected != null && selected) {
                                  Navigator.pushNamed(
                                    context,
                                    'editar_registro_admin',
                                    arguments: doc, // Aquí pasas el documento seleccionado
                                  );
                                }
                              },
                            );

                          }).toList(),
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColor(String estado) {
    switch (estado) {
      case 'registrado':
        return Colors.red;
      case 'revisado':
        return Colors.yellow;
      case 'activado':
        return Colors.green;
      case 'servicio_solicitado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}