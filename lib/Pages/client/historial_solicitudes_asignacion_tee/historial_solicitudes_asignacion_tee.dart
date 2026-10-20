
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

import '../../../commons/main_layaout.dart';
import '../../../providers/auth_provider.dart';
import '../../../src/colors/colors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class HistorialSolicitudesAsignacionTEEPage extends StatefulWidget {
  const HistorialSolicitudesAsignacionTEEPage({super.key});

  @override
  State<HistorialSolicitudesAsignacionTEEPage> createState() =>
      _HistorialSolicitudesAsignacionTEEPageState();
}

class _HistorialSolicitudesAsignacionTEEPageState
    extends State<HistorialSolicitudesAsignacionTEEPage> {
  final MyAuthProvider _authProvider = MyAuthProvider();

  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = _authProvider.getUser();

    if (!mounted) return;

    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _fetchSolicitudes() {
    if (_userId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('asignacionTEE_solicitados')
        .where('idUser', isEqualTo: _userId)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Historial asignación de cursos TEE',
      content: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal:
            MediaQuery.of(context).size.width < 600 ? 2 : 0,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width >= 1000
                ? 600
                : double.infinity,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _fetchSolicitudes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint('❌ ERROR FIRESTORE ASIGNACIÓN TEE: ${snapshot.error}');

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SelectableText(
                        'Error al cargar las solicitudes TEE:\n\n${snapshot.error}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay solicitudes registradas.'),
                  );
                }

                final solicitudes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = solicitudes[index];

                    return _buildSolicitudCard(
                      solicitud.id,
                      solicitud.data(),
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

  Future<void> _abrirPdf(String path) async {
    try {
      final url = await FirebaseStorage.instance
          .ref(path)
          .getDownloadURL();

      final abierto = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!abierto) {
        throw Exception('No se pudo abrir el documento.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildDocumentosTEE(Map<String, dynamic> data) {
    final documentos = <Map<String, String>>[];

    final poderPath = (data['poderPdfPath'] ?? '').toString();
    final poderNombre =
    (data['poderPdfNombre'] ?? 'Poder.pdf').toString();

    final documentosAbogadoPath =
    (data['documentosAbogadoPdfPath'] ?? '').toString();

    final documentosAbogadoNombre =
    (data['documentosAbogadoPdfNombre'] ??
        'Documentos del abogado.pdf')
        .toString();

    if (poderPath.isNotEmpty) {
      documentos.add({
        'titulo': 'Poder',
        'nombre': poderNombre,
        'path': poderPath,
      });
    }

    if (documentosAbogadoPath.isNotEmpty) {
      documentos.add({
        'titulo': 'Documentos del abogado',
        'nombre': documentosAbogadoNombre,
        'path': documentosAbogadoPath,
      });
    }

    if (documentos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Documentos adjuntos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),

        ...documentos.map((documento) {
          return Card(
            color: Colors.grey.shade50,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 30,
              ),
              title: Text(
                documento['titulo']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                documento['nombre']!,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.visibility_outlined,
                color: primary,
              ),
              onTap: () => _abrirPdf(documento['path']!),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSolicitudCard(
      String idDocumento,
      Map<String, dynamic> data,
      ) {
    final status = (data['status'] ?? 'Solicitado').toString();

    final fecha = data['fecha'];
    String fechaTexto = 'Sin fecha';

    if (fecha is Timestamp) {
      fechaTexto = DateFormat(
        "d 'de' MMMM 'de' y",
        'es',
      ).format(fecha.toDate());
    } else if (fecha is String) {
      final fechaConvertida = DateTime.tryParse(fecha);

      if (fechaConvertida != null) {
        fechaTexto = DateFormat(
          "d 'de' MMMM 'de' y",
          'es',
        ).format(fechaConvertida);
      }
    }

    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      margin: const EdgeInsets.symmetric(
        vertical: 5,
        horizontal: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _colorFondoEstado(status),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconoEstado(status),
                    size: 18,
                    color: _colorEstado(status),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mensajeEstado(status),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildDatoFila(
              'Número de seguimiento',
              (data['numero_seguimiento'] ?? 'N/A').toString(),
              destacado: true,
            ),
            _buildDatoFila(
              'Fecha de solicitud',
              fechaTexto,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // DOCUMENTOS PDF
                _buildDocumentosTEE(data),

                const SizedBox(height: 18),

                const Text(
                  'Informe de Diligencias realizadas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                _buildHistorialCorreos(idDocumento),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialCorreos(String idDocumento) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('asignacionTEE_solicitados')
          .doc(idDocumento)
          .collection('log_correos')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'No se pudo cargar el historial de correos.',
            style: TextStyle(fontSize: 12),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Text(
            'Aún no hay correos enviados a la autoridad competente '
                'para esta solicitud.',
            style: TextStyle(fontSize: 11),
          );
        }

        final correos = snapshot.data!.docs;

        return Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Estado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Fecha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Ver',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...correos.map((doc) {
                final correo = doc.data();

                final esRespuesta =
                    correo['esRespuesta'] == true ||
                        correo['EsRespuesta'] == true;

                final tipo = (correo['tipo'] ?? 'enviado')
                    .toString()
                    .toLowerCase()
                    .trim();

                final estado =
                esRespuesta ? 'respuesta' : tipo;

                final fecha =
                (correo['timestamp'] as Timestamp?)?.toDate();

                final fechaCorreo = fecha != null
                    ? DateFormat(
                  'dd/MM/yyyy - hh:mm a',
                  'es',
                ).format(fecha)
                    : 'Fecha no disponible';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _estadoConIcono(estado),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              fechaCorreo,
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: TextButton(
                              onPressed: () {
                                _mostrarContenidoCorreo(
                                  idDocumento,
                                  doc.id,
                                );
                              },
                              child: const Text(
                                'Ver el correo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarContenidoCorreo(
      String idDocumento,
      String correoId,
      ) async {
    try {
      final documento = await FirebaseFirestore.instance
          .collection('asignacionTEE_solicitados')
          .doc(idDocumento)
          .collection('log_correos')
          .doc(correoId)
          .get();

      if (!mounted) return;

      final datos = documento.data();

      if (datos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el correo.'),
          ),
        );
        return;
      }

      final html = (datos['html'] ?? '').toString();

      final asunto = (
          datos['subject'] ?? 'Contenido del correo'
      ).toString();

      if (html.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este correo no tiene contenido disponible.',
            ),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(asunto),
            content: SizedBox(
              width: 700,
              height:
              MediaQuery.of(dialogContext).size.height * 0.7,
              child: SingleChildScrollView(
                child: Html(data: html),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el correo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDatoFila(
      String titulo,
      String valor, {
        bool destacado = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: destacado ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFondoEstado(String status) {
    switch (status) {
      case 'Solicitado':
        return Colors.orange.shade50;
      case 'Diligenciado':
        return Colors.amber.shade50;
      case 'Revisado':
        return Colors.teal.shade50;
      case 'Enviado':
        return Colors.green.shade50;
      case 'Negado':
        return Colors.red.shade50;
      case 'Concedido':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _colorEstado(String status) {
    switch (status) {
      case 'Solicitado':
        return Colors.orange;
      case 'Diligenciado':
        return Colors.amber.shade700;
      case 'Revisado':
        return Colors.teal;
      case 'Enviado':
        return Colors.green;
      case 'Negado':
        return Colors.red;
      case 'Concedido':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _iconoEstado(String status) {
    switch (status) {
      case 'Solicitado':
        return Icons.assignment_outlined;
      case 'Diligenciado':
        return Icons.search;
      case 'Revisado':
        return Icons.check_circle_outline;
      case 'Enviado':
        return Icons.send_outlined;
      case 'Negado':
        return Icons.cancel;
      case 'Concedido':
        return Icons.verified;
      default:
        return Icons.help_outline;
    }
  }

  String _mensajeEstado(String status) {
    switch (status) {
      case 'Solicitado':
        return 'Hemos recibido tu solicitud';
      case 'Diligenciado':
        return 'Se está analizando tu solicitud';
      case 'Revisado':
        return 'Tu solicitud está lista para ser enviada';
      case 'Enviado':
        return 'Se ha enviado a la autoridad competente';
      case 'Negado':
        return 'ATENCIÓN: La autoridad competente ha negado esta solicitud';
      case 'Concedido':
        return 'FELICITACIONES: La autoridad ha concedido esta solicitud';
      default:
        return 'Estado desconocido';
    }
  }

  Widget _estadoConIcono(String estado) {
    late Icon icono;
    late String texto;

    switch (estado.toLowerCase().trim()) {
      case 'email.delivered':
        icono = const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        );
        texto = 'Entregado';
        break;

      case 'email.sent':
      case 'enviado':
        icono = const Icon(
          Icons.send,
          color: Colors.green,
          size: 16,
        );
        texto = 'Enviado';
        break;

      case 'email.bounced':
        icono = const Icon(
          Icons.error,
          color: Colors.red,
          size: 16,
        );
        texto = 'Rebotado';
        break;

      case 'respuesta':
        icono = const Icon(
          Icons.mark_email_read,
          color: Colors.deepPurple,
          size: 16,
        );
        texto = 'Respuesta';
        break;

      case 'recibido':
        icono = const Icon(
          Icons.inbox,
          color: Colors.orange,
          size: 16,
        );
        texto = 'Correo recibido';
        break;

      default:
        icono = const Icon(
          Icons.help_outline,
          color: Colors.grey,
          size: 16,
        );
        texto = estado;
    }

    return Row(
      children: [
        icono,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
