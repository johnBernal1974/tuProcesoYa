import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/derecho_tutelable.dart';

class DerechosTutelablesPage extends StatefulWidget {
  const DerechosTutelablesPage({super.key});

  @override
  State<DerechosTutelablesPage> createState() => _DerechosTutelablesPageState();
}

class _DerechosTutelablesPageState extends State<DerechosTutelablesPage> {
  List<DerechoTutelable> derechos = [];
  DerechoTutelable? derechoSeleccionado;

  @override
  void initState() {
    super.initState();
    cargarDerechos();
  }

  Future<void> cargarDerechos() async {
    final jsonString = await rootBundle.loadString('assets/data/derechos_tutelables.json');
    final jsonMap = json.decode(jsonString);
    final lista = (jsonMap['derechos'] as List)
        .map((d) => DerechoTutelable.fromJson(d))
        .toList();
    setState(() {
      derechos = lista;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fundamentos de Derechos Tutelables')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: derechos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<DerechoTutelable>(
              value: derechoSeleccionado,
              hint: const Text('Selecciona un derecho'),
              isExpanded: true,
              items: derechos.map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text(d.titulo),
                );
              }).toList(),
              onChanged: (nuevo) {
                setState(() {
                  derechoSeleccionado = nuevo;
                });
              },
            ),
            const SizedBox(height: 20),
            if (derechoSeleccionado != null)
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      derechoSeleccionado!.descripcion,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    const Text('📚 Fundamentos:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...derechoSeleccionado!.fundamentos.map((f) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔹 ${f.titulo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(f.detalle),
                        const SizedBox(height: 12)
                      ],
                    )),
                    const SizedBox(height: 16),
                    const Text('📌 Pretensiones sugeridas:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...derechoSeleccionado!.pretensiones.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $p'),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
