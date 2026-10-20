
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../commons/admin_provider.dart';
import '../../../../commons/main_layaout.dart';
import '../../../../src/colors/colors.dart';

class HistorialSolicitudesAsignacionTEEAdminPage extends StatefulWidget {
  const HistorialSolicitudesAsignacionTEEAdminPage({super.key});

  @override
  State<HistorialSolicitudesAsignacionTEEAdminPage> createState() =>
      _HistorialSolicitudesAsignacionTEEAdminPageState();
}

class _HistorialSolicitudesAsignacionTEEAdminPageState
    extends State<HistorialSolicitudesAsignacionTEEAdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static const String _coleccion = 'asignacionTEE_solicitados';
  static const String _rutaAtender = 'atender_asignacion_tee_page';

  String _filtroEstado = 'Solicitado';
  String rol = AdminProvider().rol ?? '';
  String adminFullName = '';

  @override
  void initState() {
    super.initState();
    adminFullName = AdminProvider().adminFullName ?? '';
    _loadAdminRole();
  }

  Future<void> _loadAdminRole() async {
    await AdminProvider().loadAdminData();

    if (!mounted) return;

    setState(() {
      rol = AdminProvider().rol ?? '';
      adminFullName = AdminProvider().adminFullName ?? '';

      if (rol == 'pasante 2') {
        _filtroEstado = 'Diligenciado';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Solicitudes de asignación TEE',
      content: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width >= 1000
              ? 1200
              : double.infinity,
          child: Column(
            children: [
              _buildEstadoCards(),
              const SizedBox(height: 30),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection(_coleccion)
                      .orderBy('fecha', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar solicitudes: ${snapshot.error}',
                        ),
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay solicitudes de asignación TEE.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final currentUserUid =
                        FirebaseAuth.instance.currentUser?.uid;

                    final filteredDocs =
                    snapshot.data!.docs.where((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;

                      final asignadoA =
                      data['asignadoA']?.toString().trim();

                      final asignadoA_P2 =
                      data['asignadoA_P2']?.toString().trim();

                      final assignedToMe =
                          currentUserUid != null &&
                              asignadoA == currentUserUid;

                      final assignedToMeP2 =
                          currentUserUid != null &&
                              asignadoA_P2 == currentUserUid;

                      final unassignedP2 =
                          asignadoA_P2 == null ||
                              asignadoA_P2.isEmpty;

                      final status = data['status'];

                      if (_esAdministrador(rol)) {
                        return status == _filtroEstado;
                      }

                      if (rol == 'pasante 1') {
                        if (_filtroEstado == 'Solicitado') {
                          return (asignadoA == null ||
                              asignadoA.isEmpty ||
                              assignedToMe) &&
                              status == 'Solicitado';
                        }

                        if (_filtroEstado == 'Diligenciado') {
                          return assignedToMe &&
                              (status == 'Diligenciado' ||
                                  status == 'Revisado' ||
                                  status == 'Enviado');
                        }
                      }

                      if (rol == 'pasante 2') {
                        if (_filtroEstado == 'Diligenciado') {
                          return status == 'Diligenciado' &&
                              (assignedToMeP2 || unassignedP2);
                        }

                        if (_filtroEstado == 'Revisado') {
                          return status == 'Revisado' &&
                              assignedToMeP2;
                        }

                        if (_filtroEstado == 'Enviado') {
                          return status == 'Enviado';
                        }
                      }

                      return false;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No hay documentos en estado $_filtroEstado.',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final document = filteredDocs[index];
                        final data =
                        document.data() as Map<String, dynamic>;

                        return _buildSolicitudCard(
                          data,
                          document.id,
                          rol,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _esAdministrador(String role) {
    return role == 'master' ||
        role == 'masterFull' ||
        role == 'coordinador 1' ||
        role == 'coordinador 2';
  }

  Widget _buildEstadoCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection(_coleccion).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;
        final currentUserUid =
            FirebaseAuth.instance.currentUser?.uid;

        final isMobile =
            MediaQuery.of(context).size.width < 600;

        final countSolicitado = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final asignadoA =
          data['asignadoA']?.toString().trim();

          final unassigned =
              asignadoA == null || asignadoA.isEmpty;

          final assignedToMe =
              currentUserUid != null &&
                  asignadoA == currentUserUid;

          if (rol == 'pasante 1') {
            return data['status'] == 'Solicitado' &&
                (unassigned || assignedToMe);
          }

          if (_esAdministrador(rol)) {
            return data['status'] == 'Solicitado';
          }

          return false;
        }).length;

        final countDiligenciado = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final asignadoA =
          data['asignadoA']?.toString().trim();

          final asignadoA_P2 =
          data['asignadoA_P2']?.toString().trim();

          final assignedToMe =
              currentUserUid != null &&
                  asignadoA == currentUserUid;

          final assignedToMeP2 =
              currentUserUid != null &&
                  asignadoA_P2 == currentUserUid;

          final unassignedP2 =
              asignadoA_P2 == null ||
                  asignadoA_P2.isEmpty;

          if (rol == 'pasante 1') {
            return assignedToMe &&
                (data['status'] == 'Diligenciado' ||
                    data['status'] == 'Revisado' ||
                    data['status'] == 'Enviado');
          }

          if (rol == 'pasante 2') {
            return data['status'] == 'Diligenciado' &&
                (assignedToMeP2 || unassignedP2);
          }

          if (_esAdministrador(rol)) {
            return data['status'] == 'Diligenciado';
          }

          return false;
        }).length;

        final countRevisado = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final asignadoA_P2 =
          data['asignadoA_P2']?.toString().trim();

          final assignedToMeP2 =
              currentUserUid != null &&
                  asignadoA_P2 == currentUserUid;

          if (rol == 'pasante 2') {
            return data['status'] == 'Revisado' &&
                assignedToMeP2;
          }

          if (_esAdministrador(rol)) {
            return data['status'] == 'Revisado';
          }

          return false;
        }).length;

        final countEnviado = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Enviado';
        }).length;

        final countConcedido = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Concedido';
        }).length;

        final countNegado = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Negado';
        }).length;

        final List<Widget> cards = [];

        if (rol == 'pasante 1') {
          cards.add(
            _buildEstadoCard(
              'Solicitado',
              countSolicitado,
              Colors.brown,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Diligenciado',
              countDiligenciado,
              Colors.amber,
            ),
          );
        } else if (rol == 'pasante 2') {
          cards.add(
            _buildEstadoCard(
              'Diligenciado',
              countDiligenciado,
              Colors.amber,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Revisado',
              countRevisado,
              Theme.of(context).primaryColor,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Enviado',
              countEnviado,
              Colors.blue,
            ),
          );
        } else {
          cards.add(
            _buildEstadoCard(
              'Solicitado',
              countSolicitado,
              Colors.brown,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Diligenciado',
              countDiligenciado,
              Colors.amber,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Revisado',
              countRevisado,
              Theme.of(context).primaryColor,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Enviado',
              countEnviado,
              Colors.blue,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Concedido',
              countConcedido,
              Colors.green,
            ),
          );
          cards.add(
            _buildEstadoCard(
              'Negado',
              countNegado,
              Colors.red,
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: cards.map((card) {
                  return SizedBox(
                    width: constraints.maxWidth / 2 - 12,
                    child: card,
                  );
                }).toList(),
              );
            }

            return Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: cards.map((card) {
                return SizedBox(
                  width: 180,
                  child: card,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildEstadoCard(
      String estado,
      int count,
      Color color,
      ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = estado;
        });
      },
      child: Card(
        elevation: _filtroEstado == estado ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 20,
          ),
          child: Column(
            children: [
              Text(
                estado,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(
      Map<String, dynamic> data,
      String idDocumento,
      String userRole,
      ) {
    final isMobile =
        MediaQuery.of(context).size.width < 600;

    final asignadoA =
    data['asignadoA']?.toString().trim();

    final asignadoA_P2 =
    data['asignadoA_P2']?.toString().trim();

    final fechaAsignado =
    data['asignado_fecha'] is Timestamp
        ? data['asignado_fecha'] as Timestamp
        : null;

    final fechaAsignadoP2 =
    data['asignado_fecha_P2'] is Timestamp
        ? data['asignado_fecha_P2'] as Timestamp
        : null;

    final fechaRevisado =
    data['fecha_revision'] is Timestamp
        ? data['fecha_revision'] as Timestamp
        : null;

    final fechaEnviado =
    data['fechaEnvio'] is Timestamp
        ? data['fechaEnvio'] as Timestamp
        : null;

    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no autenticado'),
            ),
          );
          return;
        }

        if (_esAdministrador(userRole)) {
          _navegarAPagina(data, idDocumento);
          return;
        }

        if (userRole == 'pasante 1' &&
            (asignadoA == null || asignadoA.isEmpty)) {
          try {
            await firestore
                .collection(_coleccion)
                .doc(idDocumento)
                .update({
              'asignadoA': user.uid,
              'asignado_fecha':
              FieldValue.serverTimestamp(),
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solicitud asignada a ti'),
              ),
            );
          } catch (error) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al asignar la solicitud: $error',
                ),
              ),
            );
            return;
          }
        }

        if (userRole == 'pasante 2' &&
            (asignadoA_P2 == null ||
                asignadoA_P2.isEmpty)) {
          try {
            await firestore
                .collection(_coleccion)
                .doc(idDocumento)
                .update({
              'asignadoA_P2': user.uid,
              'asignado_para_revisar': adminFullName,
              'asignado_fecha_P2':
              FieldValue.serverTimestamp(),
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Solicitud asignada a ti'),
              ),
            );
          } catch (error) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error al asignar la solicitud: $error',
                ),
              ),
            );
            return;
          }
        } else if (userRole == 'pasante 2' &&
            asignadoA_P2 != user.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Esta solicitud ya está asignada a otro pasante 2',
              ),
            ),
          );
          return;
        }

        if (!mounted) return;

        _navegarAPagina(data, idDocumento);
      },
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 5,
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              if (isMobile)
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: _buildSolicitudInfo(data),
                )
              else
                Column(
                  children:
                  _buildSolicitudInfoDesktop(data),
                ),
              const SizedBox(height: 10),
              if (isMobile)
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _buildAsignacionInfo(
                      'Asignado para diligenciar',
                      asignadoA,
                      fechaAsignado,
                    ),
                    const SizedBox(height: 10),
                    _buildAsignacionInfo(
                      'Asignado para revisar',
                      asignadoA_P2,
                      fechaAsignadoP2,
                    ),
                    const SizedBox(height: 10),
                    _buildFechaInfo(
                      'Revisado',
                      fechaRevisado,
                      primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 10),
                    _buildFechaInfo(
                      'Enviado',
                      fechaEnviado,
                      Colors.green.withOpacity(0.3),
                    ),
                    if (data['status'] == 'Enviado')
                      _buildTiempoSinRespuesta(
                        fechaEnviado,
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildAsignacionInfo(
                            'Asignado para diligenciar',
                            asignadoA,
                            fechaAsignado,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildAsignacionInfo(
                            'Asignado para revisar',
                            asignadoA_P2,
                            fechaAsignadoP2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildFechaInfo(
                            'Revisado',
                            fechaRevisado,
                            primary.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildFechaInfo(
                            'Enviado',
                            fechaEnviado,
                            Colors.green.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                    if (data['status'] == 'Enviado')
                      _buildTiempoSinRespuesta(
                        fechaEnviado,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTiempoSinRespuesta(
      Timestamp? fechaEnvio,
      ) {
    if (fechaEnvio == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<int>(
      future: _obtenerTiempoPermitido(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final tiempoPermitido = snapshot.data!;
        final fechaEnvioDT = fechaEnvio.toDate();

        return StreamBuilder<int>(
          stream: Stream.periodic(
            const Duration(seconds: 1),
                (_) => DateTime.now()
                .difference(fechaEnvioDT)
                .inDays,
          ),
          builder: (context, streamSnapshot) {
            if (!streamSnapshot.hasData) {
              return const SizedBox.shrink();
            }

            final diasTranscurridos =
            streamSnapshot.data!;

            final diasRestantes =
                tiempoPermitido - diasTranscurridos;

            return Row(
              children: [
                Icon(
                  diasRestantes >= 0
                      ? Icons.timer_outlined
                      : Icons.warning_amber_rounded,
                  color: diasRestantes >= 0
                      ? Colors.green
                      : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    diasRestantes >= 0
                        ? 'Tiempo límite restante para recibir respuesta: $diasRestantes días'
                        : 'Sin obtener respuesta ($diasTranscurridos días)',
                    style: TextStyle(
                      color: diasRestantes >= 0
                          ? Colors.green
                          : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int> _obtenerTiempoPermitido() async {
    try {
      final configCollection = await firestore
          .collection('configuraciones')
          .get();

      if (configCollection.docs.isNotEmpty) {
        final data = configCollection.docs.first.data();

        if (data['tiempo_respuesta_redenciones']
        is num) {
          return (data['tiempo_respuesta_redenciones']
          as num)
              .toInt();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Error consultando tiempo de respuesta: $e',
        );
      }
    }

    return 10;
  }

  void _navegarAPagina(
      Map<String, dynamic> data,
      String idDocumento,
      ) async {
    final fechaEnvio = data['fechaEnvio'] is Timestamp
        ? (data['fechaEnvio'] as Timestamp).toDate()
        : DateTime.now();

    final tiempoPermitido =
    await _obtenerTiempoPermitido();

    final fechaLimite = fechaEnvio.add(
      Duration(days: tiempoPermitido),
    );

    final sinRespuesta =
    DateTime.now().isAfter(fechaLimite);

    final fecha = data['fecha'] is Timestamp
        ? (data['fecha'] as Timestamp)
        .toDate()
        .toString()
        : 'Fecha no disponible';

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      _rutaAtender,
      arguments: {
        'status': data['status'] ?? 'Solicitado',
        'idDocumento': idDocumento,
        'numeroSeguimiento':
        data['numero_seguimiento'] ??
            'Sin número',
        'categoria': 'Solicitudes varias',
        'subcategoria': 'Solicitud Asignación TEE',
        'fecha': fecha,
        'idUser': data['idUser'] ?? '',
        'sinRespuesta': sinRespuesta,
      },
    );
  }

  Widget _buildFechaInfo(
      String titulo,
      Timestamp? fecha,
      Color color,
      ) {
    if (fecha == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
      ),
      child: Row(
        children: [
          Text(
            '$titulo: ',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat(
              'dd/MM/yyyy hh:mm a',
              'es',
            ).format(fecha.toDate()),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSolicitudInfo(
      Map<String, dynamic> data,
      ) {
    return [
      Row(
        children: [
          const Text(
            'No. Seguimiento: ',
            style: TextStyle(fontSize: 12),
          ),
          Flexible(
            child: Text(
              '${data['numero_seguimiento'] ?? 'Sin número'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      _buildNombrePpl(data),
      const SizedBox(height: 5),
      Text(
        _formatearFechaSolicitud(data['fecha']),
        style: const TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 5),
      const Text(
        'Categoría: Solicitudes varias',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          Icon(
            Icons.circle,
            size: 16,
            color: getColorEstado(
              data['status'] ?? 'Pendiente',
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${data['status'] ?? 'Pendiente'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSolicitudInfoDesktop(
      Map<String, dynamic> data,
      ) {
    return [
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'No. Seguimiento: ',
                      style: TextStyle(fontSize: 11),
                    ),
                    Expanded(
                      child: Text(
                        '${data['numero_seguimiento'] ?? 'Sin número'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 16,
                    color: getColorEstado(
                      data['status'] ?? 'Pendiente',
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${data['status'] ?? 'Pendiente'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          _buildNombrePpl(data),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Fecha: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatearFechaSolicitud(
                          data['fecha'],
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Row(
                  children: [
                    Text(
                      'Categoría: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Solicitudes varias',
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

  Widget _buildNombrePpl(
      Map<String, dynamic> data,
      ) {
    final idUser = data['idUser']?.toString() ?? '';

    if (idUser.isEmpty) {
      return const Text('Usuario no identificado');
    }

    return FutureBuilder<DocumentSnapshot>(
      future: firestore
          .collection('Ppl')
          .doc(idUser)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Text('Cargando nombre...');
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Text('Usuario no encontrado');
        }

        final userData =
        snapshot.data!.data() as Map<String, dynamic>;

        final nombreCompleto =
        '${userData['nombre_ppl'] ?? ''} ${userData['apellido_ppl'] ?? ''}'
            .trim();

        return Text(
          nombreCompleto.isNotEmpty
              ? nombreCompleto
              : 'Sin nombre',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
      },
    );
  }

  String _formatearFechaSolicitud(dynamic fecha) {
    DateTime? fechaDate;

    if (fecha is Timestamp) {
      fechaDate = fecha.toDate();
    } else if (fecha is DateTime) {
      fechaDate = fecha;
    } else if (fecha is String) {
      fechaDate = DateTime.tryParse(fecha);
    }

    if (fechaDate == null) {
      return 'Fecha no disponible';
    }

    return DateFormat(
      "dd 'de' MMMM 'de' yyyy - hh:mm a",
      'es',
    ).format(fechaDate);
  }

  Widget _buildAsignacionInfo(
      String titulo,
      String? asignado,
      Timestamp? fecha,
      ) {
    if (asignado == null ||
        asignado.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _getAsignacionColor(titulo),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$titulo: ',
              style: const TextStyle(
                fontSize: 12,
                color: negro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            fecha != null
                ? DateFormat(
              'dd/MM/yyyy hh:mm a',
              'es',
            ).format(fecha.toDate())
                : 'Fecha no disponible',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAsignacionColor(String titulo) {
    switch (titulo) {
      case 'Asignado para diligenciar':
        return Colors.grey[100]!;
      case 'Asignado para revisar':
        return Colors.orange[50]!;
      default:
        return Colors.green[50]!;
    }
  }

  Color getColorEstado(String estado) {
    switch (estado) {
      case 'Solicitado':
        return Colors.brown;
      case 'Diligenciado':
        return Colors.amber;
      case 'Revisado':
        return Colors.deepPurpleAccent;
      case 'Enviado':
        return Colors.blue;
      case 'Concedido':
        return Colors.green;
      case 'Negado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
