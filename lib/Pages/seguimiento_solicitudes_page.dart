import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'detalle_solicitudes_page.dart';

class ResumenSolicitudesWidget extends StatelessWidget {
  final String idPpl;

  const ResumenSolicitudesWidget({super.key, required this.idPpl});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('solicitudes_usuario')
          .where('idUser', isEqualTo: idPpl)
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
          shrinkWrap: true, // 🔥 Evita error de altura infinita
          physics: const NeverScrollableScrollPhysics(), // 🔥 Importante si está dentro de un scroll padre
          itemCount: solicitudes.length,
          itemBuilder: (context, index) {
            final doc = solicitudes[index];
            final tipo = doc['tipo'] ?? 'Sin tipo';
            final numero = doc['numeroSeguimiento'] ?? '—';
            final estadoRaw = doc['status'] ?? '—';
            final estilo = _obtenerEstiloEstado(estadoRaw);
            final origen = doc['origen'] ?? '';
            final idOriginal = doc['idOriginal'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: estilo['color'],
                  child: Icon(estilo['icon'], color: Colors.white),
                ),
                title: Text(tipo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seguimiento: $numero", style: const TextStyle(fontSize: 11)),
                    Text("Estado: ${estilo['texto']}", style: const TextStyle(fontSize: 11)),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleSolicitudPage(
                        origen: origen,
                        idDocumento: idOriginal,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
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
