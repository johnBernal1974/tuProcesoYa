import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class HistorialSolicitudesPermiso72HorasAdminPage extends StatefulWidget {
  const HistorialSolicitudesPermiso72HorasAdminPage({super.key});

  @override
  State<HistorialSolicitudesPermiso72HorasAdminPage> createState() => _HistorialSolicitudesPermiso72HorasAdminPageState();
}

class _HistorialSolicitudesPermiso72HorasAdminPageState extends State<HistorialSolicitudesPermiso72HorasAdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _filtroEstado = "Solicitado"; // Estado por defecto
  String rol = AdminProvider().rol ?? "";
  String adminFullName="";

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
    // Otras inicializaciones, por ejemplo:
    // _fetchPendingSuggestions();
    adminFullName = AdminProvider().adminFullName ?? ""; // Nombre completo
    if (adminFullName.isEmpty) {
      if (kDebugMode) {
        print("❌ No se pudo obtener el nombre del administrador.");
      }
    }
  }

  Future<void> _loadAdminRole() async {
    await AdminProvider().loadAdminData();
    setState(() {
      rol = AdminProvider().rol!;
      // Si el rol es "pasante 2", establecer el filtro por defecto a "Diligenciado"
      if (rol == "pasante 2") {
        _filtroEstado = "Diligenciado";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitudes de Permiso de 72 horas',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 1200 : double.infinity,
          child: Column(
            children: [
              _buildEstadoCards(rol),
              const SizedBox(height: 50),
              Expanded(
                  child:StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('permiso_solicitados')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No hay solicitudes de permiso de 72 horas.",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      // Obtener el usuario actual
                      final currentUser = FirebaseAuth.instance.currentUser;
                      final currentUserUid = currentUser?.uid;
                      // 🔹 Filtrar documentos cuando el usuario da clic en la tarjeta de estadísticas
                      var filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final asignadoA = data['asignadoA']?.toString().trim();
                        final asignadoA_P2 = data['asignadoA_P2']?.toString().trim();
                        bool assignedToMe = currentUserUid != null && asignadoA == currentUserUid;
                        bool assignedToMeP2 = currentUserUid != null && asignadoA_P2 == currentUserUid;
                        bool unassigned = asignadoA_P2 == null || asignadoA_P2.isEmpty;

                        // 🔹 Master y Coordinadores ven TODO según el estado seleccionado
                        if (rol == "master" || rol == "masterFull" || rol == "coordinador 1" || rol == "coordinador 2") {
                          return data["status"] == _filtroEstado;
                        }

                        // 🔹 Pasante 1: Solo ve los documentos que él mismo diligenció, sin importar el estado actual
                        if (rol == "pasante 1") {
                          if (_filtroEstado == "Solicitado") {
                            return (asignadoA == null || asignadoA.isEmpty || asignadoA == currentUserUid)
                                && data["status"] == "Solicitado";
                          }

                          if (_filtroEstado == "Diligenciado") {
                            return assignedToMe &&
                                (data["status"] == "Diligenciado" ||
                                    data["status"] == "Revisado" ||
                                    data["status"] == "Enviado");
                          }
                        }


                        // 🔹 Pasante 2: Ve "Diligenciados" asignados a él y los no asignados, además de "Revisados" y "Enviados"
                        if (rol == "pasante 2") {
                          if (_filtroEstado == "Diligenciado") return data["status"] == "Diligenciado" && (assignedToMeP2 || unassigned);
                          if (_filtroEstado == "Revisado") return data["status"] == "Revisado" && assignedToMeP2;
                          if (_filtroEstado == "Enviado") return data["status"] == "Enviado";
                        }

                        return false;
                      }).toList();

                      // 🔹 Si no hay documentos en el estado seleccionado, mostramos el mensaje de advertencia
                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning, color: Colors.red, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                "No hay documentos en estado $_filtroEstado.",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }

                      if (filteredDocs.isEmpty) {
                        return Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.warning, color: Colors.red, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "No hay documentos ${_filtroEstado}s.",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document = filteredDocs[index];
                          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                          return _buildSolicitudCard(data, document.id, rol);
                        },
                      );
                    },
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoCards(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('permiso_solicitados').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        var docs = snapshot.data!.docs;
        String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        bool isMobile = MediaQuery.of(context).size.width < 600;
        int countSolicitado = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final asignadoA = data['asignadoA']?.toString().trim();
          bool unassigned = asignadoA == null || asignadoA.isEmpty;
          bool assignedToMe = currentUserUid != null && asignadoA == currentUserUid;

          if (rol == "pasante 1") {
            return data["status"] == "Solicitado" && (unassigned || assignedToMe);
          }
          if (rol == "master" || rol == "masterFull" || rol == "coordinador 1" || rol == "coordinador 2") {
            return data["status"] == "Solicitado";
          }
          return false;
        }).length;

        // 🔹 Contar "Diligenciados" para estadísticas
        int countDiligenciado = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final asignadoA = data['asignadoA']?.toString().trim();
          final asignadoA_P2 = data['asignadoA_P2']?.toString().trim();
          bool assignedToMe = currentUserUid != null && asignadoA == currentUserUid;
          bool assignedToMeP2 = currentUserUid != null && asignadoA_P2 == currentUserUid;
          bool unassigned = asignadoA_P2 == null || asignadoA_P2.isEmpty;

          if (rol == "pasante 1") {
            // ✅ Cuenta los documentos que el pasante 1 diligenció (independientemente del estado actual)
            return assignedToMe && (data["status"] == "Diligenciado" || data["status"] == "Revisado" || data["status"] == "Enviado");
          }

          if (rol == "pasante 2") {
            return (data["status"] == "Diligenciado") && (assignedToMeP2 || unassigned);
          }

          if (rol == "master" || rol == "masterFull" || rol == "coordinador 1" || rol == "coordinador 2") {
            return data["status"] == "Diligenciado";
          }

          return false;
        }).length;

        // 🔹 Contar "Revisados" (Solo los ve quien está en asignadoA_P2)
        int countRevisado = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final asignadoA_P2 = data['asignadoA_P2']?.toString().trim();
          bool assignedToMeP2 = currentUserUid != null && asignadoA_P2 == currentUserUid;

          if (rol == "pasante 2") {
            return data["status"] == "Revisado" && assignedToMeP2;
          }
          if (rol == "master" || rol == "masterFull" || rol == "coordinador 1" || rol == "coordinador 2") {
            return data["status"] == "Revisado";
          }
          return false;
        }).length;

        // 🔹 Contar "Enviados" (Todos los pasantes 2 lo pueden ver)
        int countEnviado = docs.where((d) => d['status'] == 'Enviado').length;
        int countConcedido = docs.where((d) => d['status'] == 'Concedido').length;
        int countNegado = docs.where((d) => d['status'] == 'Negado').length;

        List<Widget> cards = [];

        if (role == "pasante 1") {
          cards.add(_buildEstadoCard("Solicitado", countSolicitado, Colors.brown));
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
        } else if (role == "pasante 2") {
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
          cards.add(_buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor));
          cards.add(_buildEstadoCard("Enviado", countEnviado, Colors.blue));
        } else {
          cards.add(_buildEstadoCard("Solicitado", countSolicitado, Colors.brown));
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
          cards.add(_buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor));
          cards.add(_buildEstadoCard("Enviado", countEnviado, Colors.blue));
          cards.add(_buildEstadoCard("Concedido", countConcedido, Colors.green));
          cards.add(_buildEstadoCard("Negado", countNegado, Colors.red));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: cards.map((card) {
                  return SizedBox(
                    width: constraints.maxWidth / 2 - 12,
                    child: card,
                  );
                }).toList(),
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: cards.map((card) {
                  return SizedBox(
                    width: 180,
                    child: card,
                  );
                }).toList(),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildEstadoCard(String estado, int count, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = estado; // 🔹 Se actualiza el estado para mostrar solo los documentos relacionados
        });
      },
      child: Card(
        elevation: _filtroEstado == estado ? 8 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Column(
            children: [
              Text(estado, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('$count', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 Widget para cada solicitud
  Widget _buildSolicitudCard(Map<String, dynamic> data, String idDocumento, String userRole) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    // 🔹 Obtener datos de asignación
    String? asignadoA = data['asignadoA']?.toString().trim();
    String? asignadoA_P2 = data['asignadoA_P2']?.toString().trim();
    Timestamp? fechaAsignado = data['asignado_fecha'];
    Timestamp? fechaAsignadoP2 = data['asignado_fecha_P2'];
    Timestamp? fechaRevisado = data['fecha_revision'];
    Timestamp? fechaEnviado = data['fechaEnvio'];

    // 🔹 Extraer preguntas y respuestas
    List<Map<String, dynamic>> preguntasRespuestas = data.containsKey('preguntas_respuestas')
        ? List<Map<String, dynamic>>.from(data['preguntas_respuestas'])
        : [];
    List<String> preguntas = preguntasRespuestas.map((e) => e['pregunta'].toString()).toList();
    List<String> respuestas = preguntasRespuestas.map((e) => e['respuesta'].toString()).toList();

    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Usuario no autenticado")),
          );
          return;
        }

        // 🔹 Obtener el rol desde AdminProvider
        String? userRole = AdminProvider().rol;

        // 🔹 Definir roles restringidos para la asignación
        List<String> rolesRestringidos = ["master", "masterFull", "coordinador 1", "coordinador 2"];

        // 🔹 Si el usuario está en la lista restringida, solo puede abrir el documento
        if (rolesRestringidos.contains(userRole)) {
          _navegarAPagina(data, idDocumento, preguntas, respuestas);
          return;
        }

        if (userRole == "pasante 1" && (asignadoA == null || asignadoA.isEmpty)) {
          try {
            await FirebaseFirestore.instance
                .collection('permiso_solicitados')
                .doc(idDocumento)
                .update({
              'asignadoA': user.uid,
              'asignado_fecha': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Solicitud asignada a ti")),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al asignar la solicitud: $error")),
              );
            }
            return;
          }
        }
        // 🔹 Si el usuario es pasante 2 y la solicitud no está asignada a ningún pasante 2, lo asignamos
        if (userRole == "pasante 2" && (asignadoA_P2 == null || asignadoA_P2.isEmpty)) {
          try {
            await FirebaseFirestore.instance
                .collection('permiso_solicitados')
                .doc(idDocumento)
                .update({
              'asignadoA_P2': user.uid,
              'asignado_para_revisar': adminFullName,
              'asignado_fecha_P2': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Solicitud asignada a ti")),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al asignar la solicitud: $error")),
              );
            }
            return;
          }
        } else if (userRole == "pasante 2" && asignadoA_P2 != user.uid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Esta solicitud ya está asignada a otro pasante 2")),
            );
          }
          return;
        }

        // 🔹 Navegar a la siguiente pantalla después de la asignación
        _navegarAPagina(data, idDocumento, preguntas, respuestas);
      },
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 5,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildSolicitudInfo(data),
              )
                  : Column(
                children: _buildSolicitudInfoDesktop(data),
              ),
              const SizedBox(height: 10),

              // 🔹 En Móvil, mostrar todo en Column
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAsignacionInfo("Asignado para diligenciar", asignadoA, fechaAsignado),
                    const SizedBox(height: 10),
                    _buildAsignacionInfo("Asignado para revisar", asignadoA_P2, fechaAsignadoP2),
                    const SizedBox(height: 10),
                    _buildFechaRevision("Revisado", fechaRevisado),
                    const SizedBox(height: 10),
                    _buildFechaEnvio("Enviado", fechaEnviado),
                    const SizedBox(height: 10),
                    if(data['status'] == "Enviado")
                      _buildTiempoSinRespuesta(fechaEnviado),
                  ],
                )
              else
                Column(
                  children: [
                    // 🔹 Primera Línea: Asignaciones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildAsignacionInfo("Asignado para diligenciar", asignadoA, fechaAsignado)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildAsignacionInfo("Asignado para revisar", asignadoA_P2, fechaAsignadoP2)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildFechaRevision("Revisado", fechaRevisado)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildFechaEnvio("Enviado", fechaEnviado)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if(data['status'] == "Enviado")
                      _buildTiempoSinRespuesta(fechaEnviado),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Calcula el tiempo sin respuesta y muestra un mensaje si ha pasado el límite.
  Widget _buildTiempoSinRespuesta(Timestamp? fechaEnvio) {
    if (fechaEnvio == null) return const SizedBox(); // No mostrar nada si no hay fecha de envío

    return FutureBuilder<int>(
      future: _obtenerTiempoPermitido(), // 🔥 Obtener el tiempo permitido desde Firestore
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator(); // Esperar carga

        int tiempoPermitido = snapshot.data!;
        DateTime fechaEnvioDT = fechaEnvio.toDate();

        // 🔥 Stream que actualiza el contador cada segundo
        return StreamBuilder<int>(
          stream: Stream.periodic(const Duration(seconds: 1), (_) {
            DateTime fechaActual = DateTime.now();
            return fechaActual.difference(fechaEnvioDT).inDays;
          }),
          builder: (context, streamSnapshot) {
            if (!streamSnapshot.hasData) return const SizedBox();

            int diasTranscurridos = streamSnapshot.data!;
            int diasRestantes = tiempoPermitido - diasTranscurridos;

            return Row(
              children: [
                Icon(
                  diasRestantes >= 0 ? Icons.timer_outlined : Icons.warning_amber_rounded,
                  color: diasRestantes >= 0 ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Text(
                  diasRestantes >= 0
                      ? "Tiempo límite restante para recibir respuesta: $diasRestantes días"
                      : "Sin obtener respuesta (${diasTranscurridos} días)",
                  style: TextStyle(
                    color: diasRestantes >= 0 ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔹 Obtiene el tiempo permitido desde Firestore
  Future<int> _obtenerTiempoPermitido() async {
    try {
      // 🔹 Obtener el primer documento (con ID aleatorio) de la colección "configuraciones"
      QuerySnapshot configCollection = await FirebaseFirestore.instance.collection("configuraciones").get();
      print("📁 Documentos encontrados en 'configuraciones': ${configCollection.docs.length}");

      if (configCollection.docs.isNotEmpty) {
        DocumentSnapshot configDoc = configCollection.docs.first;
        final data = configDoc.data() as Map<String, dynamic>;
        print("📄 Datos del primer documento: $data");

        // 🔥 Extraer el valor del tiempo de respuesta
        if (data.containsKey("tiempo_respuesta_permiso_72horas")) {
          final valor = (data["tiempo_respuesta_permiso_72horas"] as num).toInt();
          print("✅ Tiempo configurado: $valor días");
          return valor;
        } else {
          print("⚠️ Nodo 'tiempo_respuesta_permiso_72horas' no encontrado.");
        }
      }

      return 10; // 🔥 Valor por defecto si no hay documentos o no contiene el nodo
    } catch (e) {
      print("❌ Error al obtener tiempo permitido: $e");
      return 10; // En caso de error, devolver 10 días como predeterminado
    }
  }



  /// 🔹 Navegar a la página correspondiente
  void _navegarAPagina(Map<String, dynamic> latestData, String idDocumento, List<String> preguntas, List<String> respuestas) async {
    final String rutaDestino = obtenerRutaSegunStatus(latestData['status'] ?? "Pendiente");
    int tiempoPermitido = await _obtenerTiempoPermitido();
    DateTime fechaEnvio = latestData['fechaEnvio']?.toDate() ?? DateTime.now();
    DateTime fechaLimite = fechaEnvio.add(Duration(days: tiempoPermitido));
    bool sinRespuesta = DateTime.now().isAfter(fechaLimite);

    if (context.mounted) {
      Navigator.pushNamed(
        context,
        rutaDestino,
        arguments: {
          'status': latestData['status'] ?? "Pendiente",
          'idDocumento': idDocumento,
          'numeroSeguimiento': latestData['numero_seguimiento'] ?? "Sin número",
          'categoria': "Beneficios penitenciarios",
          'subcategoria': "Solicitud permiso de 72 horas",
          'fecha': latestData['fecha'] != null
              ? latestData['fecha'].toDate().toString()
              : "Fecha no disponible",
          'idUser': latestData['idUser'] ?? "Desconocido",
          'archivos': latestData.containsKey('archivos')
              ? List<String>.from(latestData['archivos'])
              : [],


          'urlArchivoCedulaResponsable': latestData['archivo_cedula_responsable'] ?? "",
          'urlsArchivosHijos': List<String>.from(latestData['documentos_hijos'] ?? []),

          // Datos del responsable
          'direccion': latestData['direccion'] ?? "",
          'departamento': latestData['departamento'] ?? "",
          'municipio': latestData['municipio'] ?? "",
          'nombreResponsable': latestData['nombre_responsable'] ?? "",
          'cedulaResponsable': latestData['cedula_responsable'] ?? "",
          'celularResponsable': latestData['celular_responsable'] ?? "",
          'parentesco': latestData['parentesco'] ?? "",
          'reparacion': latestData['reparacion'] ?? "",
          // Estado de la respuesta
          'sinRespuesta': sinRespuesta,
          // Si quieres incluir las preguntas y respuestas de IA (por si se usa luego)
          'preguntas': preguntas,
          'respuestas': respuestas,
        },
      );
    }
  }

  Widget _buildFechaRevision(String? titulo, Timestamp? fecha) {
    if (fecha == null) return const SizedBox(); // Si no hay fecha, no mostrar nada
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: primary.withOpacity(0.3),
      ),
      child: Row(
        children: [
          Text(
            "$titulo: ",
            style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 2),
          Text(
            DateFormat("dd/MM/yyyy hh:mm a", 'es').format(fecha.toDate()), // 📅 Formatear fecha
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFechaEnvio(String? titulo, Timestamp? fecha) {
    if (fecha == null) return const SizedBox(); // Si no hay fecha, no mostrar nada
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.withOpacity(0.3),
      ),
      child: Row(
        children: [
          Text(
            "$titulo: ",
            style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 2),
          Text(
            DateFormat("dd/MM/yyyy hh:mm a", 'es').format(fecha.toDate()), // 📅 Formatear fecha
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 🔹 Construir información de la solicitud
  List<Widget> _buildSolicitudInfo(Map<String, dynamic> data) {
    return [
      Row(
        children: [
          const Text("No. Seguimiento: ",
              style: TextStyle(fontSize: 12)),
          Text("${data['numero_seguimiento'] ?? 'Sin número'}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 5),
      FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Ppl')
            .doc(data['idUser']) // 🔹 Usamos el idUser que viene de la solicitud
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Cargando nombre...",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Text("Usuario no encontrado",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final nombreCompleto =
          "${userData['nombre_ppl'] ?? ''} ${userData['apellido_ppl'] ?? ''}".trim();

          return Text(
            nombreCompleto.isNotEmpty ? nombreCompleto : "Sin nombre",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          );
        },
      ),
      Text(
        DateFormat("dd 'de' MMMM 'de' yyyy - hh:mm a", 'es').format(data['fecha']?.toDate() ?? DateTime.now()),
        style: const TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 5),
      const Text("Categoría: Beneficios penitenciarios",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Row(
        children: [
          Icon(Icons.circle, size: 16, color: getColorEstado(data['status'] ?? "Pendiente")),
          const SizedBox(width: 5),
          Text(data['status'] ?? "Pendiente", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    ];
  }

  List<Widget> _buildSolicitudInfoDesktop(Map<String, dynamic> data) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Row(
                      children: [
                        Text("No. Seguimiento: ",
                            style: TextStyle(fontSize: 11)),
                      ],
                    ),
                    Expanded(
                      child: Text(
                        data['numero_seguimiento'] ?? 'Sin número',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.circle, size: 16, color: getColorEstado(data['status'] ?? "Pendiente")),
                  const SizedBox(width: 5),
                  Text(data['status'] ?? "Pendiente",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),

          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Ppl')
                .doc(data['idUser']) // 🔹 Usamos el idUser que viene de la solicitud
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Cargando nombre...",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("Usuario no encontrado",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final nombreCompleto =
              "${userData['nombre_ppl'] ?? ''} ${userData['apellido_ppl'] ?? ''}".trim();

              return Text(
                nombreCompleto.isNotEmpty ? nombreCompleto : "Sin nombre",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text("Fecha: ",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        DateFormat("dd 'de' MMMM 'de' yyyy - hh:mm a", 'es')
                            .format(data['fecha']?.toDate() ?? DateTime.now()),
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Row(
                  children: [
                    Text("Categoría: ",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        'Beneficios penitenciarios',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  /// 🔹 Construir información de asignación (Pasante 1 y Pasante 2)
  Widget _buildAsignacionInfo(String titulo, String? asignado, Timestamp? fecha) {
    if (asignado == null || asignado.trim().isEmpty) return const SizedBox();

    Color backgroundColor = _getAsignacionColor(titulo);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
      ),
      child: Row(
        children: [
          Text("$titulo: ", style: const TextStyle(fontSize: 12, color: negro, fontWeight: FontWeight.bold)),
          const SizedBox(width: 2),
          Text(
            fecha != null ? DateFormat("dd/MM/yyyy hh:mm a", 'es').format(fecha.toDate()) : "Fecha no disponible",
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 🔥 Función para asignar un color según el título de la asignación
  Color _getAsignacionColor(String titulo) {
    switch (titulo) {
      case "Asignado para diligenciar":
        return Colors.grey[100]!;  // Azul claro
      case "Asignado para revisar":
        return Colors.orange[50]!;
      case "Revisado":
        return Colors.purple[200]!;
      case "Asignado Coordinador":
        return Colors.purple[50]!; // Morado claro
      case "Asignado Master":
        return Colors.red[50]!; // Rojo claro
      default:
        return Colors.green[50]!; // Verde claro por defecto
    }
  }

  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "";
    return DateFormat(formato, 'es').format(fecha);
  }

  Color getColorEstado(String estado) {
    switch (estado) {
      case "Solicitado":
        return Colors.brown;
      case "Diligenciado":
        return Colors.amber;
      case "Revisado":
        return Colors.deepPurpleAccent; // Puedes cambiarlo por Theme.of(context).primaryColor si lo prefieres
      case "Enviado":
        return Colors.blue;
      case "Concedido":
        return Colors.green;
      case "Negado":
        return Colors.red;
      default:
        return Colors.grey; // Color por defecto si el estado no coincide
    }
  }

  String obtenerRutaSegunStatus(String status) {
    switch (status) {
      case "Enviado":
        return 'solicitudes_permiso_72_horas_enviadas_por_correo';
      case "Concedido":
        return 'solicitudes_permiso_72_horas_enviadas_por_correo';
      case "Negado":
        return 'solicitudes_permiso_72_horas_enviadas_por_correo';
      default:
        return 'atender_solicitud_permiso_72_horas_page';
    }
  }
}
