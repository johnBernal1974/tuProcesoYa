import 'dart:html' as html;
import 'package:flutter/material.dart';

class PDFViewer extends StatelessWidget {
  final String pdfUrl;

  PDFViewer({required this.pdfUrl});

  void abrirPDF() {
    html.window.open(pdfUrl, "_blank"); // Abre en nueva pestaña
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: abrirPDF,
      child: Text("Ver PDF"),
    );
  }
}
