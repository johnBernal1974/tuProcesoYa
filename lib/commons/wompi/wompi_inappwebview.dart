import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/commons/wompi/transaction_failed_page.dart';

import '../../src/colors/colors.dart';

class WompiWebView extends StatefulWidget {
  final String url;
  final String referencia;

  const WompiWebView({super.key, required this.url, required this.referencia});

  @override
  _WompiWebViewState createState() => _WompiWebViewState();
}

class _WompiWebViewState extends State<WompiWebView> {
  late final WebViewController _webViewController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _firestore.collection("recargas").where("reference", isEqualTo: referencia)
        .snapshots().listen((event) {
      if (event.docs.isNotEmpty) {
        var transaction = event.docs.first;
        String status = transaction["status"];

        if (status == "APPROVED") {
          print("✅ Transacción aprobada, redirigiendo home");
          Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
        } else {
          print("❌ Transacción rechazada, redirigiendo a pantalla de error");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionFailedPage(),
            ),
          );
        }
      }
    });
  }
}
