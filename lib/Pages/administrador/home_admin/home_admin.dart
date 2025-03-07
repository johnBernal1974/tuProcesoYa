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

  // para barra de busqueda de operadoresa asignados
  bool mostrarFiltroAdmin = false; // Indica si se muestra el campo de búsqueda de admin
  String searchAdminQuery = ""; // Almacena el texto ingresado en el filtro de admin
  TextEditingController _adminSearchController = TextEditingController(); // Controlador para la búsqueda por admin
  Map<String, String> adminNamesMap = {}; // 🔥 Mapa de ID de admin -> Nombre de admin
  bool isLoadingAdmins = true; // 🔥 Control de carga


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

  void _activarFiltroAdmin() async {
    if (!mostrarFiltroAdmin) { // Solo cargar si se está activando el filtro
      if (adminNamesMap.isEmpty) {
        setState(() {
          isLoadingAdmins = true; // 🔥 Mostrar indicador de carga
        });

        await _fetchAdminNames(); // 🔥 Cargar admins desde Firestore

        setState(() {
          isLoadingAdmins = false; // 🔥 Indicar que ya cargaron
        });
      }
    }

    setState(() {
      mostrarFiltroAdmin = !mostrarFiltroAdmin; // 🔥 Alternar visibilidad del filtro
      filterStatus = null; // 🔥 Establecer filtro en "Total Usuarios"
    });
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

                String userRole = snapshot.data!.exists && snapshot.data!.data() != null
                    ? snapshot.data!.get('rol').toString().toLowerCase()
                    : "";
                List<String> rolesOperadores = ["operador 1", "operador 2", "operador 3"];
                bool esOperador = rolesOperadores.contains(userRole);
                String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                return StreamBuilder<QuerySnapshot>(
                  stream: _firebaseFirestore.collection('Ppl').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    final int countRegistrado = docs.where((doc) {
                      final assignedTo = doc.get('assignedTo') ?? "";
                      final status = doc.get('status').toString().toLowerCase();
                      return status == 'registrado' && (!esOperador || assignedTo.isEmpty || assignedTo == currentUserUid);
                    }).length;

                    final int countActivado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'activado').length;
                    final int countBloqueado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'bloqueado').length;

                    final int countTotal = docs.where((doc) {
                      final assignedTo = doc.get('assignedTo') ?? "";
                      final status = doc.get('status').toString().toLowerCase();

                      if (esOperador) {
                        return (status == 'registrado' && (assignedTo.isEmpty || assignedTo == currentUserUid)) ||
                            status == 'activado' || status == 'bloqueado';
                      }
                      return true;
                    }).length;

                    List<QueryDocumentSnapshot> filteredDocs = docs;

                    if (filterStatus != null) {
                      filteredDocs = filteredDocs.where((doc) {
                        final status = doc.get('status').toString().toLowerCase();
                        final assignedTo = doc.get('assignedTo') ?? "";

                        if (esOperador && filterStatus == "registrado") {
                          return status == filterStatus!.toLowerCase() && (assignedTo.isEmpty || assignedTo == currentUserUid);
                        }
                        return status == filterStatus!.toLowerCase();
                      }).toList();
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

                    if (searchAdminQuery.trim().isNotEmpty && !isLoadingAdmins) {
                      filteredDocs = filteredDocs.where((doc) {
                        final assignedAdminId = doc.get('assignedTo')?.toString() ?? "";
                        final assignedAdminName = adminNamesMap[assignedAdminId]?.toLowerCase() ?? "";
                        return assignedAdminName.contains(searchAdminQuery);
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

                        // 🔥 Mostrar mensaje si no hay documentos después del filtro
                        filteredDocs.isEmpty
                            ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "No hay ${filterStatus == 'registrado' ? 'nuevos usuarios registrados' : filterStatus == 'activado' ? 'usuarios activados' : filterStatus == 'bloqueado' ? 'usuarios bloqueados' : 'documentos'} disponibles.",
                              style: const TextStyle(fontSize: 28, color: Colors.grey),
                            ),

                          ),
                        )
                            : _buildUserTable(filteredDocs),
                      ],
                    );

                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchAdminNames() async {
    if (adminNamesMap.isNotEmpty) return; // 🔥 Evita recargar si ya están en memoria

    setState(() => isLoadingAdmins = true);

    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance.collection('admin').get();
      Map<String, String> fetchedAdminNames = {};

      for (var doc in adminSnapshot.docs) {
        fetchedAdminNames[doc.id] = "${doc.get('name')} ${doc.get('apellidos')}";
      }

      setState(() {
        adminNamesMap = fetchedAdminNames;
        isLoadingAdmins = false;
      });

      debugPrint("✅ Admins cargados: ${adminNamesMap.length}");
    } catch (e) {
      debugPrint("❌ Error al cargar los admins: $e");
      setState(() => isLoadingAdmins = false);
    }
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


  // Barra de busqueda por rol
  Widget _buildSearchField() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firebaseFirestore.collection('admin').doc(FirebaseAuth.instance.currentUser?.uid ?? "").get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(); // Mientras carga, no muestra nada

        // 🔹 Obtener el rol del usuario autenticado
        String userRole = snapshot.data!.exists && snapshot.data!.data() != null
            ? snapshot.data!.get('rol').toString().toLowerCase()
            : "";
        List<String> rolesOperadores = ["operador 1", "operador 2", "operador 3"];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Barra de búsqueda normal (para todos los roles)
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
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
            ),

            const SizedBox(height: 10),

            // 🔥 Si NO es operador, mostrar el botón para buscar por admin asignado
            if (!rolesOperadores.contains(userRole))
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text("Filtrar por Operadores"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _activarFiltroAdmin, // 🔥 Carga admins solo al presionar el botón
                ),
              ),


            // 🔥 Si se activa el filtro de admin, mostrar la nueva barra de búsqueda
            if (!rolesOperadores.contains(userRole) && mostrarFiltroAdmin)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _adminSearchController,
                  onChanged: (value) {
                    setState(() {
                      searchAdminQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Buscar por operador",
                    prefixIcon: const Icon(Icons.person_search),
                    suffixIcon: searchAdminQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _adminSearchController.clear();
                        setState(() {
                          searchAdminQuery = "";
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserTable(List<QueryDocumentSnapshot> docs) {
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return FutureBuilder<String>(
      future: _obtenerRolActual(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator()); // Cargando rol
        }

        String userRole = snapshot.data!;
        List<String> rolesOperadores = ["operador 1", "operador 2", "operador 3"];
        bool esOperador = rolesOperadores.contains(userRole);

        // 🔥 Aplicar filtro SOLO a "registrado"
        if (esOperador) {
          docs = docs.where((doc) {
            final assignedTo = doc.get('assignedTo') ?? "";
            final status = doc.get('status').toString().toLowerCase();

            if (status == "registrado") {
              return assignedTo.isEmpty || assignedTo == currentUserUid;
            }
            return true; // Dejar pasar todos los activados y bloqueados sin filtrar `assignedTo`
          }).toList();
        }

        // 🔹 Ordenar documentos por fecha (de más reciente a más antiguo)
        docs.sort((a, b) {
          DateTime? fechaA = _convertirTimestampADateTime(a.get('fechaRegistro'));
          DateTime? fechaB = _convertirTimestampADateTime(b.get('fechaRegistro'));
          return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
        });

        // 🔥 Agrupar registros por semana
        Map<String, List<QueryDocumentSnapshot>> registrosPorSemana = {};
        for (var doc in docs) {
          DateTime? fechaRegistro = _convertirTimestampADateTime(doc.get('fechaRegistro'));
          if (fechaRegistro != null) {
            String semanaClave = _obtenerRangoSemana(fechaRegistro);
            registrosPorSemana.putIfAbsent(semanaClave, () => []).add(doc);
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: registrosPorSemana.entries.map((entry) {
              String semanaTexto = entry.key;
              List<QueryDocumentSnapshot> registros = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Encabezado con la semana
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      semanaTexto,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),

                  // 🔹 Divider para separar semanas
                  const Divider(color: Colors.grey, thickness: 1),

                  // 🔹 Tabla de registros de la semana
                  SingleChildScrollView(
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
                      rows: registros.map((doc) {
                        final String assignedTo = doc.get('assignedTo') ?? "";
                        final bool isAssigned = assignedTo.isNotEmpty;
                        final String status = doc.get('status').toString().toLowerCase();

                        return DataRow(
                          onSelectChanged: (bool? selected) async {
                            if (selected != null && selected) {
                              final String assignedTo = doc.get('assignedTo') ?? "";

                              if (assignedTo.isEmpty) {
                                // 🔹 Si el documento NO está asignado, pedir confirmación
                                bool confirmar = await _mostrarDialogoConfirmacion();
                                if (!confirmar) {
                                  print("🚫 Edición cancelada por el usuario.");
                                  return; // Si no confirma, no hace nada
                                }
                              }

                              // 🔹 Si ya estaba asignado, o si confirmó, navegar a la pantalla de edición
                              String docId = doc.id;
                              Navigator.pushNamed(context, 'editar_registro_admin', arguments: doc);
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
                                    child: Icon(Icons.circle, color: _getColor(status)),
                                  ),
                                  const SizedBox(width: 8), // Espaciado entre el círculo y la etiqueta

                                  // 🔹 Mostrar rectángulo solo si el estado es "registrado"
                                  if (status == "registrado") ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAssigned ? primary : Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isAssigned ? "Asignado" : "No asignado",
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
                            DataCell(Text(doc.get('nombre_ppl'))),
                            DataCell(Text(doc.get('apellido_ppl'))),
                            DataCell(Text(doc.get('numero_documento_ppl').toString())),
                            DataCell(Text("${doc.get('nombre_acudiente')} ${doc.get('apellido_acudiente')}")),
                            DataCell(Text(doc.get('celular').toString())),
                            DataCell(Icon(
                              doc.get('isPaid') ? Icons.check_circle : Icons.cancel,
                              color: doc.get('isPaid') ? Colors.blue : Colors.grey,
                            )),
                            DataCell(Text(_formatFecha(_convertirTimestampADateTime(doc.get('fechaRegistro'))))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  // 🔹 Divider entre semanas
                  const Divider(height: 30, thickness: 2, color: Colors.grey),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }


  String _obtenerRangoSemana(DateTime fecha) {
    DateTime inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1)); // Lunes de esa semana
    DateTime finSemana = inicioSemana.add(const Duration(days: 6)); // Domingo de esa semana

    return "Semana del ${DateFormat('dd MMM').format(inicioSemana)} al ${DateFormat('dd MMM \'del\' yyyy').format(finSemana)}";
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
