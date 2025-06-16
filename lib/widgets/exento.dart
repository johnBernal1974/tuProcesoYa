import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarExclusionWidget extends StatefulWidget {
  final String pplId;
  final bool exentoInicial;

  const EditarExclusionWidget({
    super.key,
    required this.pplId,
    required this.exentoInicial,
  });

  @override
  State<EditarExclusionWidget> createState() => _EditarExclusionWidgetState();
}

class _EditarExclusionWidgetState extends State<EditarExclusionWidget> {
  late bool _exento;

  @override
  void initState() {
    super.initState();
    _exento = widget.exentoInicial;
  }

  Future<void> _guardarExclusion() async {
    try {
      await FirebaseFirestore.instance
          .collection("Ppl")
          .doc(widget.pplId)
          .update({"exento": _exento});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Exclusión actualizada correctamente.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.purple.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.grey), // 🔹 Borde gris
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Checkbox(
              value: _exento,
              onChanged: (valor) {
                setState(() {
                  _exento = valor ?? false;
                });
              },
            ),
            const Expanded(
              child: Text("Marcar como exento del artículo 68A",
                  style: TextStyle(fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.deepPurple),
              tooltip: "Guardar",
              onPressed: _guardarExclusion,
            ),
          ],
        ),
      ),
    );
  }
}