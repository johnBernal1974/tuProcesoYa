import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Pages/administrador/listado_ppl_por_beneficio_page.dart';
import '../../helper/beneficios_helper.dart';
import '../../utils/pdf_download_helper.dart';

class ReporteBeneficiosINPECPage extends StatelessWidget {
  const ReporteBeneficiosINPECPage({super.key});

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

    return cumplidos - umbral; // >=0 cumple
  }

  /// ✅ Beneficio más alto calculado HOY (Extinción > Condicional > Domiciliaria > 72)
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

  // ---------------------------
  // ✅ PDF
  // ---------------------------

  Future<Uint8List> _buildPdf({
    required int c72,
    required int cDom,
    required int cCon,
    required int cExt,
  }) async {
    final now = DateTime.now();
    final fecha = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          pw.Widget fila(String label, int value) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(value.toString(), style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          final total = c72 + cDom + cCon + cExt;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte INPEC - Beneficios (Dinámico)',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Fecha de generación: $fecha', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 14),

              pw.Text('Resumen de cantidades (a la fecha):',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              fila('72 horas', c72),
              fila('Prisión domiciliaria', cDom),
              fila('Libertad condicional', cCon),
              fila('Extinción de la pena', cExt),

              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(total.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),
              pw.Text(
                'Nota: Este reporte se calcula dinámicamente usando la fecha de captura + condena + redenciones registradas en el sistema, y la fecha actual.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _descargarPdf(BuildContext context, int c72, int cDom, int cCon, int cExt) async {
    try {
      final bytes = await _buildPdf(c72: c72, cDom: cDom, cCon: cCon, cExt: cExt);

      final now = DateTime.now();
      final filename =
          'reporte_inpec_beneficios_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';

      if (kIsWeb) {
        downloadPdf(bytes, filename); // ✅ descarga directa
      } else {
        await Printing.sharePdf(bytes: bytes, filename: filename); // ✅ compartir/guardar
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

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('analisis_condena_ppl')
        .orderBy('created_at', descending: true)
        .limit(500);

    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('Sin datos')),
          );
        }

        final docs = snap.data!.docs;

        int c72 = 0, cDom = 0, cCon = 0, cExt = 0;

        for (final d in docs) {
          final m = d.data() as Map<String, dynamic>;
          final top = _beneficioMasAltoDinamico(m);
          if (top == null) continue;

          switch (top) {
            case BeneficioTipo.permiso72:
              c72++;
              break;
            case BeneficioTipo.domiciliaria:
              cDom++;
              break;
            case BeneficioTipo.condicional:
              cCon++;
              break;
            case BeneficioTipo.extincion:
              cExt++;
              break;
          }
        }

        Widget tarjeta(BeneficioTipo tipo, int count, IconData icon) {
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListadoPplPorBeneficioPage(beneficio: tipo),
                ),
              );
            },
            child: Card(
              color: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(icon, size: 28, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tituloBeneficio(tipo),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cantidad: $count (a hoy)',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black54),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Reporte INPEC - Beneficios'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            actions: [
              IconButton(
                tooltip: 'Descargar PDF',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _descargarPdf(context, c72, cDom, cCon, cExt),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;

              if (w < 900) {
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    tarjeta(BeneficioTipo.permiso72, c72, Icons.timer),
                    tarjeta(BeneficioTipo.domiciliaria, cDom, Icons.home),
                    tarjeta(BeneficioTipo.condicional, cCon, Icons.verified),
                    tarjeta(BeneficioTipo.extincion, cExt, Icons.done_all),
                  ],
                );
              }

              DataRow fila(BeneficioTipo tipo, int cantidad, IconData icon) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Icon(icon, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            tituloBeneficio(tipo),
                            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          cantidad.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                    DataCell(
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListadoPplPorBeneficioPage(beneficio: tipo),
                            ),
                          );
                        },
                        child: const Text('Ver listado', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: DataTable(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                  columnSpacing: 40,
                  columns: const [
                    DataColumn(
                      label: Text('Beneficio', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Cantidad (a hoy)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    DataColumn(
                      label: Text('Acción', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  rows: [
                    fila(BeneficioTipo.permiso72, c72, Icons.timer),
                    fila(BeneficioTipo.domiciliaria, cDom, Icons.home),
                    fila(BeneficioTipo.condicional, cCon, Icons.verified),
                    fila(BeneficioTipo.extincion, cExt, Icons.done_all),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
