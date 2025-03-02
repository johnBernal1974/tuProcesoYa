import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/admin_provider.dart';
import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class SolicitudesDerechoPeticionAdminPage extends StatefulWidget {
  const SolicitudesDerechoPeticionAdminPage({super.key});

  @override
  State<SolicitudesDerechoPeticionAdminPage> createState() => _SolicitudesDerechoPeticionAdminPageState();
}

class _SolicitudesDerechoPeticionAdminPageState extends State<SolicitudesDerechoPeticionAdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String _filtroEstado = "Solicitado"; // Estado por defecto
  String rol = AdminProvider().rol ?? "";

  @override
  void initState() {
    super.initState();
    _loadAdminRole();
    // Otras inicializaciones, por ejemplo:
    // _fetchPendingSuggestions();
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
      pageTitle: 'Solicitudes de derecho de petición',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
          child: Column(
            children: [
              _buildEstadoCards(rol),
              const SizedBox(height: 50),
              Expanded(
                child:StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('derechos_peticion_solicitados')
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No hay solicitudes de derecho de petición.",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      );
                    }

                    // Obtener el usuario actual
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final currentUserUid = currentUser?.uid;

                    var filteredDocs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final asignadoA = data['asignadoA'];
                      bool unassigned = asignadoA == null || asignadoA.toString().trim().isEmpty;
                      bool assignedToMe = currentUserUid != null && asignadoA.toString().trim() == currentUserUid;

                      if (rol == "master" || rol == "masterFull" || rol == "coordinador 1" || rol == "coordinador 2") {
                        // 🔹 Estos roles ven TODO sin importar asignaciones
                        return data["status"] == _filtroEstado;
                      }

                      return (unassigned || assignedToMe) && (data["status"] == _filtroEstado);
                    }).toList();

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
      stream: firestore.collection('derechos_peticion_solicitados').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        var docs = snapshot.data!.docs;
        String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
        bool isMobile = MediaQuery.of(context).size.width < 600; // Detecta si es móvil

        // 🔹 Contar "Solicitados"
        int countSolicitado;
        if (role == "pasante 1") {
          countSolicitado = docs.where((d) {
            if (d['status'] != 'Solicitado') return false;
            var asignadoA = d['asignadoA'];
            bool unassigned = asignadoA == null || asignadoA.toString().trim().isEmpty;
            bool assignedToMe = currentUserUid != null && asignadoA.toString().trim() == currentUserUid;
            return unassigned || assignedToMe;
          }).length;
        } else if (role == "pasante 2") {
          countSolicitado = 0;
        } else {
          countSolicitado = docs.where((d) => d['status'] == 'Solicitado').length;
        }

        // 🔹 Contar "Diligenciados"
        int countDiligenciado = 0;
        if (role == "pasante 1") {
          countDiligenciado = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            if (data['status'] != 'Diligenciado') return false;
            var asignadoA = data['asignadoA']?.toString().trim();
            return asignadoA == currentUserUid;
          }).length;
        } else {
          countDiligenciado = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['status'] == 'Diligenciado';
          }).length;
        }

        int countRevisado = docs.where((d) => d['status'] == 'Revisado').length;
        int countEnviado = docs.where((d) => d['status'] == 'Enviado').length;

        List<Widget> cards = [];

        if (role == "pasante 1") {
          cards.add(_buildEstadoCard("Solicitado", countSolicitado, Colors.red));
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
        } else if (role == "pasante 2") {
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
          cards.add(_buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor));
          cards.add(_buildEstadoCard("Enviado", countEnviado, Colors.green));
        } else {
          cards.add(_buildEstadoCard("Solicitado", countSolicitado, Colors.red));
          cards.add(_buildEstadoCard("Diligenciado", countDiligenciado, Colors.amber));
          cards.add(_buildEstadoCard("Revisado", countRevisado, Theme.of(context).primaryColor));
          cards.add(_buildEstadoCard("Enviado", countEnviado, Colors.green));
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
                    width: constraints.maxWidth / 2 - 12, // Divide el ancho en 2 columnas
                    child: card,
                  );
                }).toList(),
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: cards.map((card) {
                  return SizedBox(
                    width: 180, // Ancho fijo en PC
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

  // 🔥 Widget para cada tarjeta de estado
  Widget _buildEstadoCard(String estado, int count, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = estado;
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
    bool isMobile = MediaQuery.of(context).size.width < 600; // Detectar si es móvil

    // Extraer preguntas y respuestas
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

        // 🔹 Obtener la solicitud más reciente de Firestore
        DocumentSnapshot docSnap = await FirebaseFirestore.instance
            .collection('derechos_peticion_solicitados')
            .doc(idDocumento)
            .get();

        if (!docSnap.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Documento no encontrado.")),
          );
          return;
        }

        Map<String, dynamic>? latestData = docSnap.data() as Map<String, dynamic>?;

        if (latestData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al obtener datos.")),
          );
          return;
        }

        // 🔹 Verificar si la solicitud ya está asignada
        String? asignadoA = latestData.containsKey('asignadoA') ? latestData['asignadoA']?.toString().trim() : null;

        if (asignadoA == null || asignadoA.isEmpty) {
          try {
            // 🔥 Asignar la solicitud al usuario actual
            await FirebaseFirestore.instance
                .collection('derechos_peticion_solicitados')
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
        } else {
          if (asignadoA != user.uid) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Esta solicitud ya está asignada a otro usuario")),
              );
            }
            return;
          }
        }

        // 🔹 Navegar a la siguiente pantalla después de la asignación
        if (context.mounted) {
          Navigator.pushNamed(
            context,
            obtenerRutaSegunStatus(latestData['status']),
            arguments: {
              'status': latestData['status'],
              'idDocumento': idDocumento,
              'numeroSeguimiento': latestData['numero_seguimiento'],
              'categoria': latestData['categoria'],
              'subcategoria': latestData['subcategoria'],
              'fecha': latestData['fecha'].toDate().toString(),
              'idUser': latestData['idUser'],
              'archivos': latestData.containsKey('archivos') ? List<String>.from(latestData['archivos']) : [],
              'preguntas': preguntas,
              'respuestas': respuestas,
            },
          );
        }
      },
      child: Card(
        color: blancoCards,
        elevation: 5,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile
                  ? Column( // 📱 En móviles, todo en columna
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("No. Seguimiento: ${data['numero_seguimiento']}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat("dd 'de' MMMM 'de' yyyy - hh:mm a", 'es').format(data['fecha'].toDate()),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text("Categoría: ${data['categoria']}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 16, color: getColorEstado(data['status'])),
                      const SizedBox(width: 5),
                      Text(data['status'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              )
                  : Column( // 💻 En PC, se mantiene la estructura original con todo
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("No. Seguimiento: ${data['numero_seguimiento']}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(
                        DateFormat("dd 'de' MMMM 'de' yyyy - hh:mm a", 'es').format(data['fecha'].toDate()),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Categoría: ${data['categoria']}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 16, color: getColorEstado(data['status'])),
                          const SizedBox(width: 5),
                          Text(data['status'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (data['asignado_fecha'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green[50],
                  ),
                  child: MediaQuery.of(context).size.width < 600
                      ? Column( // 📱 En móviles, mostrar en columna
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Asignado: ",
                        style: TextStyle(fontSize: 12, color: gris, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.containsKey('asignadoA') &&
                            data['asignadoA'] != null &&
                            data['asignadoA'].toString().trim().isNotEmpty
                            ? " ${data.containsKey('asignado_fecha') && data['asignado_fecha'] != null ? _formatFecha((data['asignado_fecha'] as Timestamp).toDate()) : "Fecha no disponible"}"
                            : "No asignado",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                      : Row( // 💻 En PC, mantener en una fila
                    children: [
                      const Text(
                        "Asignado: ",
                        style: TextStyle(fontSize: 14, color: negro, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data.containsKey('asignadoA') &&
                            data['asignadoA'] != null &&
                            data['asignadoA'].toString().trim().isNotEmpty
                            ? " ${data.containsKey('asignado_fecha') && data['asignado_fecha'] != null ? _formatFecha((data['asignado_fecha'] as Timestamp).toDate()) : "Fecha no disponible"}"
                            : "No asignado",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  String _formatFecha(DateTime? fecha, {String formato = "dd 'de' MMMM 'de' yyyy - hh:mm a"}) {
    if (fecha == null) return "";
    return DateFormat(formato, 'es').format(fecha);
  }

  Color getColorEstado(String estado) {
    switch (estado) {
      case "Solicitado":
        return Colors.red;
      case "Diligenciado":
        return Colors.amber;
      case "Revisado":
        return Colors.deepPurpleAccent; // Puedes cambiarlo por Theme.of(context).primaryColor si lo prefieres
      case "Enviado":
        return Colors.green;
      default:
        return Colors.grey; // Color por defecto si el estado no coincide
    }
  }

  String obtenerRutaSegunStatus(String status) {
    switch (status) {
      case "Enviado":
        return 'derechos_peticion_enviados_por_correo';
      default:
        return 'atender_derecho_peticion_page';
    }
  }
}
