
import 'dart:typed_data';

void downloadPdf(Uint8List bytes, String filename) {
  // En móvil/desktop no descargamos con navegador.
  // Se manejará con Printing.sharePdf(...) en el widget.
}
