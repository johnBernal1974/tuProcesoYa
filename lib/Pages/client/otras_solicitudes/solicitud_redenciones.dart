import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../commons/wompi/checkout_page.dart';
import '../../../src/colors/colors.dart';
import '../solicitud_exitosa_redenciones/solicitud_exitosa_redenciones.dart';

class SolicitudRedencionPage extends StatefulWidget {
  const SolicitudRedencionPage({Key? key}) : super(key: key);

  @override
  State<SolicitudRedencionPage> createState() => _SolicitudRedencionPageState();
}

class _SolicitudRedencionPageState extends State<SolicitudRedencionPage> {
  DateTime? fechaInicio;
  DateTime? fechaFin;

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '';
    return DateFormat('yyyy-MM-dd').format(fecha);
  }

  int _calcularDias() {
    if (fechaInicio != null && fechaFin != null) {
      return fechaFin!.difference(fechaInicio!).inDays + 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final diasTrabajados = _calcularDias();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Solicitud de Redención', style: TextStyle(color: Colors.white)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '🔎 Redención de pena (Artículo 141 de la Ley 65 de 1993)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Indique el período durante el cual realizó actividades susceptibles de redención de pena. Esta solicitud será enviada a la autoridad competente para el respectivo cómputo.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),

                const Text('Periodo solicitado para la redención', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                const Text('Desde', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha de inicio',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          locale: const Locale('es', 'ES'),
                        );
                        if (fecha != null) setState(() => fechaInicio = fecha);
                      },
                    ),
                  ),
                  controller: TextEditingController(text: _formatearFecha(fechaInicio)),
                ),

                const SizedBox(height: 20),
                const Text('Hasta', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha de finalización',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                          locale: const Locale('es', 'ES'),
                        );
                        if (fecha != null) setState(() => fechaFin = fecha);
                      },
                    ),
                  ),
                  controller: TextEditingController(text: _formatearFecha(fechaFin)),
                ),

                const SizedBox(height: 30),
                if (fechaInicio != null && fechaFin != null) ...[
                  Text(
                    '🗓️ Desde ${_formatearFecha(fechaInicio)} hasta ${_formatearFecha(fechaFin)} — Total: $diasTrabajados días',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],

                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (fechaInicio == null || fechaFin == null) {
                      _mostrarAlerta("Debes seleccionar el periodo de tiempo.");
                      return;
                    }
                    final confirmacion = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: blanco,
                        title: const Text('Confirmar envío'),
                        content: const Text('¿Estás seguro de que deseas enviar esta solicitud de redención?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primary),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Enviar', style: TextStyle(color: blanco)),
                          ),
                        ],
                      ),
                    );

                    if (confirmacion == true) {
                      await verificarSaldoYEnviarSolicitud();
                    }
                  },
                  child: const Text('Solicitar redención', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 50)
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Campo obligatorio"),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar")),
        ],
      ),
    );
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorRedenciones = (configSnapshot.docs.first.data()['valor_redenciones'] ?? 0).toDouble();

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
                    tipoPago: 'redenciones',
                    valor: valorRedenciones.toInt(),
                    onTransaccionAprobada: () async {
                      await enviarSolicitudRedencion();
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

  Future<void> enviarSolicitudRedencion() async {
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
      String docId = firestore.collection('redenciones_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      await firestore.collection('redenciones_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'fecha_inicio': Timestamp.fromDate(fechaInicio!),
        'fecha_fin': Timestamp.fromDate(fechaFin!),
        'dias_trabajados': _calcularDias(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaRedencionPage(
              numeroSeguimiento: numeroSeguimiento,
            ),
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
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );
      }
    }
  }
}
