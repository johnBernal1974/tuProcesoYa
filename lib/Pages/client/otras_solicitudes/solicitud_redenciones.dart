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
  final Map<String, List<String>> trabajosPorCategoria = {
    'Trabajo manual y artesanal': [
      'Confección de ropa',
      'Tejido (crochet, bordado)',
      'Elaboración de calzado',
      'Carpintería',
      'Ebanistería',
      'Marroquinería',
      'Joyería artesanal',
    ],
    'Mantenimiento y servicios generales': [
      'Aseo y limpieza',
      'Mantenimiento de jardines',
      'Pintura',
      'Reparación de instalaciones',
      'Ayudante de cocina',
      'Lavandería',
    ],
    'Producción de alimentos': [
      'Panadería',
      'Repostería',
      'Cocina institucional',
      'Empaque de alimentos',
    ],
    'Apoyo logístico y administrativo': [
      'Auxiliar administrativo',
      'Apoyo a biblioteca',
      'Monitor educativo',
      'Apoyo a programas de resocialización',
    ],
    'Arte y cultura': [
      'Pintura o arte visual',
      'Teatro penitenciario',
      'Música',
      'Manualidades con material reciclable',
    ],
    'Otro': [],
  };

  String tipoSeleccionado = '';
  String? categoriaSeleccionada;
  String? trabajoSeleccionado;
  String? categoriaPersonalizada;
  String? trabajoPersonalizado;
  DateTime? fechaInicio;
  DateTime? fechaFin;

  String? actividadSeleccionada; // trabajo, estudio, enseñanza
  TextEditingController otroTrabajoController = TextEditingController();


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

  int _calcularDiasRedimidos(int dias) {
    switch (tipoSeleccionado) {
      case 'Trabajo':
        return (dias / 2).floor();
      case 'Estudio':
        return (dias / 2).floor();
      case 'Enseñanza':
        return (dias * 2);
      default:
        return 0;
    }
  }

  String _mensajeRedimido(int dias) {
    switch (tipoSeleccionado) {
      case 'Trabajo':
        return '✅ Días redimibles: $dias (1 día de redención por cada 2 días trabajados)';
      case 'Estudio':
        return '✅ Días redimibles: $dias (1 día de redención por cada 2 días de estudio)';
      case 'Enseñanza':
        return '✅ Días redimibles: $dias (2 días redimibles por cada día de enseñanza)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final diasTrabajados = _calcularDias();
    final diasRedimidos = _calcularDiasRedimidos(diasTrabajados);

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
                  '🔎 Redención de pena por trabajo, estudio o enseñanza (Artículo 141 de la Ley 65 de 1993)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Las personas privadas de la libertad pueden redimir su pena mediante actividades de trabajo, estudio o enseñanza. Estas actividades deben ser certificadas y supervisadas por el centro penitenciario. La redención se aplica de acuerdo con los artículos 141 al 145 de la Ley 65 de 1993, y permite reducir el tiempo de reclusión. Por cada dos días de trabajo o estudio, se redime un día de pena. En el caso de la enseñanza, se pueden redimir hasta dos días por cada uno de enseñanza impartida, siempre que se verifique su impacto y cumplimiento.',
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),

                const Text('Selecciona la actividad:', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<String>(
                  title: const Text('Trabajo'),
                  value: 'Trabajo',
                  groupValue: tipoSeleccionado,
                  onChanged: (val) => setState(() => tipoSeleccionado = val ?? ''),
                ),
                RadioListTile<String>(
                  title: const Text('Estudio'),
                  value: 'Estudio',
                  groupValue: tipoSeleccionado,
                  onChanged: (val) => setState(() => tipoSeleccionado = val ?? ''),
                ),
                RadioListTile<String>(
                  title: const Text('Enseñanza'),
                  value: 'Enseñanza',
                  groupValue: tipoSeleccionado,
                  onChanged: (val) => setState(() => tipoSeleccionado = val ?? ''),
                ),

                if (tipoSeleccionado == 'Trabajo') ...[
                  const SizedBox(height: 30),
                  const Text('Selecciona la categoría de trabajo', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    dropdownColor: Colors.amber.shade50,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    ),
                    value: categoriaSeleccionada,
                    items: trabajosPorCategoria.keys.map((categoria) {
                      return DropdownMenuItem(value: categoria, child: Text(categoria));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        categoriaSeleccionada = value;
                        trabajoSeleccionado = null;
                        trabajoPersonalizado = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (categoriaSeleccionada == 'Otro')
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Trabajo específico',
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      onChanged: (val) => setState(() => trabajoPersonalizado = val),
                    )
                  else
                    DropdownButtonFormField<String>(
                      dropdownColor: Colors.amber.shade50,
                      decoration: const InputDecoration(
                        labelText: 'Trabajo específico',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      ),
                      value: trabajoSeleccionado,
                      items: categoriaSeleccionada == null
                          ? []
                          : trabajosPorCategoria[categoriaSeleccionada]!
                          .map((trabajo) => DropdownMenuItem(value: trabajo, child: Text(trabajo)))
                          .toList(),
                      onChanged: (value) {
                        setState(() => trabajoSeleccionado = value);
                      },
                    ),
                ],

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
                if (fechaInicio != null && fechaFin != null && tipoSeleccionado.isNotEmpty) ...[
                  Text(
                    '🗓️ Desde ${_formatearFecha(fechaInicio)} hasta ${_formatearFecha(fechaFin)} — Total: $diasTrabajados días',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _mensajeRedimido(diasRedimidos),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
                  ),
                ],

                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (tipoSeleccionado.isEmpty) {
                      _mostrarAlerta("Debes seleccionar una actividad: Trabajo, Estudio o Enseñanza.");
                      return;
                    }

                    if (fechaInicio == null || fechaFin == null) {
                      _mostrarAlerta("Debes seleccionar el periodo de tiempo.");
                      return;
                    }

                    if (tipoSeleccionado == 'Trabajo') {
                      if (categoriaSeleccionada == null) {
                        _mostrarAlerta("Debes seleccionar una categoría de trabajo.");
                        return;
                      }

                      if (categoriaSeleccionada == 'Otro' && otroTrabajoController.text.trim().isEmpty) {
                        _mostrarAlerta("Por favor, escribe el trabajo específico.");
                        return;
                      }

                      if (categoriaSeleccionada != 'Otro' && trabajoSeleccionado == null) {
                        _mostrarAlerta("Debes seleccionar un trabajo específico.");
                        return;
                      }
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

  Future<bool> mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text('Confirmar envío'),
          content: const Text('¿Estás seguro de solicitar las redenciones? Esta acción será enviada para su revisión y trámite.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar', style: TextStyle(color: blanco)),
            ),
          ],
        );
      },
    ) ?? false;
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
      String docId = firestore.collection('redenciones_solicitadas').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      await firestore.collection('redenciones_solicitadas').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha_creacion': FieldValue.serverTimestamp(),
        'status': 'Solicitado',

        // 👇 Aquí se accede directamente a variables declaradas en el widget
        'tipo_actividad': tipoSeleccionado,
        'categoria': categoriaSeleccionada == 'Otro' ? 'Otro' : categoriaSeleccionada,
        'trabajo': categoriaSeleccionada == 'Otro'
            ? otroTrabajoController.text.trim()
            : trabajoSeleccionado ?? '',
        'fecha_inicio': Timestamp.fromDate(fechaInicio!),
        'fecha_fin': Timestamp.fromDate(fechaFin!),
        'dias_trabajados': _calcularDias(),
        'dias_redimidos': _calcularDiasRedimidos(_calcularDias()),
      });

      if (context.mounted) {
        Navigator.pop(context); // Cierra el diálogo "Enviando..."
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



  Future<void> descontarSaldo(double valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final datos = snapshot.data();
      final double saldoActual = (datos?['saldo'] ?? 0).toDouble();
      final double nuevoSaldo = saldoActual - valor;

      if (nuevoSaldo >= 0) {
        await docRef.update({'saldo': nuevoSaldo});
      } else {
        debugPrint('⚠️ Saldo insuficiente, no se pudo descontar');
      }
    }
  }

  @override
  void dispose() {
    otroTrabajoController.dispose();
    super.dispose();
  }

}
