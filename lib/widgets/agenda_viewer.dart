import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../commons/admin_provider.dart';
import '../src/colors/colors.dart';

class AgendaViewerCompact extends StatefulWidget {
  const AgendaViewerCompact({super.key});

  @override
  State<AgendaViewerCompact> createState() => _AgendaViewerCompactState();
}

class _AgendaViewerCompactState extends State<AgendaViewerCompact> {
  DateTime _fechaActual = DateTime.now();
  List<Map<String, dynamic>> _actividadesDelDia = [];
  List<int> _diasConNotas = [];
  int? _diaSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
    _cargarDiasConNotas();
  }

  Future<void> _cargarActividades({DateTime? fecha}) async {
    final DateTime fechaConsulta = fecha ?? DateTime(_fechaActual.year, _fechaActual.month, _diaSeleccionado ?? DateTime.now().day);

    final snapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .where('fecha', isGreaterThanOrEqualTo: DateTime(fechaConsulta.year, fechaConsulta.month, fechaConsulta.day))
        .where('fecha', isLessThan: DateTime(fechaConsulta.year, fechaConsulta.month, fechaConsulta.day + 1))
        .orderBy('fecha')
        .get();

    setState(() {
      _actividadesDelDia = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'comentario': data['comentario'],
          'estado': data['estado'],
          'fecha': data['fecha'],
          'programadoPor': data['programadoPor'],
          'gestionadoPor': data['gestionadoPor'],
          'fechaGestion': data['fechaGestion'],
        };
      }).toList();
    });
  }


  Future<void> _cargarDiasConNotas() async {
    final inicioMes = DateTime(_fechaActual.year, _fechaActual.month, 1);
    final finMes = DateTime(_fechaActual.year, _fechaActual.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(finMes))
        .get();

    final dias = snapshot.docs.map((doc) {
      final fecha = (doc['fecha'] as Timestamp).toDate();
      return fecha.day;
    }).toSet();

    setState(() {
      _diasConNotas = dias.toList()..sort();
    });
  }

  void _mostrarActividadesDelDia() {
    final TextEditingController nuevoComentarioController = TextEditingController();
    DateTime? nuevaFecha;
    //TimeOfDay? nuevaHora;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            _diaSeleccionado ??= DateTime.now().day;
            //final totalDias = DateUtils.getDaysInMonth(_fechaActual.year, _fechaActual.month);
            final fechaSeleccionada = DateTime(_fechaActual.year, _fechaActual.month, _diaSeleccionado!);
            final fechaFormateada = DateFormat('EEEE d MMMM yyyy', 'es').format(fechaSeleccionada);
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              content: SizedBox(
                width: 1200,
                height: 550,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🟩 COLUMNA IZQUIERDA
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📅 $fechaFormateada", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Divider(color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Expanded(
                            child: _actividadesDelDia.isEmpty
                                ? const Center(child: Text("No hay actividades para esta fecha."))
                                : ListView.builder(
                              itemCount: _actividadesDelDia.length,
                              itemBuilder: (_, index) {
                                final sortedActividades = [..._actividadesDelDia]
                                  ..sort((a, b) {
                                    final fechaA = (a['fecha'] as Timestamp).toDate();
                                    final fechaB = (b['fecha'] as Timestamp).toDate();
                                    return fechaA.compareTo(fechaB);
                                  });

                                final act = sortedActividades[index];
                                final fecha = (act['fecha'] as Timestamp).toDate();
                                final ahora = DateTime.now();
                                final diferencia = fecha.difference(ahora);
                                final programador = act['programadoPor'] ?? 'Desconocido';

                                final estado = act['estado'] ?? 'Pendiente';
                                final gestionadoPor = act['gestionadoPor'];
                                final fechaGestion = act['fechaGestion'] != null
                                    ? (act['fechaGestion'] as Timestamp).toDate()
                                    : null;

                                final bool esPendiente = estado == 'Pendiente';
                                final bool mostrarIconoFaltando1Hora = esPendiente && diferencia.inMinutes >= 0 && diferencia.inMinutes <= 60;
                                final bool mostrarIconoVencida = esPendiente && diferencia.inMinutes < 0;
                                final bool esAhoraMismo = esPendiente && diferencia.inMinutes >= -1 && diferencia.inMinutes <= 1;

                                // ⏰ Alerta emergente si es ahora
                                if (esAhoraMismo) {
                                  Future.microtask(() {
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          backgroundColor: blanco,
                                          title: const Text("⏰ ¡Alerta de actividad!"),
                                          content: Text("Debes atender ahora la actividad:\n\n${act['comentario']}"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Entendido"),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  });
                                }
                                // 🟩 Color dinámico según estado y tiempo
                                Color colorFondo;
                                if (estado == 'Atendida') {
                                  colorFondo = Colors.green.shade100;
                                } else if (estado == 'Cerrada') {
                                  colorFondo = Colors.grey.shade300;
                                } else if (estado == 'Pendiente' && diferencia.inMinutes < 0) {
                                  // Si ya pasó la hora y sigue pendiente → rojo
                                  colorFondo = Colors.red.shade100;
                                } else {
                                  colorFondo = Colors.yellow.shade100;
                                }


                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorFondo,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ListTile(
                                    tileColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              "🕒 ${DateFormat('h:mm a', 'es').format(fecha)}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: mostrarIconoVencida ? Colors.red : Colors.black87,
                                                fontWeight: mostrarIconoVencida ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                            if (mostrarIconoFaltando1Hora)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 4),
                                                child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                                              ),
                                            if (mostrarIconoVencida)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 4),
                                                child: Icon(Icons.error_outline, color: Colors.red, size: 16),
                                              ),
                                          ],
                                        ),
                                        Text(act['comentario'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              const TextSpan(
                                                text: "Programado por: ",
                                                style: TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                              TextSpan(
                                                text: programador,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text("📌 Estado: $estado", style: const TextStyle(fontSize: 11, color: Colors.black87)),
                                        if (gestionadoPor != null && fechaGestion != null)
                                          Text(
                                            "👤 Gestionado por: $gestionadoPor (${DateFormat('d MMM, h:mm a', 'es').format(fechaGestion)})",
                                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_calendar, color: Colors.deepPurple),
                                          onPressed: () {
                                            _mostrarReagendadorComentario(
                                              comentarioOriginal: act['comentario'] ?? 'Sin comentario',
                                              docId: act['id'],
                                            );
                                          },
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.black54),
                                          onSelected: (String nuevoEstado) async {
                                            final ahora = Timestamp.now();
                                            final gestor = AdminProvider().adminFullName ?? 'Administrador';

                                            await FirebaseFirestore.instance
                                                .collection('agenda')
                                                .doc(act['id'])
                                                .update({
                                              'estado': nuevoEstado,
                                              'gestionadoPor': gestor,
                                              'fechaGestion': ahora,
                                            });

                                            Navigator.pop(context);
                                            await _cargarActividades(
                                              fecha: DateTime(_fechaActual.year, _fechaActual.month, _diaSeleccionado ?? DateTime.now().day),
                                            );
                                            Future.delayed(const Duration(milliseconds: 200), () {
                                              _mostrarActividadesDelDia();
                                            });
                                          },
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                            const PopupMenuItem<String>(value: 'Pendiente', child: Text('🟡 Pendiente')),
                                            const PopupMenuItem<String>(value: 'Atendida', child: Text('🟢 Atendida')),
                                            const PopupMenuItem<String>(value: 'Cerrada', child: Text('⚫ Cerrada')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // 🟪 COLUMNA DERECHA
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("🗓️ Calendario", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () async {
                                  final nuevaFecha = DateTime(_fechaActual.year, _fechaActual.month - 1);
                                  setState(() {
                                    _fechaActual = nuevaFecha;
                                    _diaSeleccionado = 1; // ✅ Selecciona el primer día del mes
                                  });

                                  await _cargarDiasConNotas();
                                  await _cargarActividades(fecha: DateTime(nuevaFecha.year, nuevaFecha.month, 1));

                                  setStateDialog(() {});
                                },


                              ),
                              Text(
                                DateFormat('MMMM yyyy', 'es').format(_fechaActual),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () async {
                                  final nuevaFecha = DateTime(_fechaActual.year, _fechaActual.month + 1);
                                  setState(() {
                                    _fechaActual = nuevaFecha;
                                    _diaSeleccionado = 1; // ✅ Selecciona el primer día del nuevo mes
                                  });

                                  await _cargarDiasConNotas();
                                  await _cargarActividades(fecha: DateTime(nuevaFecha.year, nuevaFecha.month, 1));

                                  setStateDialog(() {});
                                },

                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text('L', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('J', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('V', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text('D', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Container(
                            height: 250,
                            child: GridView.builder(
                              key: ValueKey('${_fechaActual.year}-${_fechaActual.month}'), // 🔄 Fuerza reconstrucción
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: () {
                                final primerDiaDelMes = DateTime(_fechaActual.year, _fechaActual.month, 1);
                                final offset = (primerDiaDelMes.weekday + 6) % 7; // Lunes = 0
                                final totalDias = DateUtils.getDaysInMonth(_fechaActual.year, _fechaActual.month);
                                return totalDias + offset;
                              }(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                                childAspectRatio: 1.9,
                              ),
                              itemBuilder: (_, index) {
                                final primerDiaDelMes = DateTime(_fechaActual.year, _fechaActual.month, 1);
                                final offset = (primerDiaDelMes.weekday + 6) % 7;

                                if (index < offset) return const SizedBox();

                                final dia = index - offset + 1;
                                final tieneNota = _diasConNotas.contains(dia);
                                final esHoy = DateTime.now().day == dia &&
                                    DateTime.now().month == _fechaActual.month &&
                                    DateTime.now().year == _fechaActual.year;
                                final esSeleccionado = _diaSeleccionado == dia;

                                return GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _diaSeleccionado = dia;
                                    });
                                    await _cargarActividades(
                                      fecha: DateTime(_fechaActual.year, _fechaActual.month, dia),
                                    );
                                    Navigator.pop(context);
                                    _mostrarActividadesDelDia();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: esSeleccionado
                                          ? Colors.green.shade100
                                          : esHoy
                                          ? Colors.deepPurple.shade100
                                          : Colors.white,
                                      border: Border.all(
                                        color: tieneNota ? Colors.deepPurple : Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      tieneNota ? '•$dia' : '$dia',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: tieneNota ? FontWeight.bold : FontWeight.normal,
                                        color: tieneNota ? Colors.deepPurple : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: gris),
                          const SizedBox(height: 6),
                          const Text("📝 Agendar otra actividad", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: nuevoComentarioController,
                                  maxLines: 3,
                                  minLines: 1,
                                  keyboardType: TextInputType.multiline,
                                  decoration: InputDecoration(
                                    hintText: "Escribe una nueva actividad",
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.deepPurple),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.calendar_month, color: Colors.deepPurple),
                                    onPressed: () async {
                                      final fecha = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                        lastDate: DateTime(2100),
                                      );
                                      if (fecha != null && context.mounted) {
                                        final hora = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now(),
                                        );
                                        if (hora != null) {
                                          nuevaFecha = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.green),
                                    onPressed: () async {
                                      if (nuevoComentarioController.text.isNotEmpty && nuevaFecha != null) {
                                        await FirebaseFirestore.instance.collection('agenda').add({
                                          'fecha': Timestamp.fromDate(nuevaFecha!),
                                          'comentario': nuevoComentarioController.text.trim(),
                                          'programadoPor': AdminProvider().adminFullName ?? "Administrador",
                                        });
                                        Navigator.pop(context);
                                        _cargarActividades();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fechaActual = DateTime.now();
                      _diaSeleccionado = DateTime.now().day;
                    });
                    Navigator.pop(context);
                    _cargarActividades(); // Opcional, si quieres actualizar actividades del día actual
                  },
                  child: const Text("Cerrar"),
                ),

              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cargarDiasConNotasForDate(DateTime fecha) async {
    final inicioMes = DateTime(fecha.year, fecha.month, 1);
    final finMes = DateTime(fecha.year, fecha.month + 1, 0);

    final querySnapshot = await FirebaseFirestore.instance
        .collection('agenda')
        .where('fecha', isGreaterThanOrEqualTo: inicioMes)
        .where('fecha', isLessThanOrEqualTo: finMes)
        .get();

    final diasConNotas = querySnapshot.docs.map((doc) {
      final fecha = (doc['fecha'] as Timestamp).toDate();
      return fecha.day;
    }).toSet().toList(); // ✅ Convierte el Set en Lista

    setState(() {
      _diasConNotas = diasConNotas;
    });
  }


  @override
  Widget build(BuildContext context) {
    final primerComentario = _actividadesDelDia.isNotEmpty
        ? _actividadesDelDia.first['comentario']
        : "No hay actividades para este día.";

    final primeraHora = _actividadesDelDia.isNotEmpty
        ? DateFormat('h:mm a', 'es').format(
      (_actividadesDelDia.first['fecha'] as Timestamp).toDate(),
    )
        : "";

    final fechaSeleccionada = DateTime(
      _fechaActual.year,
      _fechaActual.month,
      _diaSeleccionado ?? DateTime.now().day,
    );

    return InkWell(
      onTap: _mostrarActividadesDelDia,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "📅 ${DateFormat('d MMM yyyy', 'es').format(fechaSeleccionada)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (primeraHora.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  "🕒 $primeraHora",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                primerComentario,
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _mostrarReagendadorComentario({
    required String comentarioOriginal,
    required String docId,
  }) async {
    DateTime? nuevaFecha;
    final TextEditingController notaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: 800,
              child: AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: const Text("Reagendar actividad"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📌 Comentario original:\n$comentarioOriginal"),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          final hora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (hora != null) {
                            setState(() {
                              nuevaFecha = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Seleccionar nueva fecha y hora"),
                    ),
                    if (nuevaFecha != null) ...[
                      const SizedBox(height: 10),
                      Text("📅 Nueva fecha: ${DateFormat('d MMM yyyy, h:mm a', 'es').format(nuevaFecha!)}"),
                    ],
                    const SizedBox(height: 16),
                    const Text("✏️ Nota adicional"),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notaController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Agrega una nota si lo deseas",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text("Cancelar"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text("Guardar"),
                    onPressed: () async {
                      if (nuevaFecha != null) {
                        await FirebaseFirestore.instance.collection('agenda').doc(docId).update({
                          'fecha': Timestamp.fromDate(nuevaFecha!),
                          'nota': notaController.text.trim(),
                        });

                        Navigator.pop(context); // Cierra este modal

                        await _cargarActividades(); // 🔁 Recarga actividades actualizadas
                        _mostrarActividadesDelDia(); // 🔄 Vuelve a mostrar con cambios visibles
                      }
                    }
                    ,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
