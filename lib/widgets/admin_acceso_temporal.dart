import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAccesoTemporal extends StatefulWidget {
  final String uidPPL;

  const AdminAccesoTemporal({super.key, required this.uidPPL});

  @override
  State<AdminAccesoTemporal> createState() => _AdminAccesoTemporalState();
}

class _AdminAccesoTemporalState extends State<AdminAccesoTemporal> {
  bool _cambioTemporalAplicado = false;
  Map<String, dynamic>? _valoresOriginales;

  Future<void> _aplicarAccesoTemporal() async {
    final docRef = FirebaseFirestore.instance.collection("Ppl").doc(widget.uidPPL);
    final doc = await docRef.get();
    final data = doc.data();

    if (data == null) return;

    // Guardar valores originales en memoria
    _valoresOriginales = {
      "isPaid": data["isPaid"],
      "fecha_activacion": data["fecha_activacion"]
    };

    // Aplicar acceso temporal
    await docRef.update({
      "isPaid": true,
      "fecha_activacion": FieldValue.serverTimestamp()
    });

    setState(() => _cambioTemporalAplicado = true);
  }

  Future<void> _restaurarValoresOriginales() async {
    if (_valoresOriginales == null) return;

    await FirebaseFirestore.instance.collection("Ppl").doc(widget.uidPPL).update({
      "isPaid": _valoresOriginales!["isPaid"],
      "fecha_activacion": _valoresOriginales!["fecha_activacion"],
    });

    setState(() {
      _cambioTemporalAplicado = false;
      _valoresOriginales = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(_cambioTemporalAplicado ? Icons.undo : Icons.timer),
      label: Text(_cambioTemporalAplicado
          ? "Restaurar acceso original"
          : "Dar acceso temporal"),
      onPressed: () async {
        if (_cambioTemporalAplicado) {
          final confirmar = await _confirmarRestauracion();
          if (confirmar) await _restaurarValoresOriginales();
        } else {
          await _aplicarAccesoTemporal();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _cambioTemporalAplicado ? Colors.red : Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<bool> _confirmarRestauracion() async {
    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Restaurar valores originales?"),
        content: const Text("El acceso temporal será revocado."),
        actions: [
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: const Text("Restaurar"), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    ) ??
        false;
  }
}
