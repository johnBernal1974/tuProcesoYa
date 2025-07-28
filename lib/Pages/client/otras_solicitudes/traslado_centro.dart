import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../commons/drop_depatamentos_municipios.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../services/resumen_solicitudes_service.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_trasladoPenitenciaria/solicitud_exitosa_trasladoPenitenciaria.dart';

class SolicitudTrasladoPenitenciariaPage extends StatefulWidget {
  const SolicitudTrasladoPenitenciariaPage({super.key});

  @override
  State<SolicitudTrasladoPenitenciariaPage> createState() => _SolicitudTrasladoPenitenciariaPageState();
}

class _SolicitudTrasladoPenitenciariaPageState extends State<SolicitudTrasladoPenitenciariaPage> {

  String? _motivoSeleccionado;
  String? departamentoSeleccionado;
  String? municipioSeleccionado;
  String? parentescoSeleccionado;
  String? nombreFamiliar;
  String? descripcionSalud;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud Traslado de Centro Penitenciario', style: TextStyle(color: blanco)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                const Text(
                  'Solicitar el traslado a otro centro penitenciario',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Si te encuentras en un centro penitenciario donde no tienes acceso a actividades de resocialización como el trabajo, el estudio o programas productivos, puedes solicitar el traslado a otro establecimiento donde sí existan estas oportunidades.\n\n'
                      'El traslado también puede pedirse cuando:\n'
                      '- Hay riesgo para tu vida o integridad por amenazas o conflictos internos.\n'
                      '- Estás lejos de tu núcleo familiar y deseas acercarte a tu familia para fortalecer los lazos afectivos.\n'
                      '- Requieres atención médica especializada que no se brinda en tu lugar de reclusión.\n\n'
                      'Esta solicitud está respaldada por la Ley 65 de 1993 (Código Penitenciario y Carcelario), que establece que la pena debe cumplirse en condiciones dignas y con enfoque de resocialización. También se fundamenta en el derecho al trabajo (Artículo 25 de la Constitución) y el principio de dignidad humana.\n\n'
                      'El objetivo es que el INPEC evalúe tu caso y, si encuentra que se vulneran tus derechos o se limita tu acceso a la redención de pena, autorice tu traslado a un centro que cumpla con las condiciones necesarias.\n\n'
                      'Al presionar el siguiente botón, iniciarás el proceso para que tu solicitud sea registrada y tramitada. Nuestro equipo te apoyará durante todo el proceso.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Selecciona el motivo principal de tu solicitud de traslado:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 10),
                ...[
                  'Por acercamiento familiar',
                  'Por derecho al trabajo o redención de pena',
                  'Por razones de salud',
                ].map((motivo) {
                  return RadioListTile<String>(
                    title: Text(motivo),
                    value: motivo,
                    groupValue: _motivoSeleccionado,
                    activeColor: primary,
                    onChanged: (value) {
                      setState(() {
                        _motivoSeleccionado = value;
                      });
                    },
                  );
                }).toList(),

                if (_motivoSeleccionado == 'Por acercamiento familiar') ...[
                  const SizedBox(height: 20),
                  const Text(
                    '¿En qué departamento y municipio se encuentra el familiar con el que se pretende realizar el acercamiento?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DepartamentosMunicipiosWidget(
                    departamentoSeleccionado: departamentoSeleccionado,
                    municipioSeleccionado: municipioSeleccionado,
                    onSelectionChanged: (String departamento, String municipio) {
                      setState(() {
                        departamentoSeleccionado = departamento;
                        municipioSeleccionado = municipio;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Cuál es el parentesco del familiar?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    dropdownColor: blanco,
                    decoration: const InputDecoration(
                      labelText: 'Parentesco del familiar con el PPL',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    value: parentescoSeleccionado,
                    items: const [
                      DropdownMenuItem(value: 'Madre', child: Text('Madre')),
                      DropdownMenuItem(value: 'Padre', child: Text('Padre')),
                      DropdownMenuItem(value: 'Hija', child: Text('Hija')),
                      DropdownMenuItem(value: 'Hijo', child: Text('Hijo')),
                      DropdownMenuItem(value: 'Esposa', child: Text('Esposa')),
                      DropdownMenuItem(value: 'Esposo', child: Text('Esposo')),
                      DropdownMenuItem(value: 'Abuela', child: Text('Abuela')),
                      DropdownMenuItem(value: 'Abuelo', child: Text('Abuelo')),
                      DropdownMenuItem(value: 'Nieta', child: Text('Nieta')),
                      DropdownMenuItem(value: 'Nieto', child: Text('Nieto')),
                      DropdownMenuItem(value: 'Hermana', child: Text('Hermana')),
                      DropdownMenuItem(value: 'Hermano', child: Text('Hermano')),
                      DropdownMenuItem(value: 'Tía', child: Text('Tía')),
                      DropdownMenuItem(value: 'Tío', child: Text('Tío')),
                      DropdownMenuItem(value: 'Prima', child: Text('Prima')),
                      DropdownMenuItem(value: 'Primo', child: Text('Primo')),
                      DropdownMenuItem(value: 'Compañera', child: Text('Compañera')),
                      DropdownMenuItem(value: 'Compañero', child: Text('Compañero')),
                      DropdownMenuItem(value: 'Cuñada', child: Text('Cuñada')),
                      DropdownMenuItem(value: 'Cuñado', child: Text('Cuñado')),
                      DropdownMenuItem(value: 'Suegra', child: Text('Suegra')),
                      DropdownMenuItem(value: 'Suegro', child: Text('Suegro')),
                      DropdownMenuItem(value: 'Nuera', child: Text('Nuera')),
                      DropdownMenuItem(value: 'Yerno', child: Text('Yerno')),
                      DropdownMenuItem(value: 'Sobrina', child: Text('Sobrina')),
                      DropdownMenuItem(value: 'Sobrino', child: Text('Sobrino')),
                      DropdownMenuItem(value: 'Amiga', child: Text('Amiga')),
                      DropdownMenuItem(value: 'Amigo', child: Text('Amigo')),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        parentescoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¿Cuál es el nombre y apellido del familiar?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre y apellido del familiar',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        nombreFamiliar = value.trim();
                      });
                    },
                  ),
                ],
                if (_motivoSeleccionado == 'Por razones de salud') ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Describe tu situación médica con detalle:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Ej. Requiero atención especializada por una enfermedad crónica que no es tratada en este centro...',
                      labelText: 'Motivo de salud',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    minLines: 4,
                    maxLines: null,
                    onChanged: (value) {
                      setState(() {
                        descripcionSalud = value.trim();
                      });
                    },
                  ),
                ],

                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  onPressed: _intentarEnviarSolicitud,
                  child: const Text(
                    'Solicitar Traslado de Centro',
                    style: TextStyle(fontSize: 18, color: blanco),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),

          ),
        ),
      ),
    );
  }

  Future<bool> mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text('Confirmar envío'),
        content: const Text('¿Estás seguro de solicitar el traslado? Esta acción será enviada para su revisión y trámite.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: blanco)),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _intentarEnviarSolicitud() async {
    if (_motivoSeleccionado == null) {
      _mostrarSnackBar("Debes seleccionar un motivo para el traslado.");
      return;
    }

    if (_motivoSeleccionado == 'Por acercamiento familiar') {
      if ((departamentoSeleccionado?.isEmpty ?? true) ||
          (municipioSeleccionado?.isEmpty ?? true) ||
          (parentescoSeleccionado?.isEmpty ?? true) ||
          (nombreFamiliar?.isEmpty ?? true)) {
        _mostrarSnackBar("Completa todos los campos de acercamiento familiar.");
        return;
      }
    }

    if (_motivoSeleccionado == 'Por razones de salud') {
      if (descripcionSalud == null || descripcionSalud!.trim().isEmpty) {
        _mostrarSnackBar("Debes describir la situación médica.");
        return;
      }
    }

    final confirmado = await mostrarConfirmacionEnvio(context);
    if (confirmado) {
      await verificarSaldoYEnviarSolicitudTraslado();
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 3),
      ),
    );
  }


  Future<void> verificarSaldoYEnviarSolicitudTraslado() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valor = (configSnapshot.docs.first.data()['valor_trasladoPenitenciaria'] ?? 0).toDouble();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('Ppl').doc(uid).get();
    final double saldo = (userDoc.data()?['saldo'] ?? 0).toDouble();

    if (saldo >= valor) {
      await FirebaseFirestore.instance.collection('Ppl').doc(uid).update({'saldo': saldo - valor});
      await enviarSolicitudTrasladoPenitenciaria(valor);
    } else {
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: blanco,
          title: const Text("Pago requerido"),
          content: const Text("Para enviar esta solicitud debes realizar el pago del servicio."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutPage(
                      tipoPago: 'trasladoPenitenciaria',
                      valor: valor.toInt(),
                      onTransaccionAprobada: () async {
                        await enviarSolicitudTrasladoPenitenciaria(valor);
                      },
                    ),
                  ),
                );
              },
              child: const Text("Pagar"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> enviarSolicitudTrasladoPenitenciaria(double valor) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: blancoCards,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Enviando solicitud..."),
          ],
        ),
      ),
    );

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = firestore.collection('trasladoPenitenciaria_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      final pplDoc = await firestore.collection('Ppl').doc(user.uid).get();
      final data = pplDoc.data();
      final nombrePpl = (data?['nombre_ppl'] ?? '').toString();
      final apellidoPpl = (data?['apellido_ppl'] ?? '').toString();

      await descontarSaldo(valor);

      final Map<String, dynamic> motivoData = {
        'motivo': _motivoSeleccionado,
      };

      if (_motivoSeleccionado == 'Por acercamiento familiar') {
        motivoData['departamento_familiar'] = departamentoSeleccionado;
        motivoData['municipio_familiar'] = municipioSeleccionado;
        motivoData['parentesco'] = parentescoSeleccionado;
        motivoData['nombre_familiar'] = nombreFamiliar;
      }

      if (_motivoSeleccionado == 'Por razones de salud') {
        motivoData['descripcion_salud'] = descripcionSalud;
      }

      await firestore.collection('trasladoPenitenciaria_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
        ...motivoData,
      });

      await ResumenSolicitudesService.guardarResumen(
        idUser: user.uid,
        nombrePpl: '$nombrePpl $apellidoPpl',
        tipo: "Traslado de centro penitenciario",
        numeroSeguimiento: numeroSeguimiento,
        status: "Solicitado",
        idOriginal: docId,
        origen: "trasladoPenitenciaria_solicitados",
        fecha: Timestamp.now(),
      );

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SolicitudExitosaTrasladoPenitenciariaPage(numeroSeguimiento: numeroSeguimiento),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Hubo un problema al guardar la solicitud."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar")),
            ],
          ),
        );
      }
    }
  }

  Future<void> descontarSaldo(double valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final datos = snapshot.data();
    final double saldoActual = (datos?['saldo'] ?? 0).toDouble();
    final double nuevoSaldo = saldoActual - valor;

    if (nuevoSaldo >= 0) {
      await docRef.update({'saldo': nuevoSaldo});
    }
  }
}
