import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../src/colors/colors.dart';

class FormularioEstadiaAdmin extends StatefulWidget {
  final String pplId; // ID del documento del PPL

  const FormularioEstadiaAdmin({super.key, required this.pplId});

  @override
  State<FormularioEstadiaAdmin> createState() => _FormularioEstadiaAdminState();
}

class _FormularioEstadiaAdminState extends State<FormularioEstadiaAdmin> {
  DateTime? _fechaIngreso;
  DateTime? _fechaSalida;
  String _tipo = 'Reclusión';

  final _tipos = ['Reclusión', 'Domiciliaria', 'Condicional'];

  Future<void> _guardarEstadia() async {
    if (_fechaIngreso == null) {
      _mostrarAlerta("Debes seleccionar la fecha de ingreso");
      return;
    }

    if (_fechaSalida != null && _fechaSalida!.isBefore(_fechaIngreso!)) {
      _mostrarAlerta("La fecha de salida no puede ser anterior a la de ingreso");
      return;
    }

    // Verificar que no se solape con estadías
    final estadiasExistentes = await FirebaseFirestore.instance
        .collection('Ppl')
        .doc(widget.pplId)
        .collection('estadias')
        .get();

    final nuevaInicio = _fechaIngreso!;
    final nuevaFin = _fechaSalida ?? DateTime.now();

    for (final doc in estadiasExistentes.docs) {
      final data = doc.data();
      final inicio = (data['fecha_ingreso'] as Timestamp).toDate();
      final fin = data['fecha_salida'] != null
          ? (data['fecha_salida'] as Timestamp).toDate()
          : DateTime.now();

      final seSolapan = nuevaInicio.isBefore(fin) && nuevaFin.isAfter(inicio);
      if (seSolapan) {
        _mostrarAlerta(
            "Ya existe una estadía entre ${_formatearFecha(inicio)} y ${_formatearFecha(fin)} que se solapa con la actual."
        );
        return;
      }
    }

    final uidAdmin = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance
        .collection('Ppl')
        .doc(widget.pplId)
        .collection('estadias')
        .add({
      'fecha_ingreso': Timestamp.fromDate(_fechaIngreso!),
      'fecha_salida': _fechaSalida != null ? Timestamp.fromDate(_fechaSalida!) : null,
      'tipo': _tipo,
      'creado_por': uidAdmin,
      'creado_en': Timestamp.now(),
    });

    final doc = await FirebaseFirestore.instance.collection('Ppl').doc(widget.pplId).get();
    final data = doc.data() ?? {};
    final status = data['status'] ?? '';
    final yaTieneFechaCaptura = data['fecha_captura'] != null;

    String mensajeFinal = "Estadía registrada correctamente.";

    if ((status == 'activado' || status == 'registrado' || status == 'pendiente') && !yaTieneFechaCaptura) {
      await FirebaseFirestore.instance.collection('Ppl').doc(widget.pplId).update(
          {'fecha_captura': Timestamp.fromDate(_fechaIngreso!)}
      );
      mensajeFinal += "\n📌 Fecha de captura agregada automáticamente.";
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeFinal),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  Future<void> _seleccionarFechaIngreso() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaIngreso = picked);
  }

  Future<void> _seleccionarFechaSalida() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSalida ?? DateTime.now(),
      firstDate: _fechaIngreso ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fechaSalida = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      surfaceTintColor:Colors.amber.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Registrar estadía", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              dropdownColor: blanco,
              value: _tipo,
              onChanged: (value) => setState(() => _tipo = value!),
              items: _tipos
                  .map((tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)))
                  .toList(),
              decoration: InputDecoration(
                labelText: "Tipo de estadía",
                floatingLabelBehavior: FloatingLabelBehavior.always, // 👈 Siempre visible
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _seleccionarFechaIngreso,
                  child: Text(
                    _fechaIngreso == null
                        ? "Fecha de inicio"
                        : "Ingreso: ${_fechaIngreso!.toLocal().toString().split(' ')[0]}",
                  ),
                ),
                ElevatedButton(
                  onPressed: _seleccionarFechaSalida,
                  child: Text(
                    _fechaSalida == null
                        ? "Fecha terminación"
                        : "Salida: ${_fechaSalida!.toLocal().toString().split(' ')[0]}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 👈 centra el botón
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                  onPressed: _guardarEstadia,
                  icon: const Icon(Icons.save, color: blanco),
                  label: const Text("Guardar", style: TextStyle(color: blanco)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  String _formatearFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  void _mostrarAlerta(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Aviso"),
          content: Text(mensaje),
          actions: [
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarEstadia(String estadiaId) async {
    try {
      final estadiasRef = FirebaseFirestore.instance
          .collection('Ppl')
          .doc(widget.pplId)
          .collection('estadias');

      // 🗑️ Eliminar la estadía
      await estadiasRef.doc(estadiaId).delete();

      // 🔍 Consultar si quedan más estadías
      final estadiasActualizadas = await estadiasRef.get();

      if (estadiasActualizadas.size == 0) {
        // ✅ Si ya no hay estadías, limpiar `fecha_captura`
        await FirebaseFirestore.instance
            .collection('Ppl')
            .doc(widget.pplId)
            .update({'fecha_captura': FieldValue.delete()});
        debugPrint(
            "📌 Sin estadías. Campo fecha_captura eliminado correctamente.");
      } else {
        // ✅ Opcional: Recalcular fecha_captura con la estadía más antigua
        final estadiasOrdenadas = estadiasActualizadas.docs
          ..sort((a, b) {
            final fechaA = (a.data()['fecha_ingreso'] as Timestamp).toDate();
            final fechaB = (b.data()['fecha_ingreso'] as Timestamp).toDate();
            return fechaA.compareTo(fechaB); // orden ascendente
          });

        final fechaIngresoMasAntigua = (estadiasOrdenadas.first
            .data()['fecha_ingreso'] as Timestamp)
            .toDate();

        await FirebaseFirestore.instance
            .collection('Ppl')
            .doc(widget.pplId)
            .update(
          {'fecha_captura': Timestamp.fromDate(fechaIngresoMasAntigua)},
        );

        debugPrint(
            "🔄 fecha_captura actualizada a la estadía más antigua: $fechaIngresoMasAntigua");
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Estadía eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error eliminando estadía: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error eliminando estadía'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


}
