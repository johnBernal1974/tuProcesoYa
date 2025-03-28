import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/wompi/pagoExistoso_peticion.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/commons/wompi/transaction_failed_page.dart';

import '../../src/colors/colors.dart';

class WompiWebView extends StatefulWidget {
  final String url;
  final String referencia;
  final bool esPagoDerechoPeticion;
  final VoidCallback? onTransaccionAprobada;

  const WompiWebView({
    Key? key,
    required this.url,
    required this.referencia,
    this.esPagoDerechoPeticion = false,
    this.onTransaccionAprobada,
  }) : super(key: key);

  @override
  _WompiWebViewState createState() => _WompiWebViewState();
}


class _WompiWebViewState extends State<WompiWebView> {
  late final WebViewController _webViewController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _callbackEjecutado = false;


  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..loadRequest(Uri.parse(widget.url)); // ❌ Elimina setJavaScriptMode (Web no lo soporta)

    _monitorearTransaccion(widget.referencia);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blancoCards,
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: const Text(
          "Hacer el pago",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),

      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }

  /// **Monitorea el estado de la transacción en Firestore**
  void _monitorearTransaccion(String referencia) {
    _firestore
        .collection("recargas")
        .where("reference", isEqualTo: referencia)
        .snapshots()
        .listen((event) {
      if (event.docs.isNotEmpty && !_callbackEjecutado) {
        var transaction = event.docs.first;
        String status = transaction["status"];
        _callbackEjecutado = true; // ⚠️ importante para evitar múltiples llamadas

        if (status == "APPROVED") {
          if (widget.esPagoDerechoPeticion && widget.onTransaccionAprobada != null) {
            final double amount = (transaction["amount"] ?? 0).toDouble();
            final String transaccionId = transaction["transactionId"] ?? "N/A";
            final DateTime fecha = (transaction["createdAt"] as Timestamp).toDate();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PagoExitosoDerechoPeticionPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: widget.onTransaccionAprobada!,
                ),
              ),
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
          }
        }

        // ✅ Manejo si es DECLINED
        else if (status == "DECLINED") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TransactionFailedPage()),
          );
        }
      }
    });
  }


}
