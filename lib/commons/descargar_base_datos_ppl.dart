import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExportarPplCsvWebWidget extends StatefulWidget {
  const ExportarPplCsvWebWidget({Key? key}) : super(key: key);

  @override
  State<ExportarPplCsvWebWidget> createState() => _ExportarPplCsvWebWidgetState();
}

class _ExportarPplCsvWebWidgetState extends State<ExportarPplCsvWebWidget> {
  final _pplRef = FirebaseFirestore.instance.collection('Ppl');
  bool _exporting = false;

  Future<void> _exportarCsv() async {
    setState(() => _exporting = true);
    try {
      final snapshot = await _pplRef.get();
      final docs = snapshot.docs;

      // Cabeceras con punto y coma
      final List<String> rows = [
        'id;nombre_acudiente;apellido_acudiente;apellido_ppl;celular;celularWhatsapp;centro_reclusion;ciudad;nombre_completo_ppl'
      ];

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final id = doc.id;
        final nombreAcudiente = data['nombre_acudiente'] ?? '';
        final apellidoAcudiente = data['apellido_acudiente'] ?? '';
        final apellidoPpl = data['apellido_ppl'] ?? '';
        final celular = data['celular'] ?? '';
        final celularWhatsapp = data['celularWhatsapp'] ?? '';
        final centroReclusion = data['centro_reclusion'] ?? '';
        final ciudad = data['ciudad'] ?? '';
        final nombrePpl = data['nombre_ppl'] ?? '';
        final nombreCompletoPpl = '$nombrePpl $apellidoPpl'.trim();

        final row = [
          id,
          _limpiar(nombreAcudiente),
          _limpiar(apellidoAcudiente),
          _limpiar(apellidoPpl),
          _limpiar(celular),
          _limpiar(celularWhatsapp),
          _limpiar(centroReclusion),
          _limpiar(ciudad),
          _limpiar(nombreCompletoPpl),
        ].join(';'); // ← usamos punto y coma
        rows.add(row);
      }

      final csvString = rows.join('\n');

      // Agregar el BOM UTF-8 para que Excel interprete bien los acentos y eñes
      final bomUtf8 = utf8.encode('\uFEFF');
      final bytes = utf8.encode(csvString);
      final fullBytes = [...bomUtf8, ...bytes];

      final blob = html.Blob([fullBytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Base_PPL_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo CSV descargado correctamente')),
      );
    } catch (e, st) {
      debugPrint('Error exportando CSV: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _exporting = false);
    }
  }

  String _limpiar(String value) {
    return value.replaceAll(';', ',').replaceAll('\n', ' ').replaceAll('\r', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar base PPL')),
      body: Center(
        child: ElevatedButton.icon(
          icon: _exporting
              ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download),
          label: Text(_exporting ? 'Exportando...' : 'Descargar CSV para Excel'),
          onPressed: _exporting ? null : _exportarCsv,
        ),
      ),
    );
  }
}
