import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../src/colors/colors.dart';

class AgregarAgendaSimple extends StatefulWidget {
  const AgregarAgendaSimple({super.key});

  @override
  State<AgregarAgendaSimple> createState() => _AgregarAgendaSimpleState();
}

class _AgregarAgendaSimpleState extends State<AgregarAgendaSimple> {
  DateTime? _fechaSeleccionada;
  final TextEditingController _comentarioController = TextEditingController();
  bool _guardando = false;

  Future<void> _seleccionarFechaYHora() async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora.subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (fecha == null) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora == null) return;

    final fechaHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      _fechaSeleccionada = fechaHora;
    });
  }

  Future<void> _guardarEnAgenda() async {
    if (_fechaSeleccionada == null || _comentarioController.text.trim().isEmpty) return;

    setState(() {
      _guardando = true;
    });

    try {
      await FirebaseFirestore.instance.collection('agenda').add({
        'fecha': _fechaSeleccionada,
        'comentario': _comentarioController.text.trim(),
        'estado': 'Pendiente',
        'creado': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Actividad guardada en agenda')),
      );

      setState(() {
        _comentarioController.clear();
        _fechaSeleccionada = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al guardar la agenda')),
      );
    }

    setState(() {
      _guardando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = _fechaSeleccionada != null
        ? DateFormat('dd/MM/yyyy hh:mm a').format(_fechaSeleccionada!)
        : 'Seleccionar fecha y hora';

    return Card(
      color: blanco,
      surfaceTintColor: blanco,
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("GENERAR UN RECORDATORIO", style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: _seleccionarFechaYHora,
              icon: const Icon(Icons.calendar_today),
              label: Text(fechaFormateada),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Escribe un comentario',
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_fechaSeleccionada != null && !_guardando)
                  ? _guardarEnAgenda
                  : null,
              icon: const Icon(Icons.save),
              label: _guardando
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
