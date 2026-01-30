import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


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

  final Set<String> _beneficiosQueDefinenSituacion = {
    "Permiso de 72h",
    "Prisión Domiciliaria",
    "Libertad Condicional",
    "Extinción de la Pena",
  };


  late List<String> _beneficiosAdquiridosSeleccionados;
  late List<String> _beneficiosNegadosSeleccionados;


  // nuevo para ctuializar la situcaion cuando se seleecione un beneficioa dquirido
  String _calcularSituacionNueva() {
    final adquiridos = _beneficiosAdquiridosSeleccionados.toSet();

    // Prioridad (de mayor a menor)
    if (adquiridos.contains("Extinción de la Pena")) {
      return "Extinción de la pena";
    }
    if (adquiridos.contains("Libertad Condicional")) {
      return "En libertad condicional";
    }
    if (adquiridos.contains("Prisión Domiciliaria")) {
      return "En Prisión domiciliaria";
    }

    // Si no hay beneficios que cambien estado → vuelve a reclusión
    return "En Reclusión";
  }


  @override
  void initState() {
    super.initState();
    _beneficiosAdquiridosSeleccionados = List<String>.from(widget.beneficiosAdquiridosInicial);
    _beneficiosNegadosSeleccionados = List<String>.from(widget.beneficiosNegadosInicial);
  }

  //para tomar el nombre del admin que hace el cambio o la seleccion
  Future<String> _obtenerNombreAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return "Admin desconocido";

    final snap = await FirebaseFirestore.instance
        .collection("admin") // ⚠️ ajusta si tu colección se llama distinto
        .doc(uid)
        .get();

    final data = snap.data();
    if (data == null) return "Admin desconocido";

    final nombre = data["name"] ?? "";
    final apellido = data["apellidos"] ?? "";

    return "$nombre $apellido".trim();
  }


  // Future<void> _guardarCambios() async {
  //   try {
  //     await FirebaseFirestore.instance.collection("Ppl").doc(widget.pplId).update({
  //       "beneficiosAdquiridos": _beneficiosAdquiridosSeleccionados,
  //       "beneficiosNegados": _beneficiosNegadosSeleccionados,
  //     });
  //
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Beneficios actualizados exitosamente.")),
  //       );
  //     }
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Error al actualizar beneficios.")),
  //       );
  //     }
  //   }
  // } comentado para guardar estado


  Future<void> _guardarCambios() async {
    try {
      final pplRef = FirebaseFirestore.instance.collection("Ppl").doc(widget.pplId);

      // ✅ 1) Leer "antes"
      final snap = await pplRef.get();
      final data = snap.data() as Map<String, dynamic>?;

      final adquiridosAntes = (data?["beneficiosAdquiridos"] as List?)?.cast<String>() ?? [];
      final negadosAntes = (data?["beneficiosNegados"] as List?)?.cast<String>() ?? [];
      final String nombreAdmin = await _obtenerNombreAdmin();


      // ✅ 2) Preparar "después"
      final adquiridosDespues = _beneficiosAdquiridosSeleccionados.toSet().toList();
      final negadosDespues = _beneficiosNegadosSeleccionados.toSet().toList();

      final String nuevaSituacion = _calcularSituacionNueva();

      // ✅ 3) Update principal
      final Map<String, dynamic> updateData = {
        "beneficiosAdquiridos": adquiridosDespues,
        "beneficiosNegados": negadosDespues,
        "situacion": nuevaSituacion,
        "fechaUltimaActualizacionBeneficios": FieldValue.serverTimestamp(),
      };

      // Si en algún momento se concede algo desde plataforma, queda marcado para filtro histórico
      final bool huboConcedidoNuevo = adquiridosDespues.toSet().difference(adquiridosAntes.toSet()).isNotEmpty;
      if (huboConcedidoNuevo) {
        updateData["haAdquiridoBeneficioEnPlataforma"] = true;
        updateData["ultimaActualizacionBeneficiosPor"] = nombreAdmin;


        // Solo poner fecha primer beneficio plataforma si no existe
        if (data == null || data["fechaPrimerBeneficioEnPlataforma"] == null) {
          updateData["fechaPrimerBeneficioEnPlataforma"] = FieldValue.serverTimestamp();
          updateData["primerBeneficioEnPlataforma"] =
          adquiridosDespues.isNotEmpty ? adquiridosDespues.first : null;
        }
      }

      await pplRef.update(updateData);

      // ✅ 4) Registrar historial según cambios
      await _registrarHistorialBeneficios(
        pplRef: pplRef,
        adquiridosAntes: adquiridosAntes,
        negadosAntes: negadosAntes,
        adquiridosDespues: adquiridosDespues,
        negadosDespues: negadosDespues,
        situacionResultante: nuevaSituacion,
        nombreAdmin: nombreAdmin,
      );


      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Guardado. Situación: $nuevaSituacion")),
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


  //nuevo para hacer log de cambios de beneficios

  Future<void> _registrarHistorialBeneficios({
    required DocumentReference pplRef,
    required List<String> adquiridosAntes,
    required List<String> negadosAntes,
    required List<String> adquiridosDespues,
    required List<String> negadosDespues,
    required String situacionResultante,
    required String nombreAdmin,
  }) async {
    final antesA = adquiridosAntes.toSet();
    final antesN = negadosAntes.toSet();
    final despuesA = adquiridosDespues.toSet();
    final despuesN = negadosDespues.toSet();

    final concedidosNuevos = despuesA.difference(antesA);
    final negadosNuevos = despuesN.difference(antesN);
    final concedidosQuitados = antesA.difference(despuesA);
    final negadosQuitados = antesN.difference(despuesN);

    final historialRef = pplRef.collection("beneficios_historial");

    Future<void> addEvento(String beneficio, String accion) async {
      await historialRef.add({
        "beneficio": beneficio,
        "accion": accion,
        "fecha": FieldValue.serverTimestamp(),
        "situacionResultante": situacionResultante,
        "origen": "plataforma",
        "adminNombre": nombreAdmin, // ✅ AQUÍ
      });
    }

    for (final b in concedidosNuevos) {
      await addEvento(b, "concedido");
    }
    for (final b in negadosNuevos) {
      await addEvento(b, "negado");
    }
    for (final b in concedidosQuitados) {
      await addEvento(b, "quitado_concedido");
    }
    for (final b in negadosQuitados) {
      await addEvento(b, "quitado_negado");
    }
  }



  // void _seleccionarAdquirido(String beneficio) {
  //   setState(() {
  //     _beneficiosAdquiridosSeleccionados.add(beneficio);
  //     _beneficiosNegadosSeleccionados.remove(beneficio);
  //   });
  // }comenatdo

  void _seleccionarAdquirido(String beneficio) {
    setState(() {
      // ✅ Si este beneficio define situación, entonces solo puede haber uno concedido a la vez
      if (_beneficiosQueDefinenSituacion.contains(beneficio)) {
        _beneficiosAdquiridosSeleccionados.removeWhere(
              (b) => _beneficiosQueDefinenSituacion.contains(b) && b != beneficio,
        );
      }

      if (!_beneficiosAdquiridosSeleccionados.contains(beneficio)) {
        _beneficiosAdquiridosSeleccionados.add(beneficio);
      }

      // ✅ No puede estar concedido y negado a la vez
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.grey), // 🔹 Borde gris
      ),
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
