import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';

import '../../../src/colors/colors.dart';

class HomeAdministradorPage extends StatefulWidget {
  const HomeAdministradorPage({super.key});

  @override
  State<HomeAdministradorPage> createState() => _HomeAdministradorPageState();
}

class _HomeAdministradorPageState extends State<HomeAdministradorPage> {
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  // Variables para filtrar
  String? filterStatus; // Si es null, no se filtra por status
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Color _getColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'registrado':
        return Colors.red;
      case 'revisado':
        return Colors.yellow;
      case 'activado':
        return Colors.green;
      case 'servicio_solicitado':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Panel de administración',
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            padding: const EdgeInsets.all(10),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseFirestore.collection('Ppl').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;
                  // Recuentos generales
                  final int countRegistrado = docs
                      .where((doc) => doc.get('status').toString().toLowerCase() == 'registrado')
                      .length;
                  final int countActivado = docs
                      .where((doc) => doc.get('status').toString().toLowerCase() == 'activado')
                      .length;
                  final int countPendiente = docs
                      .where((doc) => doc.get('status').toString().toLowerCase() == 'servicio_solicitado')
                      .length;
                  final int countTotal = countRegistrado + countActivado + countPendiente;

                  // Filtrado por filterStatus
                  List<QueryDocumentSnapshot> filteredDocs = docs;
                  if (filterStatus != null) {
                    filteredDocs = filteredDocs
                        .where((doc) =>
                    doc.get('status').toString().toLowerCase() ==
                        filterStatus!.toLowerCase())
                        .toList();
                  }
                  // Filtrado por searchQuery (por los campos solicitados)
                  if (searchQuery.trim().isNotEmpty) {
                    final query = searchQuery.toLowerCase();
                    filteredDocs = filteredDocs.where((doc) {
                      final nombre = doc.get('nombre_ppl').toString().toLowerCase();
                      final apellido = doc.get('apellido_ppl').toString().toLowerCase();
                      final identificacion = doc.get('numero_documento_ppl').toString().toLowerCase();
                      final acudiente = ("${doc.get('nombre_acudiente')} ${doc.get('apellido_acudiente')}")
                          .toLowerCase();
                      final celularAcudiente = doc.get('celular').toString().toLowerCase();
                      return nombre.contains(query) ||
                          apellido.contains(query) ||
                          identificacion.contains(query) ||
                          acudiente.contains(query) ||
                          celularAcudiente.contains(query);
                    }).toList();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Cajones en un Wrap
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          // Cajón "Usuarios Registrados"
                          InkWell(
                            onTap: () {
                              setState(() {
                                filterStatus = "registrado";
                              });
                            },
                            child: Container(
                              width: 130,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Usuarios\nRegistrados",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,color: blanco, height: 1.1),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    countRegistrado.toString(),
                                    style: const TextStyle(fontSize: 16, color: blanco),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Cajón "Usuarios Activados"
                          InkWell(
                            onTap: () {
                              setState(() {
                                filterStatus = "activado";
                              });
                            },
                            child: Container(
                              width: 130,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Usuarios\nActivados",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.1, color: blanco),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    countActivado.toString(),
                                    style: const TextStyle(fontSize: 16, color: blanco),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Cajón "Total Usuarios" (sin filtro)
                          InkWell(
                            onTap: () {
                              setState(() {
                                filterStatus = null;
                              });
                            },
                            child: Container(
                              width: 130,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    "Total\nUsuarios",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.1),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    countTotal.toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Campo de búsqueda
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Buscar registros",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = "";
                              });
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 2, color: Colors.grey),
                      const SizedBox(height: 10),
                      // Tabla de usuarios filtrada
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTableTheme(
                            data: const DataTableThemeData(
                              dividerThickness: 1,
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.black54,
                              ),
                              child: DataTable(
                                showCheckboxColumn: false,
                                horizontalMargin: 0,
                                columnSpacing: 25,
                                dataRowMinHeight: 30,
                                headingRowHeight: 30,
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Estado',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Nombre',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Apellido',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Identificación',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Acudiente',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Celular Acudiente',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                                rows: filteredDocs.map((doc) {
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
                                      DataCell(
                                        Text(
                                          '${doc.get('nombre_ppl')}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${doc.get('apellido_ppl')}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          doc.get('numero_documento_ppl').toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${doc.get('nombre_acudiente')} ${doc.get('apellido_acudiente')}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          doc.get('celular').toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                    onSelectChanged: (bool? selected) {
                                      if (selected != null && selected) {
                                        Navigator.pushNamed(
                                          context,
                                          'editar_registro_admin',
                                          arguments: doc,
                                        );
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (filteredDocs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              filterStatus == null
                                  ? "No hay usuarios"
                                  : filterStatus!.toLowerCase() == "registrado"
                                  ? "No hay Nuevos registros"
                                  : filterStatus!.toLowerCase() == "activado"
                                  ? "No hay usuarios activados"
                                  : filterStatus!.toLowerCase() == "servicio_solicitado"
                                  ? "No hay solicitudes pendientes"
                                  : "No hay registros",
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
