import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import 'dart:html' as html;
import '../../../src/colors/colors.dart';
import '../../../widgets/agenda_viewer.dart';
import '../../../widgets/ventana_whatsApp.dart';

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
  bool _cargandoActualizacion = false;
  bool mostrarSeguimiento = false;
  bool mostrarConSolicitudes = false;
  int countUsuariosConSolicitudes =0;
  Set<String> idsConSolicitudes = {};
  late Future<Set<String>> _idsConSolicitudesFuture;
  bool filtrarPorExentos = false;
  String? _docIdSeleccionado;



  Color getColor(Map<String, dynamic> data) {
    final estado = data['status']?.toString().toLowerCase() ?? '';

    if (data['tiene_seguimiento_activo'] == true) {
      return Colors.pinkAccent;
    }

    if (data['requiere_actualizacion_datos'] == true) {
      return Colors.brown.shade300;
    }

    if (data['exento'] == true) {
      return Colors.black;
    }

    switch (estado) {
      case 'registrado':
        return primary;
      case 'activado':
        return Colors.green;
      case 'bloqueado':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String getTextoEstado(Map<String, dynamic> data) {
    final estado = data['status']?.toString().toLowerCase() ?? '';

    if (data['tiene_seguimiento_activo'] == true) return 'Seguimiento';
    if (data['requiere_actualizacion_datos'] == true) return 'Actualizar';
    if (data['exento'] == true) return 'Exento';

    switch (estado) {
      case 'registrado':
        return 'Registrado';
      case 'activado':
        return 'Activado';
      case 'bloqueado':
        return 'Bloqueado';
      case 'pendiente':
        return 'Pendiente';
      default:
        return '';
    }
  }


  /// OJO TOCA VALIDAR EN DONDE IBA ESTE CODIGO
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
    _escucharCambiosDeVersion();
    _idsConSolicitudesFuture = _obtenerIdsConSolicitudes();
  }

  Future<Set<String>> _obtenerIdsConSolicitudes() async {
    final snapshot = await FirebaseFirestore.instance.collection('solicitudes_usuario').get();

    return snapshot.docs
        .map((s) => s['idUser']?.toString())
        .where((id) => id != null)
        .cast<String>()
        .toSet();
  }


  void _escucharCambiosDeVersion() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 🔁 Escuchar en tiempo real los cambios en la versión remota
    FirebaseFirestore.instance
        .collection('configuraciones')
        .doc('h7NXeT2STxoHVv049o3J')
        .snapshots()
        .listen((configDoc) async {
      final versionRemota = configDoc.data()?['version_app_admin'];
      if (versionRemota == null) return;

      // 🧾 Obtener versión local del admin
      final adminDoc = await FirebaseFirestore.instance.collection('admin').doc(uid).get();
      final versionLocal = adminDoc.data()?['version'] ?? '0.0.0';

      print('🔁 Escucha versión remota: $versionRemota | Versión local: $versionLocal');

      _versionActual = versionLocal;
      _nuevaVersion = versionRemota;

      if (_nuevaVersion != _versionActual) {
        setState(() {
          _mostrarBanner = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Panel de administración',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000 ? double.infinity : double.infinity,
            child: FutureBuilder<Set<String>>(
              future: _idsConSolicitudesFuture,
              builder: (context, snapshotSolicitudes) {
                if (!snapshotSolicitudes.hasData) return const Center(child: CircularProgressIndicator());
                final idsConSolicitudes = snapshotSolicitudes.data!;

                return FutureBuilder<DocumentSnapshot>(
                  future: _firebaseFirestore.collection('admin').doc(FirebaseAuth.instance.currentUser?.uid ?? "").get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    String userRole = snapshot.data!.exists && snapshot.data!.data() != null
                        ? snapshot.data!.get('rol').toString().toLowerCase()
                        : "";
                    List<String> rolesOperadores = ["operador 1", "operador 2", "operador 3"];
                    bool esOperador = rolesOperadores.contains(userRole);
                    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                    /// EN ESTA PARTE SE HACE EL FILTRADO

                    return StreamBuilder<QuerySnapshot>(
                      stream: _firebaseFirestore.collection('Ppl').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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

                        final int countSuscritos = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final isPaid = data['isPaid'] == true;
                          return isPaid;
                        }).length;


                        final int countBloqueado = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'bloqueado').length;
                        final int countPendiente = docs.where((doc) => doc.get('status').toString().toLowerCase() == 'pendiente').length;

                        final int countActivadoIncompleto = docs.where((doc) {
                          final status = doc.get('status').toString().toLowerCase();
                          final data = doc.data() as Map<String, dynamic>;
                          return status == 'activado' && (data['requiere_actualizacion_datos'] == true);
                        }).length;

                        // final int countTotal = docs.where((doc) {
                        //   final assignedTo = doc.get('assignedTo') ?? "";
                        //   final status = doc.get('status').toString().toLowerCase();
                        //   if (esOperador) {
                        //     return (status == 'registrado' && (assignedTo.isEmpty || assignedTo == currentUserUid)) ||
                        //         status == 'activado' || status == 'bloqueado';
                        //   }
                        //   return true;
                        // }).length;

                        final int countRedencionesVencidas = docs.where((doc) {
                          final status = doc.get('status').toString().toLowerCase();
                          final data = doc.data() as Map<String, dynamic>;
                          if (status != 'activado') return false;
                          final ts = data['ultima_actualizacion_redenciones'];
                          if (ts == null || ts is! Timestamp) return false;
                          final diferencia = DateTime.now().difference(ts.toDate()).inDays;
                          return diferencia >= 30;
                        }).length;

                        final int countConSeguimiento = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['tiene_seguimiento_activo'] == true;
                        }).length;

                        final int countUsuariosConSolicitudes = docs.where((doc) {
                          return idsConSolicitudes.contains(doc.id);
                        }).length;

                        final int countExentos = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['exento'] == true;
                        }).length;


                        List<QueryDocumentSnapshot> filteredDocs;

                        if (searchQuery.trim().isNotEmpty) {
                          final query = searchQuery.toLowerCase();
                          // 👇 búsqueda global en todos los docs
                          filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombre = normalizar(data['nombre_ppl']?.toString() ?? '');
                            final apellido = normalizar(data['apellido_ppl']?.toString() ?? '');
                            final identificacion = normalizar(data['numero_documento_ppl']?.toString() ?? '');
                            final acudiente = normalizar("${data['nombre_acudiente'] ?? ''} ${data['apellido_acudiente'] ?? ''}");
                            final celularAcudiente = normalizar(data['celular']?.toString() ?? '');

                            return nombre.contains(query) ||
                                apellido.contains(query) ||
                                identificacion.contains(query) ||
                                acudiente.contains(query) ||
                                celularAcudiente.contains(query);
                          }).toList();
                        } else {
                          // 👇 solo aplica filtros si NO hay búsqueda
                          filteredDocs = docs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = doc.get('status').toString().toLowerCase();
                            final assignedTo = doc.get('assignedTo') ?? "";
                            final requiereActualizacion = data['requiere_actualizacion_datos'] ?? false;

                            if (filtrarPorExentos && data['exento'] != true) return false;

                            if (mostrarConSolicitudes && !idsConSolicitudes.contains(doc.id)) return false;

                            if (mostrarSeguimiento) {
                              final tieneSeguimiento = data['tiene_seguimiento_activo'] == true;
                              return status == 'activado' && tieneSeguimiento;
                            }

                            if (mostrarRedencionesVencidas) {
                              final ts = data['ultima_actualizacion_redenciones'];
                              if (ts == null || ts is! Timestamp) return false;
                              final diferencia = DateTime.now().difference(ts.toDate()).inDays;
                              return status == 'activado' && diferencia >= 30;
                            }

                            if (filterStatus != null || filterIsPaid != null) {
                              // Si hay filtro por status "registrado"
                              if (filterStatus == 'registrado') {
                                final coincideStatus = status == 'registrado' &&
                                    (!esOperador || assignedTo.isEmpty || assignedTo == currentUserUid);
                                if (filterIsPaid == true) {
                                  return coincideStatus && data['isPaid'] == true;
                                }
                                return coincideStatus;
                              }

                              // Si hay filtro por status "activado"
                              if (filterStatus == 'activado') {
                                final coincideStatus = mostrarSoloIncompletos
                                    ? status == 'activado' && requiereActualizacion == true
                                    : status == 'activado' && requiereActualizacion != true;
                                if (filterIsPaid == true) {
                                  return coincideStatus && data['isPaid'] == true;
                                }
                                return coincideStatus;
                              }

                              // Si solo hay filtro por isPaid (y no importa status)
                              if (filterStatus == null && filterIsPaid == true) {
                                return data['isPaid'] == true;
                              }

                              // Otro status cualquiera
                              final coincideStatus = status == filterStatus;
                              if (filterIsPaid == true) {
                                return coincideStatus && data['isPaid'] == true;
                              }
                              return coincideStatus;
                            }


                            return true;
                          }).toList();

                        }

                        if (mostrarSeguimiento) {
                          filteredDocs = filteredDocs.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = doc.get('status').toString().toLowerCase();
                            return status == 'activado' && data['tiene_seguimiento_activo'] == true;
                          }).toList();
                        }

                        if (mostrarConSolicitudes) {
                          filteredDocs = filteredDocs.where((doc) => idsConSolicitudes.contains(doc.id)).toList();
                        }

                        if (mostrarRedencionesVencidas) {
                          filteredDocs = filteredDocs.where((doc) {
                            final status = doc.get('status').toString().toLowerCase();
                            final data = doc.data() as Map<String, dynamic>;
                            if (status != 'activado') return false;
                            final ts = data['ultima_actualizacion_redenciones'];
                            if (ts == null || ts is! Timestamp) return false;
                            final diferencia = DateTime.now().difference(ts.toDate()).inDays;
                            return diferencia >= 30;
                          }).toList();
                        }

                        return Column(
                          children: [
                            if (_mostrarBanner)
                              Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 480),
                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "Actualización disponible",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text("Versión actual: $_versionActual /",
                                                  style: const TextStyle(fontSize: 11)),
                                              const SizedBox(width: 10),
                                              Text("Nueva versión: $_nuevaVersion",
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          ElevatedButton(
                                            onPressed: _cargandoActualizacion
                                                ? null
                                                : () async {
                                              setState(() {
                                                _cargandoActualizacion = true;
                                              });

                                              final uid = FirebaseAuth.instance.currentUser?.uid;
                                              if (uid != null && _nuevaVersion != null) {
                                                await FirebaseFirestore.instance
                                                    .collection('admin')
                                                    .doc(uid)
                                                    .update({
                                                  'version': _nuevaVersion,
                                                  'fecha_actualizacion_version':
                                                  FieldValue.serverTimestamp(),
                                                });

                                                setState(() {
                                                  _mostrarBanner = false;
                                                });

                                                html.window.navigator.serviceWorker?.controller
                                                    ?.postMessage('skipWaiting');

                                                Future.delayed(const Duration(milliseconds: 200),
                                                        () {
                                                      html.window.location.reload();
                                                    });
                                              } else {
                                                setState(() {
                                                  _cargandoActualizacion = false;
                                                });
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.deepPurple,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 10),
                                            ),
                                            child: _cargandoActualizacion
                                                ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2, color: Colors.white),
                                            )
                                                : const Text("Actualizar"),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),

                            // 🟢 Esta parte se queda para el panel de usuarios
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isDesktop = constraints.maxWidth > 600;

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Tarjeta total de usuarios
                                    TotalUsuariosCard(totalUsuarios: docs.length),

                                    // Campo de búsqueda
                                    SizedBox(
                                      width: 250,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                        child: _buildSearchField(),
                                      ),
                                    ),

                                    // Chat de WhatsApp (solo en pantallas grandes)
                                    if (constraints.maxWidth >= 800)
                                      const SizedBox(
                                        width: 400,
                                        child: WhatsAppChatWrapper(),
                                      ),

                                    // Agendador (solo si hay suficiente espacio)
                                    if (constraints.maxWidth >= 1200)
                                      const SizedBox(
                                        width: 400,
                                        child: AgendaViewerCompact(),
                                      ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 30),
                            const Divider(color: primary, height: 2),
                            const SizedBox(height: 30),

                            // Tu contenido principal del dashboard
                            buildDashboardContent(
                              filteredDocs,
                              countRegistrado: countRegistrado,
                              countActivado: countActivado,
                              countSuscritos: countSuscritos,
                              countPendiente: countPendiente,
                              countBloqueado: countBloqueado,
                              countRedencionesVencidas: countRedencionesVencidas,
                              countActivadoIncompleto: countActivadoIncompleto,
                              countConSeguimiento: countConSeguimiento,
                              countExentos: countExentos,
                              countUsuariosConSolicitudes: countUsuariosConSolicitudes,
                            ),

                            const SizedBox(height: 30),
                          ],
                        );
                      },
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

  Widget buildDashboardContent(
      List<QueryDocumentSnapshot> filteredDocs, {
        required int countRegistrado,
        required int countActivado,
        required int countSuscritos,
        required int countPendiente,
        required int countBloqueado,
        required int countRedencionesVencidas,
        required int countActivadoIncompleto,
        required int countConSeguimiento,
        required int countExentos,
        required int countUsuariosConSolicitudes,
      }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          // 🔹 Móvil: filtros arriba
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilterContainer(
                countRegistrado: countRegistrado,
                countActivado: countActivado,
                countSuscritos: countSuscritos,
                countPendiente: countPendiente,
                countBloqueado: countBloqueado,
                countRedencionesVencidas: countRedencionesVencidas,
                countActivadoIncompleto: countActivadoIncompleto,
                countConSeguimiento: countConSeguimiento,
                countExentos: countExentos,
                countUsuariosConSolicitudes: countUsuariosConSolicitudes,
                selectedFilter: filterStatus,
                onFilterSelected: (filtro) {
                  setState(() {
                    filterStatus = filtro;
                  });
                },
              ),

              const SizedBox(height: 16),
              _buildUserTable(filteredDocs),
            ],
          );
        } else {
          // 🟢 Escritorio: filtros siempre visibles
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: _buildFilterContainer(
                  countRegistrado,
                  countActivado,
                  countSuscritos,
                  countPendiente,
                  countBloqueado,
                  countRedencionesVencidas,
                  countActivadoIncompleto,
                  countConSeguimiento,
                  countExentos,
                  countUsuariosConSolicitudes,
                ),
              ),
              const SizedBox(width: 16),
              // La tabla scrollea
              Expanded(
                child: SingleChildScrollView(
                  child: _buildUserTable(filteredDocs),
                ),
              ),
            ],
          );
        }
      },
    );
  }


  Widget _buildFilterContainer(
      int countRegistrado,
      int countActivado,
      int countSuscritos,
      int countPendiente,
      int countBloqueado,
      int countRedencionesVencidas,
      int countActivadoIncompleto,
      int countConSeguimiento,
      int countExentos,
      int countUsuariosConSolicitudes,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildStatRow(
            "Registrados",
            countRegistrado,
            primary,
                () { setState(() {
              filterStatus = "registrado";
              filterIsPaid = null;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: filterStatus == "registrado",
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Activados",
            countActivado,
            Colors.green,
                () { setState(() {
              filterStatus = "activado";
              filterIsPaid = null;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: filterStatus == "activado" && !mostrarSoloIncompletos && !mostrarRedencionesVencidas && !mostrarSeguimiento,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Suscritos",
            countSuscritos,
            Colors.blue,
                () { setState(() {
              filterIsPaid = true;
              filterStatus = null;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: filterIsPaid == true && filterStatus == null && !mostrarSoloIncompletos && !mostrarRedencionesVencidas && !mostrarSeguimiento && !mostrarConSolicitudes && !filtrarPorExentos,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Seguimiento",
            countConSeguimiento,
            Colors.pink,
                () { setState(() {
              filterStatus = "activado";
              mostrarSeguimiento = true;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: mostrarSeguimiento,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Con solicitudes",
            countUsuariosConSolicitudes,
            Colors.deepPurpleAccent,
                () { setState(() {
              mostrarConSolicitudes = true;
              filterStatus = null;
              mostrarSeguimiento = false;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              filtrarPorExentos = false;
            }); },
            isSelected: mostrarConSolicitudes,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Pendientes",
            countPendiente,
            Colors.orange,
                () { setState(() {
              filterStatus = "pendiente";
              filterIsPaid = null;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: filterStatus == "pendiente",
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Bloqueados",
            countBloqueado,
            Colors.red,
                () { setState(() {
              filterStatus = "bloqueado";
              filterIsPaid = null;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: filterStatus == "bloqueado",
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Redenciones vencidas",
            countRedencionesVencidas,
            Colors.purple,
                () { setState(() {
              mostrarRedencionesVencidas = true;
              filterStatus = null;
              filterIsPaid = null;
              mostrarSoloIncompletos = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: mostrarRedencionesVencidas,
          ),
          const SizedBox(height: 6),
          _buildStatRow(
            "Activos\nIncompletos",
            countActivadoIncompleto,
            Colors.brown,
                () { setState(() {
              filterStatus = "activado";
              mostrarSoloIncompletos = true;
              mostrarSeguimiento = false;
              mostrarRedencionesVencidas = false;
              mostrarConSolicitudes = false;
              filtrarPorExentos = false;
            }); },
            isSelected: filterStatus == "activado" && mostrarSoloIncompletos,
          ),
          const SizedBox(height: 6),

          const SizedBox(height: 6),
          _buildStatRow(
            "Exentos",
            countExentos,
            Colors.black,
                () { setState(() {
              filtrarPorExentos = true;
              filterStatus = null;
              mostrarSoloIncompletos = false;
              mostrarRedencionesVencidas = false;
              mostrarSeguimiento = false;
              mostrarConSolicitudes = false;
            }); },
            isSelected: filtrarPorExentos,
          ),
          const SizedBox(height: 6),

        ],
      ),
    );
  }





  Widget _buildStatRow(
      String title,
      int count,
      Color color,
      VoidCallback? onTap, {
        bool isSelected = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Indicador de color
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            // Título
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Contador
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Future<int> contarUsuariosConSolicitudes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('solicitudes_usuario')
        .get();

    final Set<String> usuariosUnicos = {};

    for (var doc in snapshot.docs) {
      final idUser = doc['idUser'];
      if (idUser != null) {
        usuariosUnicos.add(idUser);
      }
    }

    return usuariosUnicos.length;
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

  Widget buildTotalUsuariosCard(int totalUsuarios) {
    // Formatear fecha actual con formato largo en español
    final String fechaActual = "Hoy es ${DateFormat('d \'de\' MMMM \'de\' y', 'es_ES').format(DateTime.now())}";

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            fechaActual,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            totalUsuarios.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Usuarios Totales",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String normalizar(String texto) {
    return removeDiacritics(texto.toLowerCase());
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = normalizar(value);
          });
        },
        decoration: InputDecoration(
          labelText: "Buscar registros",
          floatingLabelBehavior: FloatingLabelBehavior.always,
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
    );
  }

  Widget _buildUserTable(List<QueryDocumentSnapshot> docs) {
    // Si no hay registros, mostramos mensaje directamente
    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                "No hay registros que mostrar.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si hay registros, mostramos la tabla normal
    String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return FutureBuilder<String>(
      future: _obtenerRolActual(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        String userRole = snapshot.data!;
        List<String> rolesOperadores = ["operador 1", "operador 2", "operador 3"];
        bool esOperador = rolesOperadores.contains(userRole);

        if (esOperador) {
          docs = docs.where((doc) {
            final assignedTo = doc.get('assignedTo') ?? "";
            final status = doc.get('status').toString().toLowerCase();

            if (status == "registrado") {
              return assignedTo.isEmpty || assignedTo == currentUserUid;
            }
            return true;
          }).toList();
        }

        // Si después de filtrar quedó vacío, también mostramos mensaje
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    "No hay registros que mostrar.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        docs.sort((a, b) {
          DateTime? fechaA = _convertirTimestampADateTime(a.get('fechaRegistro'));
          DateTime? fechaB = _convertirTimestampADateTime(b.get('fechaRegistro'));
          return (fechaB ?? DateTime(0)).compareTo(fechaA ?? DateTime(0));
        });

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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      semanaTexto,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ),
                  const Divider(color: Colors.grey, thickness: 1),
                  _buildDataTable(registros, {}),
                  const Divider(height: 30, thickness: 2, color: Colors.grey),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }


  Widget _buildDataTable(List<QueryDocumentSnapshot> registros, Map<String, Map<String, dynamic>> porcentajesPorDocId) {
    final int rowsPerPage = calcularRowsPerPage(registros.length);

    return Container(
      color: Colors.white, // Fondo blanco para toda la tabla
      padding: const EdgeInsets.all(8), // Espaciado opcional
      child: PaginatedDataTable(
        header: const Text(''),
        rowsPerPage: rowsPerPage,
        columnSpacing: 30,
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text("Beneficios")),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Situación')),
          DataColumn(label: Text('Última\nRedención', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('Último\nSeguimiento', style: TextStyle(fontSize: 12))),
          DataColumn(label: Text('PPL')),
          DataColumn(label: Text('Identificación')),
          DataColumn(label: Text('Acudiente')),
          DataColumn(label: Text('WhatsApp')),
          DataColumn(label: Text('Pago')),
          DataColumn(label: Text('Prueba')),
          DataColumn(label: Text('Registro')),
        ],
          source: _TablaDataSource(
            context: context,
            registros: registros,
            porcentajesPorDocId: porcentajesPorDocId,
            onRowSelected: (doc) async {
              setState(() {
                _docIdSeleccionado = doc.id;
              });

              await Navigator.pushNamed(context, 'editar_registro_admin', arguments: doc);

              // Cuando regresas, el mismo doc seguirá seleccionado gracias al fondo
              setState(() {}); // Refresca la tabla por si algo cambió
            },

            convertirFecha: _convertirTimestampADateTime,
            tiempoDePruebaDias: _tiempoDePruebaDias,
            onTapPagoPendiente: (doc) => _mostrarDialogoPagoPendiente(doc),
            getColor: getColor,
            getTextoEstado: getTextoEstado,
            docIdSeleccionado: _docIdSeleccionado, // 👈 pásala aquí
          )

      ),
    );
  }

  int calcularRowsPerPage(int totalRegistros) {
    if (totalRegistros <= 5) return totalRegistros;
    return 10; // Valor por defecto si hay suficientes registros
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

Widget iconoPruebaYPago({
  required Map<String, dynamic> data,
  required int? tiempoDePruebaDias,
  required void Function() onTapPagoPendiente,
}) {
  final isPaid = data['isPaid'] == true;

  if (!data.containsKey('fechaActivacion')) {
    return const Tooltip(
      message: "Usuario aún no ha sido activado",
      child: Icon(Icons.help_outline, color: Colors.grey, size: 15),
    );
  }

  final fechaActivacion = convertirTimestampADateTime(data['fechaActivacion']);
  if (fechaActivacion == null) {
    return const Tooltip(
      message: "Fecha de activación no válida",
      child: Icon(Icons.error_outline, color: Colors.red, size: 15),
    );
  }

  if (tiempoDePruebaDias == null) {
    return const Tooltip(
      message: "Cargando configuración de prueba...",
      child: Icon(Icons.hourglass_top, color: Colors.grey, size: 15),
    );
  }

  final diasDesdeActivacion = DateTime.now().difference(fechaActivacion).inDays;

  if (isPaid) {
    return const Tooltip(
      message: "Pago realizado",
      child: Icon(Icons.verified_user, color: Colors.green, size: 15),
    );
  }

  if (diasDesdeActivacion < tiempoDePruebaDias) {
    final diasRestantes = tiempoDePruebaDias - diasDesdeActivacion;
    return Tooltip(
      message: "En periodo de prueba ($diasRestantes días restantes)",
      child: const Icon(Icons.lock_clock, color: Colors.orange, size: 15),
    );
  }

  final bool yaSeEnvio = data['recordatorioWhatsappEnviado'] == true;
  final DateTime? fechaRecordatorio = convertirTimestampADateTime(data['fechaRecordatorioWhatsapp']);
  final String mensajeTooltip = yaSeEnvio && fechaRecordatorio != null
      ? "Prueba vencida sin pago\nRecordatorio enviado el ${DateFormat("dd/MM/yyyy hh:mm a").format(fechaRecordatorio)}"
      : "Prueba vencida sin pago";

  return Tooltip(
    message: mensajeTooltip,
    child: Row(
      children: [
        InkWell(
          onTap: onTapPagoPendiente,
          child: const Icon(Icons.lock_outline, color: Colors.red, size: 15),
        ),
        if (yaSeEnvio) ...[
          const SizedBox(width: 4),
          const Icon(Icons.mark_chat_read, size: 15, color: Colors.green),
        ],
      ],
    ),
  );
}


// 🔹 FUNCIONES AUXILIARES (afuera de clases)
DateTime? convertirTimestampADateTime(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  }
  return null;
}

class _TablaDataSource extends DataTableSource {
  final BuildContext context;
  final List<QueryDocumentSnapshot> registros;
  final Map<String, Map<String, dynamic>> porcentajesPorDocId;
  final void Function(QueryDocumentSnapshot doc) onRowSelected;
  final DateTime? Function(dynamic)? convertirFecha;
  final int? tiempoDePruebaDias; // 🔹 nuevo
  final void Function(QueryDocumentSnapshot) onTapPagoPendiente;
  final Color Function(Map<String, dynamic>) getColor;
  final String Function(Map<String, dynamic>) getTextoEstado;
  final String? docIdSeleccionado;

  _TablaDataSource({
    required this.context,
    required this.registros,
    required this.porcentajesPorDocId,
    required this.onRowSelected,
    this.convertirFecha,
    required this.tiempoDePruebaDias,
    required this.onTapPagoPendiente,
    required this.getColor,
    required this.getTextoEstado,
    required this.docIdSeleccionado,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= registros.length) return null;
    final doc = registros[index];
    final data = doc.data() as Map<String, dynamic>;
    final String status = (data['status'] ?? '').toString().toLowerCase();
    final String situacion = data['situacion'] ?? '';
    final bool isPaid = data['isPaid'] ?? false;
    final bool isAssigned = (data['assignedTo'] ?? '').toString().isNotEmpty;
    final bool aplicaRedencion = situacion == 'En Reclusión';
    final colorEstado = getColor(data);
    final textoEstado = getTextoEstado(data);

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onRowSelected(doc),
      color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (docIdSeleccionado == doc.id) {
            return Colors.yellow.withOpacity(0.2); // fondo de la fila seleccionada
          }
          return index % 2 == 0 ? Colors.white : Colors.blue.withOpacity(0.05);
        },
      ),

      cells: [
        // 🔷 Nivel beneficio
        DataCell(Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getIconoPorNivel(data['nivel_tiempo_beneficio']),
            const SizedBox(height: 2),
            Text(_getTextoPorNivel(data['nivel_tiempo_beneficio']), style: const TextStyle(fontSize: 10)),
          ],
        )),

        // 🔷 Estado
        // 🔷 Estado
        DataCell(
          Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: colorEstado,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    textoEstado,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorEstado,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(width: 4),

              // 🔴 Solo si NO está asignado Y el estado es 'registrado'
              if (!isAssigned && status == 'registrado')
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),

        // 🔷 Situación
        DataCell(_getIconoPorSituacion(situacion)),

        // 🔷 Redención
        DataCell(aplicaRedencion
            ? Builder(
          builder: (_) {
            final fechaRedencion = convertirTimestampADateTime(data['ultima_actualizacion_redenciones']);
            final bool mostrarAlerta = fechaRedencion != null &&
                DateTime.now().difference(fechaRedencion).inDays > 90;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mostrarAlerta ? Icons.warning_amber_rounded : Icons.update,
                  size: 16,
                  color: mostrarAlerta ? Colors.red : Colors.black87,
                ),
                const SizedBox(height: 2),
                Text(
                  fechaRedencion != null
                      ? DateFormat("d 'de' MMMM 'de' y", 'es_CO').format(fechaRedencion)
                      : 'Sin revisión',
                  style: TextStyle(
                    fontSize: 10,
                    color: mostrarAlerta ? Colors.red : Colors.black87,
                    fontWeight: mostrarAlerta ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        )
            : const Text("No aplica", style: TextStyle(color: Colors.grey, fontSize: 10))),
        // 🔷 Último seguimiento
        DataCell(_buildSeguimiento(data['ultimo_seguimiento'])),

        // 🔷 PPL
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['nombre_ppl'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(data['apellido_ppl'] ?? '', style: const TextStyle(fontSize: 12)),
          ],
        )),

        // 🔷 Documento
        DataCell(Text(data['numero_documento_ppl'].toString(), style: const TextStyle(fontSize: 12))),

        // 🔷 Acudiente
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['nombre_acudiente'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(data['apellido_acudiente'] ?? '', style: const TextStyle(fontSize: 12)),
          ],
        )),

        // 🔷 WhatsApp
        DataCell(Text(data['celularWhatsapp'] ?? '', style: const TextStyle(fontSize: 12))),

        // 🔷 Pago
        DataCell(Icon(isPaid ? Icons.check_circle : Icons.cancel, color: isPaid ? Colors.blue : Colors.grey)),

        // 🔷 Prueba
        DataCell(
          iconoPruebaYPago(
            data: data,
            tiempoDePruebaDias: tiempoDePruebaDias,
            onTapPagoPendiente: () => onTapPagoPendiente(doc),
          ),
        ),

        // 🔷 Registro
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat("dd 'de' MMMM 'de' yyyy", 'es').format(
                  convertirTimestampADateTime(data['fechaRegistro']) ?? DateTime.now()),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
            Text(
              DateFormat('hh:mm a', 'es').format(
                  convertirTimestampADateTime(data['fechaRegistro']) ?? DateTime.now()),
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => registros.length;

  @override
  int get selectedRowCount => 0;

  // Helpers:
  Widget _getIconoPorSituacion(String situacion) {
    switch (situacion) {
      case 'En Reclusión':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 15, color: Colors.grey),
            Text("Reclusión", style: TextStyle(fontSize: 10)),
          ],
        );
      case 'En Prisión domiciliaria':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.home, size: 15, color: Colors.orange),
            Text("Domiciliaria", style: TextStyle(fontSize: 10)),
          ],
        );
      case 'En libertad condicional':
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk, size: 15, color: Colors.green),
            Text("Condicional", style: TextStyle(fontSize: 10)),
          ],
        );
      default:
        return const Text('-', style: TextStyle(fontSize: 10));
    }
  }

  Widget _buildSeguimiento(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final fecha = timestamp.toDate();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(DateFormat("d 'de' MMMM 'de' y", 'es_CO').format(fecha), style: const TextStyle(fontSize: 10)),
          Text(DateFormat('hh:mm a', 'es_CO').format(fecha), style: const TextStyle(fontSize: 10)),
        ],
      );
    }
    return const Text("Sin seguimiento", style: TextStyle(fontSize: 10, color: Colors.grey));
  }

  Icon _getIconoPorNivel(dynamic nivel) {
    switch (nivel) {
      case 'superado':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case 'cercano':
        return const Icon(Icons.access_time, color: Colors.orange, size: 20);
      case 'bajo':
        return const Icon(Icons.cancel, color: Colors.red, size: 20);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey, size: 20);
    }
  }

  String _getTextoPorNivel(dynamic nivel) {
    switch (nivel) {
      case 'superado':
        return 'Beneficios';
      case 'cercano':
        return 'Cercano';
      case 'bajo':
        return 'Lejano';
      default:
        return 'Sin dato';
    }
  }

}

class WhatsAppChatWrapper extends StatefulWidget {
  const WhatsAppChatWrapper({Key? key}) : super(key: key);

  @override
  State<WhatsAppChatWrapper> createState() => _WhatsAppChatWrapperState();
}

class _WhatsAppChatWrapperState extends State<WhatsAppChatWrapper> {
  String? _numeroCliente;

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('whatsapp_messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshotMensajes) {
      if (snapshotMensajes.docs.isNotEmpty) {
        final numero = snapshotMensajes.docs.first['conversationId']?.toString() ?? 'Sin número';
        setState(() {
          _numeroCliente = numero;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_numeroCliente == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return WhatsAppChatSummary(
      numeroCliente: _numeroCliente!,
    );
  }
}

class TotalUsuariosCard extends StatelessWidget {
  final int totalUsuarios;

  const TotalUsuariosCard({Key? key, required this.totalUsuarios}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String fechaActual = "Hoy es ${DateFormat('d \'de\' MMMM \'de\' y', 'es_ES').format(DateTime.now())}";

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            fechaActual,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            totalUsuarios.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Usuarios Totales",
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FilterContainer extends StatelessWidget {
  final int countRegistrado;
  final int countActivado;
  final int countSuscritos;
  final int countPendiente;
  final int countBloqueado;
  final int countRedencionesVencidas;
  final int countActivadoIncompleto;
  final int countConSeguimiento;
  final int countExentos;
  final int countUsuariosConSolicitudes;
  final void Function(String filtro) onFilterSelected;
  final String? selectedFilter;

  const FilterContainer({
    Key? key,
    required this.countRegistrado,
    required this.countActivado,
    required this.countSuscritos,
    required this.countPendiente,
    required this.countBloqueado,
    required this.countRedencionesVencidas,
    required this.countActivadoIncompleto,
    required this.countConSeguimiento,
    required this.countExentos,
    required this.countUsuariosConSolicitudes,
    required this.onFilterSelected,
    this.selectedFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatRow("Registrados", countRegistrado, Colors.blue, () => onFilterSelected("registrado")),
        const SizedBox(height: 6),
        _buildStatRow("Activados", countActivado, Colors.green, () => onFilterSelected("activado")),
        const SizedBox(height: 6),
        _buildStatRow("Suscritos", countSuscritos, Colors.deepPurple, () => onFilterSelected("suscritos")),
        const SizedBox(height: 6),
        _buildStatRow("Pendientes", countPendiente, Colors.orange, () => onFilterSelected("pendiente")),
        const SizedBox(height: 6),
        _buildStatRow("Bloqueados", countBloqueado, Colors.red, () => onFilterSelected("bloqueado")),
        const SizedBox(height: 6),
        _buildStatRow("Redenciones vencidas", countRedencionesVencidas, Colors.purple, () => onFilterSelected("redenciones")),
        const SizedBox(height: 6),
        _buildStatRow("Activos Incompletos", countActivadoIncompleto, Colors.brown, () => onFilterSelected("incompletos")),
        const SizedBox(height: 6),
        _buildStatRow("Seguimiento", countConSeguimiento, Colors.pink, () => onFilterSelected("seguimiento")),
        const SizedBox(height: 6),
        _buildStatRow("Exentos", countExentos, Colors.black, () => onFilterSelected("exentos")),
        const SizedBox(height: 6),
        _buildStatRow("Con solicitudes", countUsuariosConSolicitudes, Colors.deepPurpleAccent, () => onFilterSelected("solicitudes")),
      ],
    );
  }


  Widget _buildStatRow(
      String title,
      int count,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, color: color),
            const SizedBox(width: 8),
            Text(title),
            const Spacer(),
            Text(count.toString()),
          ],
        ),
      ),
    );
  }
}





