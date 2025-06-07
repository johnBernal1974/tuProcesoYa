import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../src/colors/colors.dart';


class DetalleSolicitudPage extends StatelessWidget {
  final String origen;
  final String idDocumento;

  const DetalleSolicitudPage({
    super.key,
    required this.origen,
    required this.idDocumento,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(title: const Text("Detalle de solicitud")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection(origen)
            .doc(idDocumento)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No se encontró la solicitud."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Número de seguimiento: ${data['numero_seguimiento'] ?? '—'}"),
              const SizedBox(height: 12),
              Text("Estado: ${data['status'] ?? '—'}"),
              const SizedBox(height: 12),
              if (data['correoHtmlUrl'] != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.mail),
                  label: const Text("Ver correo enviado"),
                  onPressed: () {
                    // Puedes abrir en WebView o navegador externo
                    launchUrl(Uri.parse(data['correoHtmlUrl']));
                  },
                )
              else
                const Text("No se encontró un correo enviado para esta solicitud."),
            ],
          );
        },
      ),
    );
  }
}
