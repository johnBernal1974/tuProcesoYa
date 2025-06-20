import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/colors/colors.dart';
import '../widgets/email_status_widget.dart';

class ResumenSolicitudesWidget extends StatefulWidget {
  final String idPpl;
  final bool mostrarCorreos;

  const ResumenSolicitudesWidget({
    super.key,
    required this.idPpl,
    this.mostrarCorreos = false,
  });

  @override
  State<ResumenSolicitudesWidget> createState() => _ResumenSolicitudesWidgetState();
}

class _ResumenSolicitudesWidgetState extends State<ResumenSolicitudesWidget> {

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('solicitudes_usuario')
          .where('idUser', isEqualTo: widget.idPpl)
          .orderBy('fecha', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No hay solicitudes registradas.");
        }

        final solicitudes = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: solicitudes.length,
          itemBuilder: (context, index) {
            final doc = solicitudes[index];
            final tipo = doc['tipo'] ?? 'Sin tipo';
            final numero = doc['numeroSeguimiento'] ?? '—';
            final estadoRaw = doc['status'] ?? '—';
            final estilo = _obtenerEstiloEstado(estadoRaw);
            final origen = doc['origen'] ?? '';
            final idOriginal = doc['idOriginal'] ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  surfaceTintColor: blanco,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: estilo['color'],
                      child: Icon(estilo['icon'], color: Colors.white),
                    ),
                    title: Text(
                      tipo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Seguimiento: $numero", style: const TextStyle(fontSize: 11)),
                        Text("Estado: ${estilo['texto']}", style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      showDialog(
                        context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: blanco,
                            title: const Text("Correos de la solicitud"),
                            content: SizedBox(
                              width: 600,
                              height: 300,
                              child: Scrollbar( // 🔹 Añadido scrollbar para mejor UX
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  child: ListaCorreosWidget(
                                    solicitudId: idOriginal,
                                    nombreColeccion: origen,
                                    onTapCorreo: (correoId) {
                                      Navigator.of(context).pop(); // Cierra el diálogo

                                      _mostrarDetalleCorreo(
                                        correoId: correoId,
                                        solicitudId: idOriginal,
                                        nombreColeccion: origen,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Cerrar"),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),

                      );
                    },
                  ),
                ),

                if (widget.mostrarCorreos)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                    child: ListaCorreosWidget(
                      nombreColeccion: origen,
                      solicitudId: idOriginal,
                      onTapCorreo: (correoHtmlUrl) async {
                        final url = Uri.parse(correoHtmlUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("No se pudo abrir el correo.")),
                          );
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarDetalleCorreo({
    required String correoId,
    required String solicitudId,
    required String nombreColeccion,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return Container(
              color: Colors.white,
              width: isMobile ? double.infinity : 1000,
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(nombreColeccion)
                    .doc(solicitudId)
                    .collection('log_correos')
                    .doc(correoId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text("No se encontró información del correo.");
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  final toList = (data['to'] as List?)?.whereType<String>().toList();
                  final destinatario = data['destinatario'] as String?;

                  final to = toList != null && toList.isNotEmpty
                      ? toList.join(', ')
                      : (destinatario?.isNotEmpty == true ? destinatario : '(sin destinatario)');
                  final cc = (data['cc'] as List?)?.join(', ') ?? '';
                  final subject = data['subject'] ?? '(sin asunto)';
                  final htmlContent = data['cuerpoHtml'] ?? data['html'] ?? data['text'] ?? '(sin contenido)';

                  final fromList = (data['from'] as List?)?.whereType<String>().toList();
                  final remitente = data['remitente'] as String?;

                  final from = fromList != null && fromList.isNotEmpty
                      ? fromList.join(', ')
                      : (remitente?.isNotEmpty == true ? remitente : 'peticiones@tuprocesoya.com');

                  final archivos = data['archivos'] as List? ?? [];

                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final fechaEnvio = timestamp != null
                      ? DateFormat("dd MMM yyyy - hh:mm a", 'es').format(timestamp)
                      : 'Fecha no disponible';

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text("📤 De: $from", style: const TextStyle(fontSize: 13)),
                        Text("📥 Para: $to", style: const TextStyle(fontSize: 13)),
                        if (cc.isNotEmpty)
                          Text("📋 CC: $cc", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 10),
                        Text("📌 Asunto: $subject", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("📅 Fecha de envío: $fechaEnvio", style: const TextStyle(color: Colors.black87, fontSize: 12)),
                        const Divider(),
                        Html(data: htmlContent),
                        if (archivos.isNotEmpty) ...[
                          const Divider(),
                          const Text("📎 Archivos adjuntos:", style: TextStyle(fontWeight: FontWeight.bold)),
                          ...archivos.map((a) => Text("- ${a['nombre']}")).toList(),
                        ],
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            child: const Text("Cerrar"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }


  Map<String, dynamic> _obtenerEstiloEstado(String status) {
    switch (status.toLowerCase()) {
      case 'solicitado':
        return {'icon': Icons.schedule, 'color': Colors.amber, 'texto': 'Solicitado'};
      case 'diligenciado':
        return {'icon': Icons.edit_document, 'color': Colors.blueGrey, 'texto': 'Diligenciado'};
      case 'revisado':
        return {'icon': Icons.search, 'color': Colors.blue, 'texto': 'Revisado'};
      case 'enviado':
        return {'icon': Icons.send, 'color': Colors.green, 'texto': 'Enviado'};
      case 'negado':
        return {'icon': Icons.cancel, 'color': Colors.red, 'texto': 'Negado'};
      case 'concedido':
        return {'icon': Icons.verified, 'color': Colors.green, 'texto': 'Concedido'};
      default:
        return {'icon': Icons.help_outline, 'color': Colors.grey, 'texto': status};
    }
  }
}
