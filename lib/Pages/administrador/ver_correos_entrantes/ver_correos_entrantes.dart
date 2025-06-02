import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../commons/main_layaout.dart';
import '../../../widgets/detalle_correo_respuesta.dart';

class VerRespuestasCorreosPage extends StatefulWidget {
  const VerRespuestasCorreosPage({super.key});

  @override
  State<VerRespuestasCorreosPage> createState() => _VerRespuestasCorreosPageState();
}

class _VerRespuestasCorreosPageState extends State<VerRespuestasCorreosPage> {
  String _busqueda = '';
  DateTime? _fechaSeleccionada;
  Set<int> _citasVisibles = {}; // ⬅️ Esta es la que faltaba


  List<TextSpan> parseNegrilla(String texto) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*(.*?)\*');
    final matches = regex.allMatches(texto);
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: texto.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < texto.length) {
      spans.add(TextSpan(text: texto.substring(lastIndex)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Respuestas de correos',
      content: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por remitente o asunto',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _busqueda = value.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _fechaSeleccionada != null
                              ? DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!)
                              : 'Filtrar por fecha',
                        ),
                        onPressed: () async {
                          final fecha = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (fecha != null) {
                            setState(() => _fechaSeleccionada = fecha);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Quitar filtro de fecha',
                      onPressed: () => setState(() => _fechaSeleccionada = null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('respuestas_correos')
                        .orderBy('recibidoEn', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const Text('❌ Error al cargar los correos.');
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final correos = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final remitente = (data['remitente'] ?? '').toString().toLowerCase();
                        final asunto = (data['asunto'] ?? '').toString().toLowerCase();
                        final fecha = DateTime.tryParse(data['recibidoEn'] ?? '');
                        final coincideBusqueda = remitente.contains(_busqueda) || asunto.contains(_busqueda);
                        final coincideFecha = _fechaSeleccionada == null ||
                            (fecha != null &&
                                fecha.year == _fechaSeleccionada!.year &&
                                fecha.month == _fechaSeleccionada!.month &&
                                fecha.day == _fechaSeleccionada!.day);
                        return coincideBusqueda && coincideFecha;
                      }).toList();

                      if (correos.isEmpty) {
                        return const Text('No se encontraron correos con los filtros aplicados.');
                      }

                      return ListView.separated(
                        itemCount: correos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final correo = correos[index].data() as Map<String, dynamic>;

                          final remitente = (correo['remitente'] ?? 'Desconocido').toString();
                          final asunto = (correo['asunto'] ?? 'Sin asunto').toString();
                          final para = (correo['destinatario'] ?? 'Desconocido').toString();
                          final recibidoEnRaw = correo['recibidoEn'];
                          DateTime? recibidoDateTime;

                          if (recibidoEnRaw is String) {
                            recibidoDateTime = DateTime.tryParse(recibidoEnRaw);
                          } else if (recibidoEnRaw is Timestamp) {
                            recibidoDateTime = recibidoEnRaw.toDate();
                          }

                          final recibidoEn = recibidoDateTime != null
                              ? DateFormat("d 'de' MMMM 'de' yyyy - h:mm a", 'es')
                              .format(recibidoDateTime!)
                              .replaceAll('a. m.', 'am')
                              .replaceAll('p. m.', 'pm')
                              : 'Fecha desconocida';
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleCorreoPage(correo: correo),
                                ),
                              );
                            },
                            child: Card(
                              surfaceTintColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(asunto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('De: $remitente', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('Para: $para', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.deepPurple),
                                        const SizedBox(width: 4),
                                        Text('Recibido: $recibidoEn', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },

                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
