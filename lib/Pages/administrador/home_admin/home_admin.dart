import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  String? filterStatus = "registrado";
  bool? filterIsPaid;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Color _getColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'registrado':
        return primary;
      case 'revisado':
        return Colors.yellow;
      case 'activado':
        return Colors.green;
      case 'bloqueado':
        return Colors.red;
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
            width: MediaQuery.of(context).size.width >= 1000 ? 1500 : double.infinity,
            padding: const EdgeInsets.all(10),
            child: StreamBuilder<QuerySnapshot>(
              stream: _firebaseFirestore.collection('Ppl').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final docs = snapshot.data!.docs;

                  final int countSuscritos = docs.where((doc) => doc.get('isPaid') == true).length;
                  final int countNoSuscritos = docs.where((doc) => doc.get('isPaid') == false).length;
                  final int countRegistrado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'registrado').length;
                  final int countActivado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'activado').length;
                  final int countBloqueado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'bloqueado').length;
                  final int countTotal = docs.length;

                  // 🔹 Aplicar filtros desde el inicio
                  List<QueryDocumentSnapshot> filteredDocs = docs;

                  // 🔹 Aplicar filtros normales (status, pago y búsqueda)
                  if (filterStatus != null) {
                    filteredDocs = filteredDocs.where((doc) => doc.get('status').toString().toLowerCase() == filterStatus!.toLowerCase()).toList();
                  }
                  if (filterIsPaid != null) {
                    filteredDocs = filteredDocs.where((doc) => doc.get('isPaid') == filterIsPaid).toList();
                  }
                  if (searchQuery.trim().isNotEmpty) {
                    final query = searchQuery.toLowerCase();
                    filteredDocs = filteredDocs.where((doc) {
                      final nombre = doc.get('nombre_ppl').toString().toLowerCase();
                      final apellido = doc.get('apellido_ppl').toString().toLowerCase();
                      final identificacion = doc.get('numero_documento_ppl').toString().toLowerCase();
                      final acudiente = ("${doc.get('nombre_acudiente')} ${doc.get('apellido_acudiente')}").toLowerCase();
                      final celularAcudiente = doc.get('celular').toString().toLowerCase();
                      return nombre.contains(query) || apellido.contains(query) || identificacion.contains(query) || acudiente.contains(query) || celularAcudiente.contains(query);
                    }).toList();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildStatCard("Registrados", countRegistrado, primary, () {
                            setState(() {
                              filterStatus = "registrado";
                              filterIsPaid = null;
                            });
                          }, isSelected: filterStatus == "registrado"),

                          _buildStatCard("Usuarios Activados", countActivado, Colors.green, () {
                            setState(() {
                              filterStatus = "activado";
                              filterIsPaid = null;
                            });
                          }, isSelected: filterStatus == "activado"),

                          _buildStatCard("Suscritos", countSuscritos, Colors.blueAccent, () {
                            setState(() {
                              filterIsPaid = true;
                              filterStatus = null;
                            });
                          }, isSelected: filterIsPaid == true),

                          _buildStatCard("Sin Suscribir", countNoSuscritos, Colors.grey, () {
                            setState(() {
                              filterIsPaid = false;
                              filterStatus = null;
                            });
                          }, isSelected: filterIsPaid == false),

                          _buildStatCard("Bloqueados", countBloqueado, Colors.red, () {
                            setState(() {
                              filterStatus = "bloqueado";
                              filterIsPaid = null;
                            });
                          }, isSelected: filterStatus == "bloqueado"),

                          _buildStatCard("Total Usuarios", countTotal, Colors.amber, () {
                            setState(() {
                              filterStatus = null;
                              filterIsPaid = null;
                            });
                          }, isSelected: filterStatus == null && filterIsPaid == null),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSearchField(),
                      const SizedBox(height: 20),
                      const Divider(height: 2, color: Colors.grey),
                      const SizedBox(height: 10),

                      if (filteredDocs.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No hay documentos disponibles.",
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        _buildUserTable(filteredDocs),
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


  // Widget para construir tarjetas de estadísticas con efecto de selección
  Widget _buildStatCard(String title, int count, Color color, VoidCallback onTap, {bool isSelected = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3) // 🔹 Borde blanco si está seleccionada
              : null,
          boxShadow: isSelected
              ? [ // 🔹 Sombra más fuerte si está seleccionada
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
              : [ // 🔹 Sombra normal si NO está seleccionada
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, height: 1.1),
              textAlign: TextAlign.center,
            ),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSearchField() {
    return TextField(
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUserTable(List<QueryDocumentSnapshot> docs) {
    // 🔹 Obtener el UID del operador actual
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    // 🔥 Filtrar los documentos "registrados" para que solo se muestren los asignados al operador actual o los que no han sido asignados
    if (filterStatus == "registrado") {
      docs = docs.where((doc) {
        final assignedTo = doc.get('assignedTo') ?? ""; // Obtener el campo 'assignedTo'
        return assignedTo.isEmpty || assignedTo == currentUserUid;
      }).toList();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Apellido')),
          DataColumn(label: Text('Identificación')),
          DataColumn(label: Text('Acudiente')),
          DataColumn(label: Text('Celular Acudiente')),
          DataColumn(label: Text('Pago')),
        ],
        rows: docs.map((doc) {
          return DataRow(
            onSelectChanged: (bool? selected) async {
              if (selected != null && selected) {
                String docId = doc.id;

                // 🔹 Asignar el documento al operador actual
                await _firebaseFirestore.collection('Ppl').doc(docId).update({
                  'assignedTo': currentUserUid, // Guarda el UID del operador que tomó el documento
                });

                if(context.mounted){
                  Navigator.pushNamed(
                    context,
                    'editar_registro_admin',
                    arguments: doc,
                  );
                }
              }
            },
            cells: [
              DataCell(Icon(Icons.circle, color: _getColor(doc.get('status')))),
              DataCell(Text(doc.get('nombre_ppl'))),
              DataCell(Text(doc.get('apellido_ppl'))),
              DataCell(Text(doc.get('numero_documento_ppl').toString())),
              DataCell(Text("${doc.get('nombre_acudiente')} ${doc.get('apellido_acudiente')}")),
              DataCell(Text(doc.get('celular').toString())),
              DataCell(Icon(doc.get('isPaid') ? Icons.check_circle : Icons.cancel, color: doc.get('isPaid') ? Colors.blue : Colors.grey)),
            ],
          );
        }).toList(),
      ),
    );
  }

}
