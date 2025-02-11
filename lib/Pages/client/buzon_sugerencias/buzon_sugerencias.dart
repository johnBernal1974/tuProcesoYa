import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';

class BuzonSugerenciasPage extends StatefulWidget {
  const BuzonSugerenciasPage({super.key});

  @override
  State<BuzonSugerenciasPage> createState() => _BuzonSugerenciasPageState();
}

class _BuzonSugerenciasPageState extends State<BuzonSugerenciasPage> {
  final TextEditingController _sugerenciaController = TextEditingController();
  final TextEditingController _resenaController = TextEditingController();
  double _calificacion = 0.0;
  bool _isSending = false;

  String _capitalizarPrimeraLetra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Future<void> _enviarSugerencia() async {
    if (_sugerenciaController.text.trim().isEmpty && _calificacion == 0) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(user.uid).get();
      final nombreAcudiente = userDoc.data()?['nombre_acudiente'] ?? 'Desconocido';
      final apellidoAcudiente = userDoc.data()?['apellido_acudiente'] ?? '';

      await FirebaseFirestore.instance.collection('buzon_sugerencias').add({
        'fecha_sugerencia': Timestamp.now(),
        'nombre_acudiente': '$nombreAcudiente $apellidoAcudiente',
        'id': user.uid,
        'sugerencia': _capitalizarPrimeraLetra(_sugerenciaController.text.trim()),
        'calificacion': _calificacion,
        'resena': _calificacion > 0 ? _capitalizarPrimeraLetra(_resenaController.text.trim()) : '',
      });

      _sugerenciaController.clear();
      _resenaController.clear();
      setState(() {
        _calificacion = 0.0;
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu sugerencia!'),
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Regresa al Home
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return MainLayout(
      pageTitle: 'Buzón de Sugerencias',
      content: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth >= 1000 ? 1000 : double.infinity,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Queremos escucharte!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu opinión es muy importante para nosotros. Déjanos tus sugerencias o califica el servicio recibido.',
                  style: TextStyle(fontSize: 16, height: 1.3),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _sugerenciaController,
                  maxLines: 5,
                  decoration: _inputDecoration('Escribe tu sugerencia aquí'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Califica nuestro servicio:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: _calificacion,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 30,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: primary,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() {
                      _calificacion = rating;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_calificacion > 0)
                  TextField(
                    controller: _resenaController,
                    maxLines: 3,
                    decoration: _inputDecoration('Déjanos una reseña ( opcional )'),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                  onPressed: _isSending ? null : _enviarSugerencia,
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enviar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
