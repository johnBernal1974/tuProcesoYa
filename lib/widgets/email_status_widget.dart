import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListaCorreosWidget extends StatelessWidget {
  final String solicitudId;
  final String nombreColeccion;
  final void Function(String correoId) onTapCorreo;

  const ListaCorreosWidget({super.key, required this.solicitudId, required this.onTapCorreo, required this.nombreColeccion});

  Future<List<Map<String, dynamic>>> _obtenerCorreosConEstado() async {
    final correosSnapshot = await FirebaseFirestore.instance
        .collection(nombreColeccion) // ✅ Se usa el parámetro aquí
        .doc(solicitudId)
        .collection("log_correos")
        .orderBy("timestamp", descending: true)
        .get();

    List<Map<String, dynamic>> resultado = [];

    for (final correo in correosSnapshot.docs) {
      final correoData = correo.data();
      final correoId = correo.id;
      final messageId = correoData['messageId'];
      final timestamp = (correoData['timestamp'] as Timestamp?)?.toDate();

      String email;
      String estadoFinal;

      // 📨 SI ES ENVIADO (tiene 'to')
      if (correoData.containsKey('to') && correoData['to'] is List) {
        email = (correoData['to'] as List?)?.join(", ") ?? "(sin destinatario)";
        String? estado;

        if (messageId != null) {
          final eventosSnapshot = await FirebaseFirestore.instance
              .collection("resend_eventos_basico")
              .where("messageId", isEqualTo: messageId)
              .orderBy("timestamp", descending: true)
              .limit(1)
              .get();

          if (eventosSnapshot.docs.isNotEmpty) {
            estado = eventosSnapshot.docs.first.data()['type'];
          }
        }

        estadoFinal = estado ?? "(sin estado)";
      }

      // 📥 SI ES RECIBIDO (no tiene 'to', pero sí 'from')
      else if (correoData.containsKey('from') || correoData.containsKey('remitente')) {
        // Obtener remitente
        final fromList = (correoData['from'] as List?)?.whereType<String>().toList();
        final remitente = correoData['remitente'] as String?;
        email = fromList != null && fromList.isNotEmpty
            ? fromList.join(', ')
            : (remitente?.isNotEmpty == true ? remitente! : "peticiones@tuprocesoya.com");

        // Detectar si es respuesta
        final esRespuesta = correoData['esRespuesta'] == true || correoData['EsRespuesta'] == true;

        estadoFinal = esRespuesta ? "respuesta" : "recibido";
      }

      // ❓ SI NO HAY NI 'to' NI 'from'
      else {
        email = "(correo sin dirección)";
        estadoFinal = "(sin estado)";
      }

      resultado.add({
        'estado': estadoFinal,
        'correo': email,
        'fecha': timestamp,
        'id': correoId,
      });
    }
    return resultado;
  }

  Widget _estadoConIcono(String estado) {
    late Icon icono;
    late String texto;
    estado = estado.toLowerCase().trim();


    switch (estado) {
      case 'email.delivered':
        icono = const Icon(Icons.check_circle, color: Colors.green, size: 16);
        texto = 'Entregado';
        break;
      case 'email.sent':
        icono = const Icon(Icons.send, color: Colors.blue, size: 16);
        texto = 'Enviado';
        break;
      case 'email.bounced':
        icono = const Icon(Icons.error, color: Colors.red, size: 16);
        texto = 'Rebotado';
        break;
      case 'respuesta':
        icono = const Icon(Icons.mark_email_read, color: Colors.deepPurple, size: 16);
        texto = 'Respuesta';
        break;

      case 'recibido':
        icono = const Icon(Icons.inbox, color: Colors.orange, size: 16);
        texto = 'Correo recibido';
        break;
      default:
        icono = const Icon(Icons.help_outline, color: Colors.grey, size: 16);
        texto = estado;
    }

    return Row(
      children: [
        icono,
        const SizedBox(width: 6),
        Flexible(child: Text(texto, style: const TextStyle(fontSize: 13)))
      ],
    );
  }


  Color _estadoColor(String estado) {
    switch (estado) {
      case 'email.delivered':
        return Colors.green.shade50;
      case 'email.bounced':
        return Colors.red.shade50;
      case 'email.sent':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _obtenerCorreosConEstado(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No hay correos con estado para mostrar.");
        }

        final lista = snapshot.data!;

        return Column(
          children: lista.map((item) {
            final estado = item['estado'];
            final correo = item['correo'];
            final fecha = item['fecha'] != null
                ? DateFormat("dd/MM/yyyy - hh:mm a", 'es').format(item['fecha'])
                : 'Sin fecha';
            final correoId = item['id'];

            return InkWell(
              onTap: () => onTapCorreo(correoId),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: _estadoColor(estado),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isMobile
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: estado.toLowerCase().contains('recibido') || estado.toLowerCase().contains('respuesta')
                            ? "De: "
                            : "Para: ",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: correo,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("📅 $fecha", style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  ],
                )
                    : Row(
                  children: [
                    Expanded(flex: 3, child: _estadoConIcono(estado)),
                    Expanded(flex: 4, child: Text(correo, style: const TextStyle(fontSize: 13))),
                    Expanded(flex: 4, child: Text(fecha, style: const TextStyle(fontSize: 13))),
                  ],
                ),

              ),
            );
          }).toList(),
        );

      },
    );
  }
}
