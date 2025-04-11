import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListaCorreosWidget extends StatelessWidget {
  final String solicitudId;
  final void Function(String correoId) onTapCorreo;

  const ListaCorreosWidget({super.key, required this.solicitudId, required this.onTapCorreo});

  Future<List<Map<String, dynamic>>> _obtenerCorreosConEstado(String solicitudId) async {
    final correosSnapshot = await FirebaseFirestore.instance
        .collection("derechos_peticion_solicitados")
        .doc(solicitudId)
        .collection("log_correos")
        .orderBy("timestamp", descending: true)
        .get();

    List<Map<String, dynamic>> resultado = [];

    for (final correo in correosSnapshot.docs) {
      final correoData = correo.data();
      final messageId = correoData['messageId'];
      final email = (correoData['to'] as List?)?.join(", ") ?? "(sin destinatario)";
      final timestamp = (correoData['timestamp'] as Timestamp?)?.toDate();
      final correoId = correo.id;

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

      resultado.add({
        'estado': estado ?? '(sin estado)',
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
      future: _obtenerCorreosConEstado(solicitudId),
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
                    _estadoConIcono(estado),
                    const SizedBox(height: 8),
                    Text("📧 $correo", style: const TextStyle(fontSize: 13)),
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
