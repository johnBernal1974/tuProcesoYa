import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TablaEstadiasAdmin extends StatelessWidget {
  final String pplId;

  const TablaEstadiasAdmin({super.key, required this.pplId});

  @override
  Widget build(BuildContext context) {
    final estadiasRef = FirebaseFirestore.instance
        .collection('Ppl')
        .doc(pplId)
        .collection('estadias')
        .orderBy('fecha_ingreso', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: estadiasRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Espera ...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No hay estadías registradas.");
        }

        final estadias = snapshot.data!.docs;

        return Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 4,
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Registros", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4), // 🔽 Espacio reducido entre título y tabla
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) => Colors.grey.shade200, // ✅ color fila encabezado
                    ),
                    columns: const [
                      DataColumn(
                          label: Text("Tipo",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                      DataColumn(
                          label: Text("Inicio",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                      DataColumn(
                          label: Text("Terminación",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                      DataColumn(
                          label: Text("Acciones",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                    ],
                    rows: estadias.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final id = doc.id;
                      final tipo = data['tipo'] ?? '-';
                      final ingreso = (data['fecha_ingreso'] as Timestamp).toDate();
                      final salida = data['fecha_salida'] != null
                          ? (data['fecha_salida'] as Timestamp).toDate()
                          : null;

                      return DataRow(cells: [
                        DataCell(Text(tipo, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(_formatearFecha(ingreso), style: const TextStyle(fontSize: 12))),
                        DataCell(Text(
                            salida != null
                                ? _formatearFecha(salida)
                                : 'Actual',
                            style: const TextStyle(fontSize: 12))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black, size: 15),
                              onPressed: () => _mostrarDialogoEdicion(context, pplId, id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 15),
                              onPressed: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Eliminar estadía"),
                                    content: const Text("¿Deseas eliminar esta estadía?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancelar"),
                                        onPressed: () => Navigator.pop(context, false),
                                      ),
                                      TextButton(
                                        child: const Text("Eliminar"),
                                        onPressed: () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmar == true) {
                                  final tipoEstadia = data['tipo'];
                                  final fechaIngresoEstadia = (data['fecha_ingreso'] as Timestamp).toDate();

                                  // Eliminamos la estadía
                                  await FirebaseFirestore.instance
                                      .collection('Ppl')
                                      .doc(pplId)
                                      .collection('estadias')
                                      .doc(id)
                                      .delete();

                                  // Si era una estadía de Reclusión, verificamos si era la más antigua
                                  if (tipoEstadia == 'Reclusión') {
                                    final snapshot = await FirebaseFirestore.instance
                                        .collection('Ppl')
                                        .doc(pplId)
                                        .collection('estadias')
                                        .where('tipo', isEqualTo: 'Reclusión')
                                        .orderBy('fecha_ingreso')
                                        .limit(1)
                                        .get();

                                    final primeraEstadia = snapshot.docs.isNotEmpty
                                        ? (snapshot.docs.first['fecha_ingreso'] as Timestamp).toDate()
                                        : null;

                                    // Si no hay más reclusiones o la primera ya no es la misma
                                    if (primeraEstadia == null || primeraEstadia.isAfter(fechaIngresoEstadia)) {
                                      await FirebaseFirestore.instance
                                          .collection('Ppl')
                                          .doc(pplId)
                                          .update({'fecha_captura': null});

                                      debugPrint("📛 Nodo 'fecha_captura' eliminado tras borrar la primera estadía de Reclusión");
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );


      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    return "${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
  }

  void _mostrarDialogoEdicion(BuildContext context, String pplId, String estadiaId, Map<String, dynamic> data) {
    final tipoCtrl = TextEditingController(text: data['tipo']);
    DateTime? fechaIngreso = (data['fecha_ingreso'] as Timestamp).toDate();
    DateTime? fechaSalida = data['fecha_salida'] != null ? (data['fecha_salida'] as Timestamp).toDate() : null;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Editar estadía"),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoCtrl.text,
                  items: ['Reclusión', 'Domiciliaria', 'Condicional']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => tipoCtrl.text = val ?? 'Reclusión'),
                  decoration: InputDecoration(
                    labelText: 'Tipo',
                    floatingLabelBehavior: FloatingLabelBehavior.always, // 👈 siempre visible
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

                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaIngreso,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => fechaIngreso = picked);
                  },
                  child: Text("Ingreso: ${_formatearFecha(fechaIngreso ?? DateTime.now())}"),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSalida ?? DateTime.now(),
                      firstDate: fechaIngreso ?? DateTime(2000), // ✅ corregido
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => fechaSalida = picked);
                  },
                  child: Text(
                    fechaSalida != null
                        ? "Salida: ${_formatearFecha(fechaSalida!)}" // ✅ corregido
                        : "Sin salida",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Guardar"),
              onPressed: () async {
                if (fechaIngreso == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("La fecha de ingreso es obligatoria")),
                  );
                  return;
                }

                if (fechaSalida != null && fechaSalida!.isBefore(fechaIngreso!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("La fecha de salida no puede ser anterior a la de ingreso")),
                  );
                  return;
                }

                // Validación de solapamientos (excluyendo esta misma estadía)
                final estadiasExistentes = await FirebaseFirestore.instance
                    .collection('Ppl')
                    .doc(pplId)
                    .collection('estadias')
                    .get();

                final nuevaInicio = fechaIngreso!;
                final nuevaFin = fechaSalida ?? DateTime.now();

                for (final doc in estadiasExistentes.docs) {
                  if (doc.id == estadiaId) continue; // ⛔ Saltamos la que estamos editando

                  final data = doc.data();
                  final inicio = (data['fecha_ingreso'] as Timestamp).toDate();
                  final fin = data['fecha_salida'] != null
                      ? (data['fecha_salida'] as Timestamp).toDate()
                      : DateTime.now();

                  final seSolapan = nuevaInicio.isBefore(fin) && nuevaFin.isAfter(inicio);
                  if (seSolapan) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Esta estadía se cruza con otra registrada entre ${_formatearFecha(inicio)} y ${_formatearFecha(fin)}.",
                        ),
                      ),
                    );
                    return;
                  }
                }

                // ✅ Si todo pasa, guardamos
                await FirebaseFirestore.instance
                    .collection('Ppl')
                    .doc(pplId)
                    .collection('estadias')
                    .doc(estadiaId)
                    .update({
                  'tipo': tipoCtrl.text,
                  'fecha_ingreso': Timestamp.fromDate(fechaIngreso!),
                  'fecha_salida': fechaSalida != null ? Timestamp.fromDate(fechaSalida!) : null,
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
