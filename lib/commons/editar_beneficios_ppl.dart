import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../src/colors/colors.dart';

class EditarBeneficiosWidget extends StatefulWidget {
  final String pplId;
  final List<String> beneficiosAdquiridosInicial;
  final List<String> beneficiosNegadosInicial;

  const EditarBeneficiosWidget({
    super.key,
    required this.pplId,
    required this.beneficiosAdquiridosInicial,
    required this.beneficiosNegadosInicial,
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

  late List<String> _beneficiosAdquiridosSeleccionados;
  late List<String> _beneficiosNegadosSeleccionados;

  @override
  void initState() {
    super.initState();
    _beneficiosAdquiridosSeleccionados = List<String>.from(widget.beneficiosAdquiridosInicial);
    _beneficiosNegadosSeleccionados = List<String>.from(widget.beneficiosNegadosInicial);
  }

  Future<void> _guardarCambios() async {
    try {
      await FirebaseFirestore.instance.collection("Ppl").doc(widget.pplId).update({
        "beneficiosAdquiridos": _beneficiosAdquiridosSeleccionados,
        "beneficiosNegados": _beneficiosNegadosSeleccionados,
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

  void _seleccionarAdquirido(String beneficio) {
    setState(() {
      _beneficiosAdquiridosSeleccionados.add(beneficio);
      _beneficiosNegadosSeleccionados.remove(beneficio);
    });
  }

  void _seleccionarNegado(String beneficio) {
    setState(() {
      _beneficiosNegadosSeleccionados.add(beneficio);
      _beneficiosAdquiridosSeleccionados.remove(beneficio);
    });
  }

  void _desmarcarAdquirido(String beneficio) {
    setState(() {
      _beneficiosAdquiridosSeleccionados.remove(beneficio);
    });
  }

  void _desmarcarNegado(String beneficio) {
    setState(() {
      _beneficiosNegadosSeleccionados.remove(beneficio);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor: Colors.amber.shade600,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Actualizar Beneficios",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(color: gris),
            ..._beneficiosDisponibles.map((beneficio) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        beneficio,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _beneficiosAdquiridosSeleccionados.contains(beneficio),
                            onChanged: (valor) {
                              if (valor == true) {
                                _seleccionarAdquirido(beneficio);
                              } else {
                                _desmarcarAdquirido(beneficio);
                              }
                            },
                          ),
                          const Text('Concedido', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Checkbox(
                            value: _beneficiosNegadosSeleccionados.contains(beneficio),
                            onChanged: (valor) {
                              if (valor == true) {
                                _seleccionarNegado(beneficio);
                              } else {
                                _desmarcarNegado(beneficio);
                              }
                            },
                          ),
                          const Text('Negado', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
              ],
            )),

            const SizedBox(height: 10),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Guardar Cambios", style: TextStyle(color: blanco)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
