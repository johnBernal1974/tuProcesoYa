import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import 'dart:html' as html;


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
  int? _tiempoDePruebaDias;
  final TextEditingController _searchController = TextEditingController();

  // para barra de busqueda de operadoresa asignados
  bool mostrarFiltroAdmin = false; // Indica si se muestra el campo de búsqueda de admin
  String searchAdminQuery = ""; // Almacena el texto ingresado en el filtro de admin
  TextEditingController _adminSearchController = TextEditingController(); // Controlador para la búsqueda por admin
  Map<String, String> adminNamesMap = {}; // 🔥 Mapa de ID de admin -> Nombre de admin
  bool isLoadingAdmins = true; //
  bool mostrarSoloIncompletos = false;
  bool mostrarRedencionesVencidas = false;
  String? _versionActual;
  String? _nuevaVersion;
  bool _mostrarBanner = false;


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
  void initState() {
    super.initState();
    _cargarTiempoDePrueba();
    _verificarVersion();
  }

  Future<void> _verificarVersion() async {
    try {
      // 🔍 Obtener UID del usuario autenticado
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 📥 Obtener versión remota desde Firestore
      final configDoc = await FirebaseFirestore.instance
          .collection('configuraciones')
          .doc('h7NXeT2STxoHVv049o3J')
          .get();
      final versionRemota = configDoc.data()?['version_app'];

      // 📥 Obtener versión guardada en el documento del Admin
      final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();
      final versionLocal = adminDoc.data()?['version'] ?? '0.0.0';

      print('🔍 Versión PPL: $versionLocal | Versión disponible: $versionRemota');

      _versionActual = versionLocal;
      _nuevaVersion = versionRemota;

      if (_nuevaVersion != null && _nuevaVersion != _versionActual) {
        setState(() {
          _mostrarBanner = true;
        });
      }
    } catch (e) {
      print('❌ Error al verificar versión: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Panel de administración',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? double.infinity : double.infinity,
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

                    final int countActivado = docs.where((doc) {
                      final status = doc.get('status').toString().toLowerCase();
                      final data = doc.data() as Map<String, dynamic>;
                      final requiereActualizacion = data['requiere_actualizacion_datos'] ?? false;
                      return status == 'activado' && requiereActualizacion != true;
                    }).length;

                    final int countBloqueado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'bloqueado').length;
                    final int countPendiente = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'pendiente').length;
                    final int countActivadoIncompleto = docs.where((doc) {
                      final status = doc.get('status').toString().toLowerCase();
                      final data = doc.data() as Map<String, dynamic>;
                      return status == 'activado' && (data['requiere_actualizacion_datos'] == true);
                    }).length;

                    final int countTotal = docs.where((doc) {
                      final assignedTo = doc.get('assignedTo') ?? "";
                      final status = doc.get('status').toString().toLowerCase();

                      if (esOperador) {
                        return (status == 'registrado' && (assignedTo.isEmpty || assignedTo == currentUserUid)) ||
                            status == 'activado' || status == 'bloqueado';
                      }
                      return true;
                    }).length;

                    final int countRedencionesVencidas = docs.where((doc) {
                      final status = doc.get('status').toString().toLowerCase();
                      final data = doc.data() as Map<String, dynamic>;

                      if (status != 'activado') return false;

                      final ts = data['ultima_actualizacion_redenciones'];
                      if (ts == null || ts is! Timestamp) return false;

                      final diferencia = DateTime.now().difference(ts.toDate()).inDays;
                      return diferencia >= 30;
                    }).length;


                    List<QueryDocumentSnapshot> filteredDocs;

                    if (searchQuery.trim().isNotEmpty) {
                      // 🔍 Búsqueda se hace sobre TODOS los documentos
                      final query = searchQuery.toLowerCase();
                      filteredDocs = docs.where((doc) {
                        final nombre = doc.get('nombre_ppl').toString().toLowerCase();
                        final apellido = doc.get('apellido_ppl').toString().toLowerCase();
                        final identificacion = doc.get('numero_documento_ppl').toString().toLowerCase();
                        final acudiente = ("${doc.get('nombre_acudiente')} ${doc.get('apellido_acudiente')}").toLowerCase();
                        final celularAcudiente = doc.get('celular').toString().toLowerCase();
                        return nombre.contains(query) ||
                            apellido.contains(query) ||
                            identificacion.contains(query) ||
                            acudiente.contains(query) ||
                            celularAcudiente.contains(query);
                      }).toList();
                    } else {
                      // ✅ Si NO se está buscando, aplica filtros normales
                      filteredDocs = docs;

                      if (filterStatus != null) {
                        filteredDocs = filteredDocs.where((doc) {
                          final status = doc.get('status').toString().toLowerCase();
                          final assignedTo = doc.get('assignedTo') ?? "";
                          final data = doc.data() as Map<String, dynamic>;
                          final requiereActualizacion = data['requiere_actualizacion_datos'] ?? false;

                          if (esOperador && filterStatus == "registrado") {
                            return status == filterStatus!.toLowerCase() &&
                                (assignedTo.isEmpty || assignedTo == currentUserUid);
                          }

                          if (filterStatus == "activado") {
                            if (mostrarSoloIncompletos) {
                              return status == "activado" && requiereActualizacion == true;
                            } else {
                              return status == "activado" && requiereActualizacion != true;
                            }
                          }

                          return status == filterStatus!.toLowerCase();
                        }).toList();
                      }

// 2. Filtro por pago (si aplica)
                      if (filterIsPaid != null) {
                        filteredDocs = filteredDocs.where((doc) => doc.get('isPaid') == filterIsPaid).toList();
                      }

// 3. Filtro por búsqueda general
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

// 4. Filtro por búsqueda de administrador (si aplica)
                      if (searchAdminQuery.trim().isNotEmpty && !isLoadingAdmins) {
                        filteredDocs = filteredDocs.where((doc) {
                          final assignedAdminId = doc.get('assignedTo')?.toString() ?? "";
                          final assignedAdminName = adminNamesMap[assignedAdminId]?.toLowerCase() ?? "";
                          return assignedAdminName.contains(searchAdminQuery);
                        }).toList();
                      }

// 5. 🔥 Filtro por redenciones vencidas
                      if (mostrarRedencionesVencidas) {
                        filteredDocs = filteredDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final ts = data['ultima_actualizacion_redenciones'];
                          if (ts == null || ts is! Timestamp) return false;

                          final diferencia = DateTime.now().difference(ts.toDate()).inDays;
                          return diferencia >= 30;
                        }).toList();
                      }

                      if (filterIsPaid != null) {
                        filteredDocs = filteredDocs.where((doc) => doc.get('isPaid') == filterIsPaid).toList();
                      }
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
                      children: [
                        if (_mostrarBanner)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 250,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                border: Border.all(color: Colors.grey), // 🟫 Borde gris
                                borderRadius: BorderRadius.circular(12), // 🔵 Bordes redondeados
                              ),
                              child: MaterialBanner(
                                backgroundColor: Colors.transparent, // 🟡 Para usar el color del Container
                                content: Column(
                                  children: [
                                    Text(
                                      'Versión actual $_versionActual',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      'Nueva versión $_nuevaVersion',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      final uid = FirebaseAuth.instance.currentUser?.uid;
                                      if (uid != null && _nuevaVersion != null) {
                                        final docRef = FirebaseFirestore.instance.collection('admin').doc(uid);

                                        // 🔎 Mostrar versión actual antes de actualizar
                                        final docSnapshot = await docRef.get();
                                        final versionAnterior = docSnapshot.data()?['version'];
                                        print('🕵️ Versión actual del admin antes de actualizar: $versionAnterior');

                                        // ✅ Actualizar con la nueva versión
                                        await docRef.update({'version': _nuevaVersion});
                                        print('✅ Versión del admin actualizada a: $_nuevaVersion');
                                      }

                                      // 🔄 Recargar la app
                                      html.window.location.reload();
                                    },
                                    child: const Text('Actualizar'),
                                  ),
                                ],

                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        // ⬇️ Resto de tu contenido
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 10,
                          runSpacing: 20,
                          children: [
                            _buildStatCard("Registrados", countRegistrado, primary, () {
                              setState(() {
                                filterStatus = "registrado";
                                filterIsPaid = null;
                                mostrarRedencionesVencidas = false;
                                mostrarSoloIncompletos = false;
                              });
                            }, isSelected: filterStatus == "registrado"),

                            _buildStatCard("Usuarios Activados", countActivado, Colors.green, () {
                              setState(() {
                                filterStatus = "activado";
                                filterIsPaid = null;
                                mostrarSoloIncompletos = false;
                                mostrarRedencionesVencidas = false;
                              });
                            }, isSelected: filterStatus == "activado" && mostrarSoloIncompletos == false && !mostrarRedencionesVencidas),

                            _buildStatCard("Activos Incompletos", countActivadoIncompleto, Colors.lightGreen, () {
                              setState(() {
                                filterStatus = "activado";
                                mostrarSoloIncompletos = true;
                                mostrarRedencionesVencidas = false;
                              });
                            }, isSelected: filterStatus == "activado" && mostrarSoloIncompletos == true),

                            _buildStatCard("Pendientes", countPendiente, Colors.orange, () {
                              setState(() {
                                filterStatus = "pendiente";
                                filterIsPaid = null;
                                mostrarRedencionesVencidas = false;
                                mostrarSoloIncompletos = false;
                              });
                            }, isSelected: filterStatus == "pendiente"),

                            _buildStatCard("Bloqueados", countBloqueado, Colors.red, () {
                              setState(() {
                                filterStatus = "bloqueado";
                                filterIsPaid = null;
                                mostrarRedencionesVencidas = false;
                                mostrarSoloIncompletos = false;
                              });
                            }, isSelected: filterStatus == "bloqueado"),

                            _buildStatCard("Redenciones vencidas", countRedencionesVencidas, Colors.blue, () {
                              setState(() {
                                mostrarRedencionesVencidas = true;
                                filterStatus = null;
                                filterIsPaid = null;
                                mostrarSoloIncompletos = false;
                              });
                            }, isSelected: mostrarRedencionesVencidas),

                            _buildStatCard("Total Usuarios", countTotal, Colors.black87, null, isSelected: false),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 800,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gris),
                            color: blanco,
                          ),
                          child: _buildSearchField(),
                        ),
                        const SizedBox(height: 20),
                        filteredDocs.isEmpty
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No hay ${filterStatus == 'registrado' ? 'nuevos usuarios registrados' : filterStatus == 'activado' ? 'usuarios activados' : filterStatus == 'bloqueado' ? 'usuarios bloqueados' : 'documentos'} disponibles.",
                              style: const TextStyle(fontSize: 20, color: Colors.grey),
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

  Future<void> _cargarTiempoDePrueba() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final valor = doc.get('tiempoDePrueba');
        setState(() {
          _tiempoDePruebaDias = valor is int ? valor : int.tryParse(valor.toString());
        });
      }
    } catch (e) {
      debugPrint('Error al cargar tiempoDePrueba: $e');
    }
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
  Widget _buildStatCard(String title, int count, Color color, VoidCallback? onTap, {bool isSelected = false}) {
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
                floatingLabelBehavior: FloatingLabelBehavior.always, // 🔹 Mantener visible
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
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
                    floatingLabelBehavior: FloatingLabelBehavior.always,
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  )
                  ,
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
                    child: IntrinsicWidth(
                      child: DataTable(
                        showCheckboxColumn: false,
                        columnSpacing: 25,
                        columns: const [
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Situación')),
                          DataColumn(label: Text('Actualización\nRedención', style: TextStyle(fontSize: 12))),
                          DataColumn(label: Text('PPL')),
                          DataColumn(label: Text('Identificación')),
                          DataColumn(label: Text('Acudiente')),
                          //DataColumn(label: Text('Celular')),
                          DataColumn(label: Text('WhatsApp')),
                          DataColumn(label: Text('Pago', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Prueba', style: TextStyle(fontSize: 11))),
                          DataColumn(label: Text('Registro')),
                        ],
                        rows: registros.asMap().entries.map((entry) {
                          int index = entry.key;
                          var doc = entry.value;

                          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          final String assignedTo = data['assignedTo'] ?? "";
                          final bool isAssigned = assignedTo.isNotEmpty;
                          final String status = (data['status'] ?? '').toString().toLowerCase();
                          final String situacion = data['situacion'] ?? '';
                          final bool aplicaRedencion = situacion == 'En Reclusión';

                          return DataRow(
                            color: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                return index % 2 == 0 ? Colors.white : primary.withOpacity(0.05);
                              },
                            ),
                            onSelectChanged: (bool? selected) async {
                              if (selected != null && selected) {
                                String userRole = await _obtenerRolActual();

                                if (userRole != "operador") {
                                  Navigator.pushNamed(context, 'editar_registro_admin', arguments: doc);
                                  return;
                                }

                                final String assignedTo = data['assignedTo'] ?? "";
                                if (assignedTo.isEmpty) {
                                  bool confirmar = await _mostrarDialogoConfirmacion();
                                  if (!confirmar) return;
                                }

                                Navigator.pushNamed(context, 'editar_registro_admin', arguments: doc);
                              }
                            },
                            cells: [
                              // Estado
                              DataCell(
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(5)),
                                      child: Icon(Icons.circle, color: _getColor(status)),
                                    ),
                                    const SizedBox(width: 8),
                                    if (status == "registrado") ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isAssigned ? primary : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Icon(
                                          isAssigned ? Icons.check_circle : Icons.cancel,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Situación
                              DataCell(
                                Builder(
                                  builder: (_) {
                                    if (situacion == 'En Reclusión') {
                                      return const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock, color: Colors.grey, size: 15),
                                            SizedBox(height: 4),
                                            Text('En Reclusión', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    } else if (situacion == 'En Prisión domiciliaria') {
                                      return const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.home, color: Colors.orange, size: 15),
                                            SizedBox(height: 4),
                                            Text('Domiciliaria', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    } else if (situacion == 'En libertad condicional') {
                                      return const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.directions_walk, color: Colors.green, size: 15),
                                            SizedBox(height: 4),
                                            Text('Condicional', style: TextStyle(fontSize: 10)),
                                          ],
                                        ),
                                      );
                                    } else {
                                      return const Center(child: Text(''));
                                    }
                                  },
                                ),
                              ),

                              // 👉 Columna de redenciones
                              DataCell(
                                aplicaRedencion
                                    ? Column(
                                  children: [
                                    iconoRevision(
                                      data['ultima_actualizacion_redenciones'] is Timestamp
                                          ? (data['ultima_actualizacion_redenciones'] as Timestamp).toDate()
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data.containsKey('ultima_actualizacion_redenciones') &&
                                          data['ultima_actualizacion_redenciones'] != null
                                          ? '${DateFormat("d 'de' MMMM", 'es_CO').format(
                                        (data['ultima_actualizacion_redenciones'] as Timestamp).toDate(),
                                      )}\nde ${DateFormat("y", 'es_CO').format(
                                            (data['ultima_actualizacion_redenciones'] as Timestamp).toDate(),
                                          )}'
                                          : 'Sin revisión',
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                                    : const Text(
                                  'No aplica',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),

                              // Nombre + Apellido
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(data['nombre_ppl'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text(data['apellido_ppl'], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ],
                              )),

                              // Identificación
                              DataCell(Text(data['numero_documento_ppl'].toString(), style: const TextStyle(fontSize: 12 ))),

                              // Acudiente
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(data['nombre_acudiente'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text(data['apellido_acudiente'], style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                ],
                              )),
                              //
                              // // Celular
                              // DataCell(Text(data['celular'].toString())),

                              // WhatsApp
                              DataCell(Text(data.containsKey('celularWhatsapp') ? (data['celularWhatsapp'] ?? '') : '', style: const TextStyle(
                                fontSize: 12
                              ))),

                              // Pago
                              DataCell(
                                Icon(
                                  data['isPaid'] ? Icons.check_circle : Icons.cancel, size: 15,
                                  color: data['isPaid'] ? Colors.blue : Colors.grey,
                                ),
                              ),

                              // Prueba
                              DataCell(iconoPruebaYPago(doc)),

                              // Fecha
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(_convertirTimestampADateTime(data['fechaRegistro'])!),
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                                  ),
                                  Text(
                                    DateFormat('hh:mm a', 'es').format(_convertirTimestampADateTime(data['fechaRegistro'])!),
                                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),

                      ),
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

  Widget iconoPruebaYPago(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isPaid = data['isPaid'] == true;

    if (!data.containsKey('fechaActivacion')) {
      return const Tooltip(
        message: "Usuario aún no ha sido activado",
        child: Icon(Icons.help_outline, color: Colors.grey, size: 15),
      );
    }

    if (_tiempoDePruebaDias == null) {
      return const Tooltip(
        message: "Cargando configuración de prueba...",
        child: Icon(Icons.hourglass_top, color: Colors.grey, size: 15),
      );
    }

    final fechaActivacion = _convertirTimestampADateTime(data['fechaActivacion']);
    if (fechaActivacion == null) {
      return const Tooltip(
        message: "Fecha de activación no válida",
        child: Icon(Icons.error_outline, color: Colors.red, size: 15),
      );
    }

    final diasDesdeActivacion = DateTime.now().difference(fechaActivacion).inDays;

    // 🔵 Caso 1: Ya pagó
    if (isPaid) {
      return const Tooltip(
        message: "Pago realizado",
        child: Icon(Icons.verified_user, color: Colors.green, size: 15),
      );
    }

    // 🟠 Caso 2: En periodo de prueba
    if (diasDesdeActivacion < _tiempoDePruebaDias!) {
      final diasRestantes = _tiempoDePruebaDias! - diasDesdeActivacion;
      return Tooltip(
        message: "En periodo de prueba ($diasRestantes días restantes)",
        child: const Icon(Icons.lock_clock, color: Colors.orange, size: 15),
      );
    }

    // 🔴 Caso 3: Prueba vencida sin pago
    final bool yaSeEnvio = data['recordatorioWhatsappEnviado'] == true;
    final DateTime? fechaRecordatorio = _convertirTimestampADateTime(data['fechaRecordatorioWhatsapp']);
    final String mensajeTooltip = yaSeEnvio && fechaRecordatorio != null
        ? "Prueba vencida sin pago\nRecordatorio enviado el ${DateFormat("dd/MM/yyyy hh:mm a").format(fechaRecordatorio)}"
        : "Prueba vencida sin pago";

    return Tooltip(
      message: mensajeTooltip,
      child: Row(
        children: [
          InkWell(
            onTap: () {
              _mostrarDialogoPagoPendiente(doc);
            },
            child: const Icon(Icons.lock_outline, color: Colors.red,size: 15),
          ),
          if (yaSeEnvio) ...[
            const SizedBox(width: 4),
            const Icon(Icons.mark_chat_read, size: 15, color: Colors.green),
          ],
        ],
      ),
    );
  }

  Widget iconoRevision(DateTime? ultimaActualizacion) {
    if (ultimaActualizacion == null) {
      return const Tooltip(
        message: 'Aún no se ha hecho la primera revisión de las redenciones',
        child: Icon(Icons.help_outline, color: Colors.orange, size: 15),
      );
    }

    final diferencia = DateTime.now().difference(ultimaActualizacion).inDays;

    if (diferencia >= 30) {
      return const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 15);
    } else {
      return const Icon(Icons.check_circle, color: Colors.green, size: 15);
    }
  }

  void _mostrarDialogoPagoPendiente(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nombre = data['nombre_ppl'] ?? '';
    final apellido = data['apellido_ppl'] ?? '';
    final celular = data['celular']?.toString().replaceAll(' ', '') ?? '';

    final nombreAcudiente = data['nombre_acudiente'] ?? '';
    final mensaje = Uri.encodeComponent(
      "Hola $nombreAcudiente, soy del equipo de Tu Proceso Ya.\n\n"
          "Tu periodo de prueba ha finalizado, por lo cual, desafortunadamente ya no tienes acceso a la información de tu proceso.\n\n"
          "Si deseas continuar usando la plataforma, por favor realiza el pago correspondiente.\n\n"
          "Estamos disponibles para ayudarte.\n\n"
          "Ingresa ahora mismo a https://www.tuprocesoya.com",
    );

    final urlWhatsapp = "https://wa.me/57$celular?text=$mensaje";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text("Enviar recordatorio"),
          content: Text(
            "El usuario $nombre $apellido ha superado su periodo de prueba y no ha hecho el respectivo pago.\n\n¿Deseas enviarle un mensaje de recordatorio por WhatsApp?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);

                await doc.reference.update({
                  'recordatorioWhatsappEnviado': true,
                  'fechaRecordatorioWhatsapp': DateTime.now().toIso8601String(),
                });


                _abrirEnlace(urlWhatsapp);
              },
              icon: const Icon(Icons.chat),
              label: const Text("Enviar WhatsApp"),
            ),
          ],
        );
      },
    );
  }

  void _abrirEnlace(String url) {
    html.window.open(url, '_blank');
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
