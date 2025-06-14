import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

class TiempoBeneficioCard extends StatefulWidget {
  final String idPpl;

  const TiempoBeneficioCard({super.key, required this.idPpl});

  @override
  State<TiempoBeneficioCard> createState() => _TiempoBeneficioCardState();
}

class _TiempoBeneficioCardState extends State<TiempoBeneficioCard> {
  String seleccion = 'superado'; // valor por defecto

  Future<void> actualizarNodo() async {
    try {
      await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(widget.idPpl)
          .update({'nivel_tiempo_beneficio': seleccion});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nivel actualizado como "$seleccion"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el nivel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        color: Colors.white,
        surfaceTintColor: blanco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.grey),
        ),
        elevation: 2,
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centrar contenido horizontal
            children: [
              const Text(
                '¿Nivel de tiempo ejecutado?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 190,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: blanco,
                          value: seleccion,
                          items: const [
                            DropdownMenuItem(value: 'superado', child: Text('Superado (≥30%)')),
                            DropdownMenuItem(value: 'cercano', child: Text('Cercano (25–29%)')),
                            DropdownMenuItem(value: 'bajo', child: Text('Bajo (<25%)')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                seleccion = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: actualizarNodo,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(0, 0),
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.save, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

