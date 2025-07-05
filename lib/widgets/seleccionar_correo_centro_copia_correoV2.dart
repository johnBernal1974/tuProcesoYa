import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../src/colors/colors.dart';

class SeleccionarCorreoCentroReclusionV2 extends StatefulWidget {
  final String idUser;
  final Function(String correoSeleccionado, String nombreCentro) onEnviarCorreo;
  final VoidCallback? onOmitir;

  const SeleccionarCorreoCentroReclusionV2({
    super.key,
    required this.idUser,
    required this.onEnviarCorreo,
    this.onOmitir,
  });

  @override
  State<SeleccionarCorreoCentroReclusionV2> createState() =>
      _SeleccionarCorreoCentroReclusionV2State();
}

class _SeleccionarCorreoCentroReclusionV2State
    extends State<SeleccionarCorreoCentroReclusionV2> {
  String? centroPenitenciario;
  Map<String, String?> correosMap = {};
  String? correoSeleccionado;
  String? nombreCorreoSeleccionado;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCorreosCentro();
  }

  Future<void> _cargarCorreosCentro() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(widget.idUser)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        print("⚠️ No se encontraron datos del usuario");
        return;
      }

      final nombreCentro = userData['centro_reclusion'];
      print("✅ Centro penitenciario encontrado en Ppl: $nombreCentro");

      final correosDoc = await FirebaseFirestore.instance
          .collection('Ppl')
          .doc(widget.idUser)
          .collection('correos_centro_reclusion')
          .doc('emails')
          .get();

      if (!correosDoc.exists) {
        print("⚠️ El documento 'emails' no existe para el user ${widget.idUser}");
        return;
      }

      final data = correosDoc.data();
      print("📨 Correos obtenidos: $data");

      Map<String, String?> mapTemp = {
        'Dirección': data?['correo_direccion'],
        'Jurídica': data?['correo_juridica'],
        'Principal': data?['correo_principal'],
        'Sanidad': data?['correo_sanidad'],
      };

      mapTemp.removeWhere((key, value) => value == null || value!.trim().isEmpty);

      setState(() {
        centroPenitenciario = nombreCentro;
        correosMap = mapTemp;
        if (correosMap.isNotEmpty) {
          nombreCorreoSeleccionado = correosMap.keys.first;
          correoSeleccionado = correosMap.values.first;
        }
        cargando = false;
      });
    } catch (e) {
      print("❌ Error en _cargarCorreosCentro: $e");
      setState(() {
        cargando = false;
      });
    }
  }

  void _confirmarYEnviarCorreo() async {
    if (correoSeleccionado == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Confirmar envío"),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 14),
            children: [
              const TextSpan(text: "¿Deseas enviar el correo a:\n\n"),
              TextSpan(
                text: correoSeleccionado!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Sí, enviar"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      widget.onEnviarCorreo(correoSeleccionado!, centroPenitenciario ?? "Centro");
    }
  }



  Widget _correoConBoton(String nombre, String correo) {
    final isSelected = nombre == nombreCorreoSeleccionado;
    return GestureDetector(
      onTap: () {
        setState(() {
          nombreCorreoSeleccionado = nombre;
          correoSeleccionado = correo;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$nombre: $correo',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  nombreCorreoSeleccionado = nombre;
                  correoSeleccionado = correo;
                });
              },
              child: Text(
                isSelected ? 'Elegido' : 'Elegir',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.black : Colors.blue,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📩 Envío de copia al centro penitenciario",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              centroPenitenciario ?? "Centro de reclusión",
              style: const TextStyle(fontSize: 18, color: negro, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            if (correosMap.isEmpty)
              const Text("⚠️ No se encontraron correos para este centro.")
            else
              Column(
                children: correosMap.entries
                    .map((entry) => _correoConBoton(entry.key, entry.value!))
                    .toList(),
              ),
            const SizedBox(height: 20),
            if (correoSeleccionado != null)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text("Enviar correo", style: TextStyle(color: blanco)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: _confirmarYEnviarCorreo,
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onOmitir?.call();
                },
                child: const Text("Omitir este paso"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
