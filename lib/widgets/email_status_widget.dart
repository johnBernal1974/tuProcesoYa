import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EstadoCorreosTable extends StatelessWidget {
  final String messageId;

  const EstadoCorreosTable({super.key, required this.messageId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📨 Eventos de correos (Resend)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('resend_eventos_basico')
                .where('messageId', isEqualTo: messageId)
                .orderBy('timestamp', descending: true)
                .limit(300)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No hay eventos registrados.");
              }

              final rawEventos = snapshot.data!.docs;
              final Map<String, Map<String, dynamic>> eventosAgrupados = {};

              for (final doc in rawEventos) {
                final data = doc.data() as Map<String, dynamic>;
                final email = data['email'] ?? '-';
                final type = data['type'] ?? '-';
                final tipo = data['tipo'] ?? '-';
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                final key = email;
                final prioridad = ['email.bounced', 'email.delivered', 'email.sent'];
                final existente = eventosAgrupados[key];

                if (existente == null || prioridad.indexOf(type) < prioridad.indexOf(existente['type'])) {
                  eventosAgrupados[key] = {
                    'email': email,
                    'tipo': tipo,
                    'type': type,
                    'timestamp': timestamp,
                  };
                }
              }

              final eventosOrdenados = eventosAgrupados.values.toList()
                ..sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

              return Column(
                children: eventosOrdenados.map((data) {
                  final email = data['email'];
                  final tipo = data['tipo'];
                  final type = data['type'];
                  final timestamp = data['timestamp'] as DateTime?;
                  final fecha = timestamp != null
                      ? DateFormat('dd/MM/yyyy - hh:mm a').format(timestamp)
                      : '-';

                  final estadoTraducido = {
                    'email.sent': 'Enviado',
                    'email.delivered': 'Entregado',
                    'email.bounced': 'Rebotado',
                  }[type] ?? type;

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(email, style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: Text(tipo, style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: Text(estadoTraducido, style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 3, child: Text(fecha, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
