import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tuprocesoya/commons/main_layaout.dart';
import '../../../../src/colors/colors.dart';
import '../../../../widgets/ventana_whatsApp.dart';

class HomeAdminPilotoPage extends StatefulWidget {
  const HomeAdminPilotoPage({super.key});

  @override
  State<HomeAdminPilotoPage> createState() => _HomeAdminPilotoPageState();
}

class _HomeAdminPilotoPageState extends State<HomeAdminPilotoPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _pplRef = FirebaseFirestore.instance.collection('pre_registro_ppl');
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = "";
  String? filterStatus; // null = todos

  // Para resaltar fila seleccionada
  String? _docIdSeleccionado;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================
  // EXPORT CSV (Excel abre esto)
  // ===========================
  Future<void> exportPplCsvWeb() async {
    final snapshot = await _pplRef.get();
    final docs = snapshot.docs;
    await _exportCsv(docs);
  }

  Future<void> _exportCsv(List<QueryDocumentSnapshot> docs) async {
    final headers = [
      'id',
      'status',
      'nombre_ppl',
      'apellido_ppl',
      'numero_documento_ppl',
      'nombre_acudiente',
      'apellido_acudiente',
      'celularWhatsapp',
      'fechaRegistro',
    ];

    final rows = <List<String>>[
      headers,
      ...docs.map((d) {
        final x = d.data() as Map<String, dynamic>? ?? {};
        final fecha = _convertirTimestampADateTime(x['fechaRegistro']);
        final fechaTxt = fecha != null ? DateFormat("yyyy-MM-dd HH:mm:ss", 'es_CO').format(fecha) : '';

        return [
          d.id,
          (x['status'] ?? '').toString(),
          (x['nombre_ppl'] ?? '').toString(),
          (x['apellido_ppl'] ?? '').toString(),
          (x['numero_documento_ppl'] ?? '').toString(),
          (x['nombre_acudiente'] ?? '').toString(),
          (x['apellido_acudiente'] ?? '').toString(),
          (x['celularWhatsapp'] ?? '').toString(),
          fechaTxt,
        ];
      }),
    ];

    const sep = ';';

    String esc(String v) {
      var out = v.replaceAll('\r', ' ').replaceAll('\n', ' ');
      out = out.replaceAll(sep, ',');
      final needsQuotes = out.contains('"') || out.contains(',') || out.contains(';');
      final escaped = out.replaceAll('"', '""');
      return needsQuotes ? '"$escaped"' : escaped;
    }

    final body = rows.map((r) => r.map(esc).join(sep)).join('\r\n');
    final content = 'sep=$sep\r\n$body';

    final bytes = _utf16leWithBom(content);

    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'Base_PPL_$ts.csv';

    final blob = html.Blob([bytes], 'text/csv;charset=utf-16le');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV descargado como $fileName')),
    );
  }

  Uint8List _utf16leWithBom(String text) {
    final bom = <int>[0xFF, 0xFE];
    final cu = text.codeUnits;
    final bytes = BytesBuilder();
    bytes.add(bom);
    for (final unit in cu) {
      final low = unit & 0xFF;
      final high = (unit >> 8) & 0xFF;
      bytes.addByte(low);
      bytes.addByte(high);
    }
    return bytes.toBytes();
  }

  // ===========================
  // HELPERS
  // ===========================

  String getEstadoPiloto(Map<String, dynamic> data) {
    final otp = (data['otp'] as Map<String, dynamic>?) ?? {};
    final estadoOtp = (otp['estado'] ?? '').toString().trim().toLowerCase();

    // Mapea a tus labels del dashboard
    if (estadoOtp == 'pendiente') return 'pre_registro';

    // Si en el futuro guardas activado / por_activar en otro campo, lo sumas aquí:
    final status = (data['status'] ?? '').toString().trim().toLowerCase();
    if (status.isNotEmpty) return status;

    return 'pre_registro';
  }




  String normalizar(String texto) => removeDiacritics(texto.toLowerCase());

  DateTime? _convertirTimestampADateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  String _obtenerRangoSemana(DateTime fecha) {
    final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1)); // lunes
    final finSemana = inicioSemana.add(const Duration(days: 6)); // domingo
    return "Semana del ${DateFormat('dd MMM', 'es_CO').format(inicioSemana)} "
        "al ${DateFormat("dd MMM 'del' yyyy", 'es_CO').format(finSemana)}";
  }

  int calcularRowsPerPage(int total) {
    if (total <= 5) return total;
    if (total <= 10) return total;
    return 10;
  }

  Color _colorEstado(String status) {
    switch (status) {
      case 'activado':
        return Colors.green;
      case 'por_activar':
        return Colors.amber;
      case 'pre_registro':
        return Colors.blueGrey;
      case 'registrado':
        return primary;
      default:
        return Colors.grey;
    }
  }

  String _textoEstado(String status) {
    switch (status) {
      case 'activado':
        return 'Activado';
      case 'por_activar':
        return 'Por activar';
      case 'pre_registro':
        return 'Pre registro';
      case 'registrado':
        return 'Registrado';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  // ===========================
  // UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Panel piloto (Admin)',
      content: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: double.infinity,
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('pre_registro_ppl')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final docs = snapshot.data!.docs;

                // ===========================
                // CONTADORES DASHBOARD
                // ===========================
                int countActivado = 0;
                int countPorActivar = 0;
                int countPreRegistro = 0;

                for (final d in docs) {
                  final data = d.data() as Map<String, dynamic>;
                  final st = getEstadoPiloto(data);

                  if (st == 'activado') countActivado++;
                  if (st == 'por_activar') countPorActivar++;
                  if (st == 'pre_registro') countPreRegistro++;
                }

                // ===========================
                // FILTROS + BÚSQUEDA (COMBINADOS)
                // ===========================
                // 1) Copia docs
                List<QueryDocumentSnapshot> filteredDocs = docs.cast<QueryDocumentSnapshot>();

// 2) Si hay búsqueda, filtra por búsqueda
                if (searchQuery.trim().isNotEmpty) {
                  final q = normalizar(searchQuery);

                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Ajusta según tu estructura pre_registro_ppl
                    final ppl = (data['ppl'] as Map<String, dynamic>?) ?? {};
                    final acud = (data['acudiente'] as Map<String, dynamic>?) ?? {};

                    final pplNombre = normalizar("${ppl['nombres'] ?? ''} ${ppl['apellidos'] ?? ''}");
                    final pplDoc = normalizar("${ppl['numero_documento'] ?? ''}");

                    final acudNombre = normalizar("${acud['nombres'] ?? ''} ${acud['apellidos'] ?? ''}");
                    final acudDoc = normalizar("${acud['numero_documento'] ?? ''}");

                    final whatsapp = normalizar("${acud['celular'] ?? ''}");

                    return pplNombre.contains(q) ||
                        pplDoc.contains(q) ||
                        acudNombre.contains(q) ||
                        acudDoc.contains(q) ||
                        whatsapp.contains(q);
                  }).toList();
                }

// 3) Si NO hay búsqueda, aplica filtro por card
                if (searchQuery.trim().isEmpty && filterStatus != null) {
                  filteredDocs = filteredDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final st = getEstadoPiloto(data);  // ✅ AQUÍ la clave
                    return st == filterStatus;
                  }).toList();
                }


                // ===========================
                // ORDEN FECHA DESC
                // ===========================
                filteredDocs.sort((a, b) {
                  final fa = _convertirTimestampADateTime((a.data() as Map<String, dynamic>)['fechaRegistro']);
                  final fb = _convertirTimestampADateTime((b.data() as Map<String, dynamic>)['fechaRegistro']);
                  return (fb ?? DateTime(0)).compareTo(fa ?? DateTime(0));
                });

                // ===========================
                // AGRUPAR POR SEMANA
                // ===========================
                final Map<String, List<QueryDocumentSnapshot>> porSemana = {};
                final sinFecha = <QueryDocumentSnapshot>[];

                for (final doc in filteredDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final fecha = _convertirTimestampADateTime(data['fechaRegistro']);
                  if (fecha == null) {
                    sinFecha.add(doc);
                    continue;
                  }
                  final key = _obtenerRangoSemana(fecha);
                  porSemana.putIfAbsent(key, () => []).add(doc);
                }

                // ===========================
                // UI
                // ===========================
                return Column(
                  children: [
                    const SizedBox(height: 10),

                    // HEADER: total + search + descargar + whatsapp
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > 900;

                        final headerLeft = Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,          // 👈 evita que ocupe todo el ancho
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _TotalUsuariosCard(totalUsuarios: docs.length),
                              const SizedBox(width: 12),
                              SizedBox(width: 360, child: _buildSearchField()),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.download, color: Colors.black),
                                label: const Text(
                                  'Excel',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: exportPplCsvWeb,
                              ),
                            ],
                          ),
                        );
                        if (!isDesktop) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TotalUsuariosCard(totalUsuarios: docs.length),
                                const SizedBox(height: 10),
                                _buildSearchField(),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.download),
                                  label: const Text('Descargar base PPL (Excel)'),
                                  onPressed: exportPplCsvWeb,
                                ),
                                const SizedBox(height: 12),
                                //const WhatsAppChatWrapper(),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: headerLeft),
                              const SizedBox(width: 12),
                              //const SizedBox(width: 420, child: WhatsAppChatWrapper()),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: primary, height: 2),
                    const SizedBox(height: 18),

                    // DASHBOARD (filtro)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _DashChip(
                            label: "Todos",
                            count: docs.length,
                            color: Colors.black87,
                            selected: filterStatus == null && searchQuery.isEmpty,
                            onTap: () => setState(() {
                              filterStatus = null;
                              searchQuery = '';
                              _searchController.clear();
                            }),
                          ),

                          _DashChip(
                            label: "Activados",
                            count: countActivado,
                            color: Colors.green,
                            selected: filterStatus == 'activado',
                            onTap: () => setState(() {
                              filterStatus = 'activado';
                              searchQuery = '';
                              _searchController.clear();
                            }),
                          ),

                          _DashChip(
                            label: "Por activar",
                            count: countPorActivar,
                            color: Colors.amber,
                            selected: filterStatus == 'por_activar',
                            onTap: () => setState(() {
                              filterStatus = 'por_activar';
                              searchQuery = '';
                              _searchController.clear();
                            }),
                          ),

                          _DashChip(
                            label: "Pre registro",
                            count: countPreRegistro,
                            color: Colors.blueGrey,
                            selected: filterStatus == 'pre_registro',
                            onTap: () => setState(() {
                              filterStatus = 'pre_registro';
                              searchQuery = '';
                              _searchController.clear();
                            }),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // TABLAS POR SEMANA
                    if (filteredDocs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inbox, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              "No hay registros que mostrar.",
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          children: [
                            // Si hay docs sin fecha, muéstralos arriba
                            if (sinFecha.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                "Sin fecha de registro",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                              ),
                              const Divider(color: Colors.grey, thickness: 1),
                              _buildDataTable(sinFecha),
                              const SizedBox(height: 18),
                              const Divider(height: 30, thickness: 2, color: Colors.grey),
                              const SizedBox(height: 18),
                            ],

                            ...porSemana.entries.map((entry) {
                              final semanaTexto = entry.key;
                              final registros = entry.value;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    semanaTexto,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Divider(color: Colors.grey, thickness: 1),
                                  _buildDataTable(registros),
                                  const SizedBox(height: 18),
                                  const Divider(height: 30, thickness: 2, color: Colors.grey),
                                  const SizedBox(height: 18),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchQuery = normalizar(value)),
        decoration: InputDecoration(
          labelText: "Buscar (PPL, cédula, acudiente, WhatsApp)",
          floatingLabelBehavior: FloatingLabelBehavior.always,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => searchQuery = "");
            },
          )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> registros) {
    final rowsPerPage = calcularRowsPerPage(registros.length);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: PaginatedDataTable(
        header: const Text(''),
        rowsPerPage: rowsPerPage,
        showCheckboxColumn: false,
        columnSpacing: 36,
        columns: const [
          // ✅ Columnas EXACTAS que pediste:
          DataColumn(label: Text('PPL')),
          DataColumn(label: Text('Identificación')),
          DataColumn(label: Text('Acudiente')),
          DataColumn(label: Text('Parentesco')),
          DataColumn(label: Text('WhatsApp')),
          DataColumn(label: Text('Fecha registro')),
        ],
        source: _PilotoTablaDataSource(
          context: context,
          registros: registros,
          docIdSeleccionado: _docIdSeleccionado,
          convertirFecha: _convertirTimestampADateTime,
          colorEstado: _colorEstado,
          textoEstado: _textoEstado,
          onRowSelected: (doc) async {
            setState(() => _docIdSeleccionado = doc.id);

            Navigator.pushNamed(
              context,
              'editar_piloto',
              arguments: doc.id,
            );


            setState(() {});
          },
        ),
      ),
    );
  }
}

// ===========================
// DATA SOURCE PILOTO
// ===========================
class _PilotoTablaDataSource extends DataTableSource {
  final BuildContext context;
  final List<QueryDocumentSnapshot> registros;
  final String? docIdSeleccionado;

  final DateTime? Function(dynamic) convertirFecha;
  final Color Function(String) colorEstado;
  final String Function(String) textoEstado;
  final void Function(QueryDocumentSnapshot doc) onRowSelected;

  _PilotoTablaDataSource({
    required this.context,
    required this.registros,
    required this.docIdSeleccionado,
    required this.convertirFecha,
    required this.colorEstado,
    required this.textoEstado,
    required this.onRowSelected,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= registros.length) return null;

    final doc = registros[index];
    final data = doc.data() as Map<String, dynamic>;

    // ✅ Mapas anidados (pre_registro_ppl)
    final ppl = (data['ppl'] as Map<String, dynamic>?) ?? {};
    final acud = (data['acudiente'] as Map<String, dynamic>?) ?? {};
    final otp = (data['otp'] as Map<String, dynamic>?) ?? {};

    // ✅ Estado para dashboard/bolita (pre_registro)
    // Si quieres: usar otp.estado (pendiente/verificado/etc.)
    final otpEstado = (otp['estado'] ?? 'pendiente').toString().toLowerCase();

    // Para tu UI existente que espera "status"
    // Aquí lo "simulamos" como pre_registro o basado en otpEstado
    final status = 'pre_registro'; // o: otpEstado
    final color = colorEstado(status);
    final estadoTxt = textoEstado(status);

    // ✅ Datos PPL
    final nombrePpl = (ppl['nombres'] ?? '').toString();
    final apellidoPpl = (ppl['apellidos'] ?? '').toString();
    final docPpl = (ppl['numero_documento'] ?? '').toString();

    // ✅ Datos acudiente
    final nombreAcud = (acud['nombres'] ?? '').toString();
    final apellidoAcud = (acud['apellidos'] ?? '').toString();
    final whatsapp = (acud['celular'] ?? '').toString();
    final parentesco = (acud['parentesco'] ?? '').toString();

    // ✅ Fecha real de registro
    final fechaRegistro = convertirFecha(data['created_at']);

    // ✅ En tabla NO mostramos "Estado", pero sí lo ponemos al lado del nombre (pequeñito)
    Widget pplCell() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$nombrePpl $apellidoPpl".trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  // Puedes mostrar también otpEstado si quieres:
                  // "Pre registro · $otpEstado"
                  estadoTxt,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget acudienteCell() {
      return Text("${nombreAcud.trim()} ${apellidoAcud.trim()}".trim());
    }

    Widget fechaCell() {
      if (fechaRegistro == null) return const Text('-');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat("dd/MM/yyyy", 'es_CO').format(fechaRegistro),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            DateFormat("hh:mm a", 'es_CO').format(fechaRegistro),
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      );
    }

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onRowSelected(doc),
      color: MaterialStateProperty.resolveWith<Color?>((states) {
        if (docIdSeleccionado == doc.id) return Colors.yellow.withOpacity(0.2);
        return index % 2 == 0 ? Colors.white : Colors.blue.withOpacity(0.05);
      }),
      cells: [
        DataCell(pplCell()),
        DataCell(Text(docPpl)),
        DataCell(acudienteCell()),
        DataCell(Text(parentesco)),
        DataCell(Text(whatsapp)),
        DataCell(fechaCell()),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => registros.length;

  @override
  int get selectedRowCount => 0;
}

// ===========================
// WIDGETS PEQUEÑOS
// ===========================
class _TotalUsuariosCard extends StatelessWidget {
  final int totalUsuarios;
  const _TotalUsuariosCard({required this.totalUsuarios});

  @override
  Widget build(BuildContext context) {
    final fechaActual = "Hoy es ${DateFormat("d 'de' MMMM 'de' y", 'es_CO').format(DateTime.now())}";
    final esMobil = MediaQuery.of(context).size.width < 600;

    return Container(
      width: esMobil ? double.infinity : 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // 👈 centra horizontal
        children: [
          Text(
            fechaActual,
            textAlign: TextAlign.center, // 👈 centra el texto
            style: TextStyle(
              fontSize: esMobil ? 9 : 12,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalUsuarios.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: esMobil ? 16 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Usuarios Totales",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: esMobil ? 10 : 13,
            ),
          ),
        ],
      ),

    );
  }
}

class _DashChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _DashChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// ===========================
// WHATSAPP WRAPPER
// ===========================
class WhatsAppChatWrapper extends StatefulWidget {
  const WhatsAppChatWrapper({Key? key}) : super(key: key);

  @override
  State<WhatsAppChatWrapper> createState() => _WhatsAppChatWrapperState();
}

class _WhatsAppChatWrapperState extends State<WhatsAppChatWrapper> {
  String? _numeroCliente;
  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('whatsapp_messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshotMensajes) {
      if (!mounted) return;
      if (snapshotMensajes.docs.isNotEmpty) {
        final numero = snapshotMensajes.docs.first['conversationId']?.toString() ?? 'Sin número';
        setState(() => _numeroCliente = numero);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_numeroCliente == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WhatsAppChatSummary(numeroCliente: _numeroCliente!);
  }
}
