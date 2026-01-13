import 'dart:html';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../helper/beneficios_helper.dart';
import '../../widgets/analisis_preliminar/resumen_analisis_condena.dart';
import '../../utils/pdf_download_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../utils/excel_download_helper.dart';
import '../../utils/excel_download_helper.dart';
import '../../utils/excel_share_helper.dart';


class ListadoPplPorBeneficioPage extends StatelessWidget {
  final BeneficioTipo beneficio;

  const ListadoPplPorBeneficioPage({
    super.key,
    required this.beneficio,
  });

  bool esPantallaGrande(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  // ---------------------------
  // ✅ CÁLCULO DINÁMICO (HOY)
  // ---------------------------

  int _diasEjecutadosHoy(DateTime fechaCaptura) {
    final now = DateTime.now();
    final f = DateTime(fechaCaptura.year, fechaCaptura.month, fechaCaptura.day);
    int d = now.difference(f).inDays;
    if (d < 0) d = 0;
    return d;
  }

  int _totalCondenaDias(Map<String, dynamic> data) {
    final v = data['total_condena_dias'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  int _diasRedimidos(Map<String, dynamic> data) {
    final v = data['dias_redimidos'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  DateTime? _fechaCaptura(Map<String, dynamic> data) {
    final ts = data['fecha_captura'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  double _reqPorcentaje(BeneficioTipo b) {
    switch (b) {
      case BeneficioTipo.permiso72:
        return 33.33;
      case BeneficioTipo.domiciliaria:
        return 50.0;
      case BeneficioTipo.condicional:
        return 60.0;
      case BeneficioTipo.extincion:
        return 100.0;
    }
  }

  int _diferenciaVsUmbral(Map<String, dynamic> data, BeneficioTipo tipo) {
    final fc = _fechaCaptura(data);
    if (fc == null) return -999999;

    final total = _totalCondenaDias(data);
    if (total <= 0) return -999999;

    final red = _diasRedimidos(data);
    final ejecutados = _diasEjecutadosHoy(fc);
    final cumplidos = ejecutados + red;

    final req = _reqPorcentaje(tipo);
    final umbral = (total * (req / 100)).round();

    return cumplidos - umbral;
  }

  BeneficioTipo? _beneficioMasAltoDinamico(Map<String, dynamic> data) {
    final diffExt = _diferenciaVsUmbral(data, BeneficioTipo.extincion);
    final diffCon = _diferenciaVsUmbral(data, BeneficioTipo.condicional);
    final diffDom = _diferenciaVsUmbral(data, BeneficioTipo.domiciliaria);
    final diff72 = _diferenciaVsUmbral(data, BeneficioTipo.permiso72);

    if (diffExt >= 0) return BeneficioTipo.extincion;
    if (diffCon >= 0) return BeneficioTipo.condicional;
    if (diffDom >= 0) return BeneficioTipo.domiciliaria;
    if (diff72 >= 0) return BeneficioTipo.permiso72;
    return null;
  }

  String _formatearDias(int dias) {
    if (dias <= 0) return '0 días';
    final meses = dias ~/ 30;
    final resto = dias % 30;
    if (meses > 0 && resto > 0) return '$meses meses y $resto días';
    if (meses > 0) return '$meses meses';
    return '$resto días';
  }

  String _textoEstadoBeneficioDinamicoUI(Map<String, dynamic> data, BeneficioTipo tipo) {
    final diff = _diferenciaVsUmbral(data, tipo);
    final bool cumple = diff >= 0;

    if (cumple) {
      return '✓ Desde hace ${_formatearDias(diff)}';
    } else {
      return '✗ Faltan ${_formatearDias(-diff)}';
    }
  }

  double _porcentajeHoy(Map<String, dynamic> data) {
    final fc = _fechaCaptura(data);
    if (fc == null) return 0;

    final total = _totalCondenaDias(data);
    if (total <= 0) return 0;

    final red = _diasRedimidos(data);
    final ejecutados = _diasEjecutadosHoy(fc);
    final cumplidos = ejecutados + red;

    return (cumplidos / total) * 100;
  }

  // ---------------------------
  // ✅ PDF (Landscape)
  // ---------------------------

  String abreviarTipoDocumento(String? tipo) {
    if (tipo == null) return '';

    final normalizado = tipo
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');

    switch (normalizado) {
      case 'cedula de ciudadania':
        return 'CC.';
      case 'cedula de extranjeria':
        return 'CE.';
      default:
        return '';
    }
  }

  Future<Uint8List> _buildPdfListado({
    required String titulo,
    required List<QueryDocumentSnapshot> docs,
  }) async {
    final now = DateTime.now();
    final fecha = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final rows = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
      final cedula = (data['numero_documento'] ?? '').toString();
      final tipoDoc = abreviarTipoDocumento(data['tipo_documento']?.toString());

      final td = (data['td'] ?? '').toString();
      final nui = (data['nui'] ?? '').toString();
      final patio = (data['patio'] ?? '').toString();

      final centro = (data['centro_reclusion_nombre'] ?? '').toString();
      final numeroProceso = (data['numero_proceso'] ?? '').toString();
      final porcentaje = _porcentajeHoy(data).toStringAsFixed(2);

      final tdNuiPatio =
          'TD: ${td.trim().isEmpty ? '—' : td.trim()}\n'
          'NUI: ${nui.trim().isEmpty ? '—' : nui.trim()}\n'
          'Patio: ${patio.trim().isEmpty ? '—' : patio.trim()}';

      final estados = beneficiosHasta(beneficio)
          .map((b) => '${tituloBeneficio(b)}: ${_textoEstadoBeneficioPdf(data, b)}')
          .join('\n'); // cada beneficio en su línea

      final docLinea = '$tipoDoc $cedula'.trim();
      final nombreYDoc =
          '${nombre.isEmpty ? '—' : nombre}\n${docLinea.isEmpty ? '—' : docLinea}';

      return <String>[
        nombreYDoc,
        tdNuiPatio,
        centro.trim().isEmpty ? '—' : centro.trim(),
        numeroProceso.trim().isEmpty ? '—' : numeroProceso.trim(),
        '$porcentaje%',
        estados.isEmpty ? '—' : estados,
      ];
    }).toList();

    final pdf = pw.Document();
    final pageFormat = PdfPageFormat.a4.landscape;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => [
          pw.Text(
            'Listado PPL con $titulo',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado: $fecha (cálculo dinámico a hoy)',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: const [
              'Nombre',
              'TD / NUI / Patio',
              'Centro de reclusión',
              'N° Proceso',
              '% hoy',
              'Estado del beneficio (a hoy)',
            ],
            data: rows,

            // ✅ Headers centrados
            headerAlignment: pw.Alignment.center,

            // ✅ Celdas a la izquierda
            cellAlignment: pw.Alignment.centerLeft,

            headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2),
              1: pw.FlexColumnWidth(0.9),
              2: pw.FlexColumnWidth(1.35),
              3: pw.FlexColumnWidth(1.1),
              4: pw.FlexColumnWidth(0.45),
              5: pw.FlexColumnWidth(1.9),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          ),

          pw.SizedBox(height: 10),
          pw.Text(
            'Total registros: ${rows.length}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _descargarPdfListado(BuildContext context, String titulo, List<QueryDocumentSnapshot> docs) async {
    try {
      final bytes = await _buildPdfListado(titulo: titulo, docs: docs);

      final now = DateTime.now();
      final filename =
          'listado_${titulo.replaceAll(" ", "_").toLowerCase()}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';

      if (kIsWeb) {
        downloadPdf(bytes, filename);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF generado correctamente.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generando PDF: $e')),
        );
      }
    }
  }

  // ---------------------------

  Future<Uint8List> _buildExcelListado({
    required String titulo,
    required List<QueryDocumentSnapshot> docs,
  }) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Listado';

    const headers = [
      'Nombre',
      'TD / NUI / Patio',
      'Centro de reclusión',
      'N° Proceso',
      '% hoy',
      'Estado del beneficio (a hoy)',
    ];

    // ----- Header style -----
    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#F2F2F2';
    headerStyle.hAlign = xlsio.HAlignType.center;
    headerStyle.vAlign = xlsio.VAlignType.center;
    headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

    // ----- Cell style -----
    final cellStyle = workbook.styles.add('cellStyle');
    cellStyle.hAlign = xlsio.HAlignType.left;
    cellStyle.vAlign = xlsio.VAlignType.center;
    cellStyle.wrapText = true;
    cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    cellStyle.fontSize = 10;

    // Header row (fila 1)
    for (int c = 0; c < headers.length; c++) {
      final range = sheet.getRangeByIndex(1, c + 1);
      range.setText(headers[c]);
      range.cellStyle = headerStyle;
    }

    // Altura del header
    sheet.getRangeByIndex(1, 1, 1, headers.length).rowHeight = 22;

    // Ajustes de columnas (anchos “bonitos”)
    sheet.getRangeByIndex(1, 1).columnWidth = 28; // A
    sheet.getRangeByIndex(1, 2).columnWidth = 20; // B
    sheet.getRangeByIndex(1, 3).columnWidth = 45; // C
    sheet.getRangeByIndex(1, 4).columnWidth = 40; // D
    sheet.getRangeByIndex(1, 5).columnWidth = 10; // E
    sheet.getRangeByIndex(1, 6).columnWidth = 45; // F


    // ❌ Freeze panes no soportado en XlsIO Flutter
    // sheet.freezePanes(2, 1);

    // Cargar filas
    int row = 2;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}'.trim();
      final cedula = (data['numero_documento'] ?? '').toString();
      final tipoDoc = abreviarTipoDocumento(data['tipo_documento']?.toString());
      final docLinea = '$tipoDoc $cedula'.trim();

      final td = (data['td'] ?? '').toString();
      final nui = (data['nui'] ?? '').toString();
      final patio = (data['patio'] ?? '').toString();

      final centro = (data['centro_reclusion_nombre'] ?? '').toString();
      final numeroProceso = (data['numero_proceso'] ?? '').toString();

      final porcentaje = _porcentajeHoy(data).toStringAsFixed(2);

      final tdNuiPatio =
          'TD: ${td.trim().isEmpty ? '—' : td.trim()}\n'
          'NUI: ${nui.trim().isEmpty ? '—' : nui.trim()}\n'
          'Patio: ${patio.trim().isEmpty ? '—' : patio.trim()}';

      final estados = beneficiosHasta(beneficio)
          .map((b) => '${tituloBeneficio(b)}: ${_textoEstadoBeneficioPdf(data, b)}')
          .join('\n');

      final nombreYDoc =
          '${nombre.isEmpty ? '—' : nombre}\n${docLinea.isEmpty ? '—' : docLinea}';

      final values = <String>[
        nombreYDoc,
        tdNuiPatio,
        centro.trim().isEmpty ? '—' : centro.trim(),
        numeroProceso.trim().isEmpty ? '—' : numeroProceso.trim(),
        '$porcentaje%',
        estados.isEmpty ? '—' : estados,
      ];

      for (int c = 0; c < values.length; c++) {
        final range = sheet.getRangeByIndex(row, c + 1);
        range.setText(values[c]);
        range.cellStyle = cellStyle;
      }

      // ✅ Altura de fila compatible (para que no quede “pegado”)
      sheet.getRangeByIndex(row, 1, row, headers.length).rowHeight = 55;

      row++;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }


  Future<void> _descargarExcelListado(
      BuildContext context,
      String titulo,
      List<QueryDocumentSnapshot> docs,
      ) async {
    try {
      final bytes = await _buildExcelListado(titulo: titulo, docs: docs);

      final now = DateTime.now();
      final filename =
          'listado_${titulo.replaceAll(" ", "_").toLowerCase()}_'
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';

      if (kIsWeb) {
        // ✅ WEB: descarga
        downloadExcel(bytes, filename);
      } else {
        // ✅ MOBILE/DESKTOP: compartir
        await shareExcelBytes(bytes, filename, text: 'Listado $titulo');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel generado correctamente.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generando Excel: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final String titulo = tituloBeneficio(beneficio);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('analisis_condena_ppl')
            .orderBy('fecha_calculo', descending: true)
            .limit(500)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Sin datos'));
          }

          final filtrados = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _beneficioMasAltoDinamico(data) == beneficio;
          }).toList();

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text('PPL con $titulo'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
              actions: [
                IconButton(
                  tooltip: 'Descargar PDF',
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: filtrados.isEmpty
                      ? null
                      : () => _descargarPdfListado(context, titulo, filtrados),
                ),
                IconButton(
                  tooltip: 'Descargar Excel',
                  icon: const Icon(Icons.grid_on), // o Icons.table_chart
                  onPressed: filtrados.isEmpty
                      ? null
                      : () => _descargarExcelListado(context, titulo, filtrados),
                ),
              ],

            ),
            body: filtrados.isEmpty
                ? const Center(child: Text('No hay personas con este beneficio (a hoy)'))
                : (esPantallaGrande(context)
                ? _tablaPC(context, filtrados)
                : _tarjetasMovil(context, filtrados)),
          );
        },
      ),
    );
  }

  Widget _tablaPC(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        columnSpacing: 8,
        columns: const [
          DataColumn(label: Center(child: Text('Nombre', style: TextStyle(fontSize: 11)))),
          DataColumn(label: Center(child: Text('TD / NUI / Patio', style: TextStyle(fontSize: 11)))),
          DataColumn(label: Center(child: Text('Centro de reclusión', style: TextStyle(fontSize: 11)))),
          DataColumn(label: Center(child: Text('N° Proceso', style: TextStyle(fontSize: 11)))),
          DataColumn(label: Center(child: Text('Estado del beneficio (a hoy)', style: TextStyle(fontSize: 11)))),
          DataColumn(label: Center(child: Text('% hoy', style: TextStyle(fontSize: 11)))),
        ],
        rows: docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final nombre = '${data['nombres'] ?? ''} ${data['apellidos'] ?? ''}';
          final cedula = (data['numero_documento'] ?? '').toString();
          final tipoDoc = abreviarTipoDocumento(data['tipo_documento']?.toString());

          final td = (data['td'] ?? '').toString();
          final nui = (data['nui'] ?? '').toString();
          final patio = (data['patio'] ?? '').toString();

          final centro = (data['centro_reclusion_nombre'] ?? '').toString();
          final numeroProceso = (data['numero_proceso'] ?? '').toString();

          final tdNuiPatio =
              'TD: ${td.trim().isEmpty ? '—' : td.trim()}\n'
              'NUI: ${nui.trim().isEmpty ? '—' : nui.trim()}\n'
              'Patio: ${patio.trim().isEmpty ? '—' : patio.trim()}';

          final estados = beneficiosHasta(beneficio)
              .map((b) => '${tituloBeneficio(b)}: ${_textoEstadoBeneficioPdf(data, b)}')
              .join('\n'); // cada beneficio en su línea


          final porcentaje = _porcentajeHoy(data);

          return DataRow(
            onSelectChanged: (_) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResumenAnalisisCondenaWidget(docId: doc.id),
                ),
              );
            },
            cells: [
              // ✅ Celdas a la izquierda
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tipoDoc $cedula',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                  ],
                ),
              ),

              DataCell(
                Text(
                  tdNuiPatio,
                  style: const TextStyle(fontSize: 11),
                ),
              ),

              DataCell(
                SizedBox(
                  width: 280,
                  child: Text(
                    centro,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ),

              DataCell(Text(numeroProceso, style: const TextStyle(fontSize: 11))),

              DataCell(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8), // ✅ más aire arriba/abajo
                  child: Text(
                    estados,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1, // ✅ separa las líneas entre sí
                    ),
                  ),
                ),
              ),

              DataCell(Text('${porcentaje.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 11))),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _textoEstadoBeneficioPdf(Map<String, dynamic> data, BeneficioTipo tipo) {
    final diff = _diferenciaVsUmbral(data, tipo);
    final bool cumple = diff >= 0;

    if (cumple) {
      return 'Desde hace ${_formatearDias(diff)}';
    } else {
      return 'Faltan ${_formatearDias(-diff)}';
    }
  }


  Widget _tarjetasMovil(BuildContext context, List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;

        final nombre = '${data['nombres']} ${data['apellidos']}';
        final cedula = data['numero_documento'] ?? '';

        final td = (data['td'] ?? '').toString();
        final nui = (data['nui'] ?? '').toString();
        final patio = (data['patio'] ?? '').toString();

        final listaBeneficios = beneficiosHasta(beneficio);
        final porcentaje = _porcentajeHoy(data);

        final tdNuiPatio =
            'TD: ${td.trim().isEmpty ? '—' : td.trim()}\n'
            'NUI: ${nui.trim().isEmpty ? '—' : nui.trim()}\n'
            'Patio: ${patio.trim().isEmpty ? '—' : patio.trim()}';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResumenAnalisisCondenaWidget(docId: docs[index].id),
              ),
            );
          },
          child: Card(
            color: Colors.white,
            elevation: 1.5,
            child: ExpansionTile(
              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('C.C. $cedula · Hoy: ${porcentaje.toStringAsFixed(2)}%'),
              childrenPadding: const EdgeInsets.all(12),
              children: [
                Text(tdNuiPatio, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...listaBeneficios.map(
                      (b) => Text(
                    '${tituloBeneficio(b)}: ${_textoEstadoBeneficioDinamicoUI(data, b)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
