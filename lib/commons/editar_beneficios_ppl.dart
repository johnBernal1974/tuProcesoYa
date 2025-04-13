import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarBeneficiosWidget extends StatefulWidget {
  final String pplId;
  final List<String> beneficiosAdquiridosInicial;

  const EditarBeneficiosWidget({
    super.key,
    required this.pplId,
    required this.beneficiosAdquiridosInicial,
  });

  @override
  State<EditarBeneficiosWidget> createState() => _EditarBeneficiosWidgetState();
}

class _EditarBeneficiosWidgetState extends State<EditarBeneficiosWidget> {
  final List<String> _beneficiosDisponibles = [
    "Permiso de 72h",
    "Prisión Domiciliaria",
    "Libertad Condicional",
    "Extinción de la Pena",
  ];

  late List<String> _beneficiosSeleccionados;

  @override
  void initState() {
    super.initState();
    _beneficiosSeleccionados = List<String>.from(widget.beneficiosAdquiridosInicial);
  }

  Future<void> _guardarCambios() async {
    try {
      await FirebaseFirestore.instance.collection("Ppl").doc(widget.pplId).update({
        "beneficiosAdquiridos": _beneficiosSeleccionados,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Beneficios actualizados exitosamente.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar beneficios.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Actualizar Beneficios Adquiridos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            ..._beneficiosDisponibles.map((beneficio) => CheckboxListTile(
              title: Text(beneficio),
              value: _beneficiosSeleccionados.contains(beneficio),
              onChanged: (valor) {
                setState(() {
                  if (valor == true) {
                    _beneficiosSeleccionados.add(beneficio);
                  } else {
                    _beneficiosSeleccionados.remove(beneficio);
                  }
                });
              },
            )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Guardar Cambios"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
