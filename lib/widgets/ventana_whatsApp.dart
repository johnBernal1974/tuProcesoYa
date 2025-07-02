import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/widgets/whatApp_chat_page.dart';
import 'package:tuprocesoya/widgets/whatsapp_state.dart';

class WhatsAppChatSummary extends StatelessWidget {
  final String numeroCliente;

  const WhatsAppChatSummary({
    Key? key,
    required this.numeroCliente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('Ppl')
          .where('celularWhatsapp',
          isEqualTo: numeroCliente.startsWith('57')
              ? numeroCliente.substring(2)
              : numeroCliente)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        String acudienteNombre = '';
        String pplNombre = '';
        String cleanNumber = numeroCliente.startsWith('57')
            ? numeroCliente.substring(2)
            : numeroCliente;
        String estadoPago = 'Sin pago ❌';
        Color colorPago = Colors.red;
        String subtitleText = "Usuario no registrado";

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final data = snapshot.data!.docs.first;
          final nombreAcudiente = data['nombre_acudiente'] ?? '';
          final apellidoAcudiente = data['apellido_acudiente'] ?? '';
          final nombrePpl = data['nombre_ppl'] ?? '';
          final apellidoPpl = data['apellido_ppl'] ?? '';
          final isPaid = data['isPaid'] == true;

          acudienteNombre = "$nombreAcudiente $apellidoAcudiente";
          pplNombre = "$nombrePpl $apellidoPpl";

          // Si está registrado, no mostrar mensaje de no registrado
          subtitleText = '';

          if (isPaid) {
            estadoPago = 'Suscripción al día ✅';
            colorPago = Colors.green;
          }
        }

        return InkWell(
          onTap: () {
            selectedNumeroCliente.value = numeroCliente;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WhatsAppChatPage(),
              ),
            );
          },

          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.shade50,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/icono_whatsapp.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Acudiente en negrita o número si no registrado
                      Text(
                        acudienteNombre.isNotEmpty ? acudienteNombre : cleanNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Nombre PPL más pequeño si existe
                      if (pplNombre.isNotEmpty)
                        Text(
                          pplNombre,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),

                      // Si acudiente está vacío, NO vuelvas a poner el número aquí
                      if (acudienteNombre.isNotEmpty)
                        Text(
                          cleanNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),

                      // Usuario no registrado
                      if (subtitleText.isNotEmpty)
                        Text(
                          subtitleText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),

                      // Estado pago
                      Text(
                        estadoPago,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorPago,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 600;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 800 : double.infinity,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Error: $error",
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
