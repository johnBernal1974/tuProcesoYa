import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
            child: FutureBuilder<DocumentSnapshot>(
              future: _firebaseFirestore.collection('admin').doc(FirebaseAuth.instance.currentUser?.uid ?? "").get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // 🔥 Obtener el rol del usuario actual
                String userRole = snapshot.data!.exists && snapshot.data!.data() != null
                    ? snapshot.data!.get('rol').toString().toLowerCase()
                    : "";
                List<String> rolesOperadores = ["operador 1", "operador 2", "operador 3"];
                bool esOperador = rolesOperadores.contains(userRole);
                String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                return StreamBuilder<QuerySnapshot>(
                  stream: _firebaseFirestore.collection('Ppl').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final docs = snapshot.data!.docs;

                      final int countRegistrado = docs.where((doc) {
                        final assignedTo = doc.get('assignedTo') ?? "";
                        final status = doc.get('status').toString().toLowerCase();

                        if (status == 'registrado') {
                          return esOperador ? (assignedTo.isEmpty || assignedTo == currentUserUid) : true;
                        }
                        return false;
                      }).length;

                      final int countActivado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'activado').length;
                      final int countBloqueado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'bloqueado').length;
                      final int countTotal = docs.where((doc) {
                        final status = doc.get('status').toString().toLowerCase();
                        if (esOperador) {
                          final assignedTo = doc.get('assignedTo') ?? "";
                          if (status == 'registrado') {
                            return assignedTo.isEmpty || assignedTo == currentUserUid;
                          }
                        }
                        return true; // Si no es operador, cuenta TODOS los documentos sin filtrar
                      }).length;

                      // 🔹 Aplicar filtros
                      List<QueryDocumentSnapshot> filteredDocs = docs;

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
                );
              },
            ),
          ),
        ),
      ),
    );
  }


  /// 📆 Función para manejar errores en la conversión de fechas
  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "Fecha no disponible";
    return DateFormat(formato, 'es').format(fecha);
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
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return FutureBuilder<String>(
      future: _obtenerRolActual(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator()); // Muestra un loader mientras se obtiene el rol
        }

        String userRole = snapshot.data!;
        List<String> rolesConFiltro = ["operador 1", "operador 2", "operador 3"];

        // 🔥 Aplicar filtros solo si el usuario es operador 1, 2 o 3
        if (rolesConFiltro.contains(userRole)) {
          docs = docs.where((doc) {
            final assignedTo = doc.get('assignedTo') ?? "";
            if (doc.get('status').toString().toLowerCase() == 'registrado') {
              return assignedTo.isEmpty || assignedTo == currentUserUid;
            }
            return true;
          }).toList();
        }

        // 🔹 Ordenar los documentos por fechaRegistro de más reciente a más antiguo
        docs.sort((a, b) {
          DateTime? fechaA = _convertirTimestampADateTime(a.get('fechaRegistro'));
          DateTime? fechaB = _convertirTimestampADateTime(b.get('fechaRegistro'));
          return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
        });

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
              DataColumn(label: Text('Celular')),
              DataColumn(label: Text('Pago')),
              DataColumn(label: Text('Registro')),
            ],
            rows: docs.map((doc) {
              final String assignedTo = doc.get('assignedTo') ?? "";
              final bool isAssigned = assignedTo.isNotEmpty;

              return DataRow(
                onSelectChanged: (bool? selected) async {
                  if (selected != null && selected) {
                    String docId = doc.id;

                    if (!isAssigned) {
                      bool confirmarAsignacion = await _mostrarDialogoConfirmacion();
                      if (!confirmarAsignacion) return;

                      await _firebaseFirestore.collection('Ppl').doc(docId).update({
                        'assignedTo': currentUserUid,
                      });
                    }

                    if (context.mounted) {
                      Navigator.pushNamed(
                        context,
                        'editar_registro_admin',
                        arguments: doc,
                      );
                    }
                  }
                },
                cells: [
                  DataCell(
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(Icons.circle, color: _getColor(doc.get('status'))),
                        ),
                        const SizedBox(width: 8), // Espaciado entre el círculo y la etiqueta

                        if (doc.get('status').toString().toLowerCase() == "registrado") ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAssigned ? primary : Colors.red, // Verde si está asignado, rojo si no
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAssigned ? "Asignado" : "No asignado", // Texto según estado
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  DataCell(Text(doc.get('nombre_ppl'), style: const TextStyle(fontSize: 14))),
                  DataCell(Text(doc.get('apellido_ppl'), style: const TextStyle(fontSize: 14))),
                  DataCell(Text(doc.get('numero_documento_ppl').toString(), style: const TextStyle(fontSize: 14))),
                  DataCell(Text("${doc.get('nombre_acudiente')}\n${doc.get('apellido_acudiente')}", style: const TextStyle(fontSize: 14))),
                  DataCell(Text(doc.get('celular').toString(), style: const TextStyle(fontSize: 14))),
                  DataCell(Icon(
                    doc.get('isPaid') ? Icons.check_circle : Icons.cancel,
                    color: doc.get('isPaid') ? Colors.blue : Colors.grey,
                  )),
                  DataCell(Text(
                    _formatFecha(_convertirTimestampADateTime(doc.get('fechaRegistro'))),
                    style: const TextStyle(fontSize: 12),
                  )),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<bool> _mostrarDialogoConfirmacion() async {
    return await showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: blancoCards,
          title: const Text("Confirmar Asignación"),
          content: const Text("Este usuario te será asignado. ¿Desea continuar?"),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(false), // Cierra sin asignar
            ),
            ElevatedButton(
              child: const Text("Asignar"),
              onPressed: () => Navigator.of(context).pop(true), // Confirma asignación
            ),
          ],
        );
      },
    ) ?? false; // En caso de error, devuelve `false` por defecto
  }

  DateTime? _convertirTimestampADateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate(); // Si es Timestamp de Firestore
    if (timestamp is String) return DateTime.tryParse(timestamp); // Si es String ISO 8601
    return null; // Si no es válido
  }
  Future<String> _obtenerRolActual() async {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (currentUserUid.isEmpty) return ""; // Si no hay usuario autenticado, devolver vacío

    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admin').doc(currentUserUid).get();
      if (adminDoc.exists) {
        return adminDoc.get('rol')?.toLowerCase() ?? "";
      }
    } catch (e) {
      print("Error obteniendo el rol: $e");
    }

    return ""; // Si hay un error, devolver vacío
  }


}
