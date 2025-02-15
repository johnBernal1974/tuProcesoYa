import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/main_layaout.dart';
import '../../../src/colors/colors.dart';
import '../home/home.dart';

class BuzonSugerenciasPage extends StatefulWidget {
  const BuzonSugerenciasPage({super.key});

  @override
  State<BuzonSugerenciasPage> createState() => _BuzonSugerenciasPageState();
}

class _BuzonSugerenciasPageState extends State<BuzonSugerenciasPage> {
  final TextEditingController _sugerenciaController = TextEditingController();
  bool _isSending = false;

  String _capitalizarPrimeraLetra(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Future<void> _enviarSugerencia() async {
    if (_sugerenciaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No has ingresado ningúna sugerencia.'),
          duration: Duration(seconds: 2),
        ),
      );
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
      final celularAcudiente = userDoc.data()?['celular'] ?? '';

      await FirebaseFirestore.instance.collection('buzon_sugerencias').add({
        'fecha_sugerencia': Timestamp.now(),
        'nombre_acudiente': '$nombreAcudiente',
        'apellido_acudiente': '$apellidoAcudiente',
        'id': user.uid,
        'celular': celularAcudiente,
        'respondido_por': "",
        'respuesta': "",
        'fecha_respuesta': null,
        'contestado': false,
        'sugerencia': _capitalizarPrimeraLetra(_sugerenciaController.text.trim()),
      });

      _sugerenciaController.clear();
      setState(() {
        _isSending = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Gracias por tu sugerencia!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
                  '¡Comparte tu opinión! En esta sección puedes dejar tus comentarios y sugerencias '
                      'para ayudarnos a mejorar nuestro servicio.'
                      ,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 15),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '¡Recuerda que este espacio es solo para sugerencias y NO para solicitar servicios.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const SizedBox(height: 20),
                TextField(
                  textCapitalization: TextCapitalization.sentences,
                  controller: _sugerenciaController,
                  maxLines: 5,
                  decoration: _inputDecoration('Escribe tu sugerencia aquí'),
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
