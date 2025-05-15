import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoCondicional.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoDomiciliaria.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoPermiso72h.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoTrasladoProceso.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitoso_suscripcion.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitoso_tutela.dart';
import 'package:tuprocesoya/commons/wompi/reintento_extiocion_pena.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_72h.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_condicional.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_peticion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_subscripcion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_traslado_proceso.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_tutela.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/commons/wompi/pagoExistoso_peticion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_domiciliaria.dart';
import '../../src/colors/colors.dart';
import 'PagoExitosoExtincionPena.dart';

class WompiWebView extends StatefulWidget {
  final String url;
  final String referencia;
  final bool esPagoDerechoPeticion;
  final int? valorDerecho;
  final VoidCallback? onTransaccionAprobada;

  const WompiWebView({
    super.key,
    required this.url,
    required this.referencia,
    this.esPagoDerechoPeticion = false,
    this.valorDerecho,
    this.onTransaccionAprobada,
  });

  @override
  State<WompiWebView> createState() => _WompiWebViewState();
}

class _WompiWebViewState extends State<WompiWebView> {
  late final WebViewController _webViewController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _callbackEjecutado = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..loadRequest(Uri.parse(widget.url));
    _monitorearTransaccion(widget.referencia);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blancoCards,
      appBar: AppBar(
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white, size: 30),
        title: const Text("Hacer el pago", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }

  void _monitorearTransaccion(String referencia) {
    _firestore
        .collection("recargas")
        .where("reference", isEqualTo: referencia)
        .snapshots()
        .listen((event) async {
      if (event.docs.isNotEmpty && !_callbackEjecutado) {
        final transaction = event.docs.first;
        final String status = transaction["status"];
        final DateTime fechaCreacion = (transaction["createdAt"] as Timestamp).toDate();
        final int segundosTranscurridos = DateTime.now().difference(fechaCreacion).inSeconds;

        if (status == "DECLINED" && segundosTranscurridos > 60) {
          return;
        }

        if (status == "APPROVED") {
          _callbackEjecutado = true;
          final tipo = referencia.split("_").first;

          final double amount = (transaction["amount"] ?? 0).toDouble();
          final String transaccionId = transaction["transactionId"] ?? "N/A";
          final DateTime fecha = (transaction["createdAt"] as Timestamp).toDate();

          switch (tipo) {
            case 'peticion':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoDerechoPeticionPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;
            case 'suscripcion':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoSuscripcionPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                ),
              ));
              break;
            case 'tutela':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoTutelaPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;
            case 'domiciliaria':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoPrisionDomiciliariaPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;
            case 'permiso':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoPermiso72hPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;
            case 'condicional':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoLibertadCondicionalPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;
            case 'extincion':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoExtincionPenaPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;

            case 'traslado':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => PagoExitosoTrasladoProcesoPage(
                  montoPagado: amount,
                  transaccionId: transaccionId,
                  fecha: fecha,
                  onContinuar: () async {
                    widget.onTransaccionAprobada?.call();
                  },
                ),
              ));
              break;

            default:
              widget.onTransaccionAprobada?.call();
          }
        }

        if (status == "DECLINED") {
          _callbackEjecutado = true;
          final tipo = referencia.split("_").first;

          switch (tipo) {
            case 'peticion':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoPeticionPage(
                  referencia: referencia,
                  valorDerecho: widget.valorDerecho,
                  onTransaccionAprobada: widget.onTransaccionAprobada,
                ),
              ));
              break;
            case 'suscripcion':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoSuscripcionPage(
                  referencia: referencia,
                ),
              ));
              break;
            case 'tutela':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoTutelaPage(
                  referencia: referencia,
                ),
              ));
              break;
            case 'domiciliaria':
              print("📢 Reintento para domiciliaria con valor: ${widget.valorDerecho}");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ReintentoPagoPrisionDomiciliariaPage(
                    referencia: referencia,
                    valor: widget.valorDerecho,
                    onTransaccionAprobada: widget.onTransaccionAprobada,
                  ),
                ),
              );
              break;

            case 'permiso':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoPermiso72hPage(
                  referencia: referencia,
                  valor: widget.valorDerecho,
                  onTransaccionAprobada: widget.onTransaccionAprobada,
                ),
              ));
              break;
            case 'condicional':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoLibertadCondicionalPage(
                  referencia: referencia,
                  valor: widget.valorDerecho,
                  onTransaccionAprobada: widget.onTransaccionAprobada,
                ),
              ));
              break;
            case 'extincion':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoExtincionPenaPage(
                  referencia: referencia,
                  valor: widget.valorDerecho,
                  onTransaccionAprobada: widget.onTransaccionAprobada,
                ),
              ));
              break;
            case 'traslado':
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (_) => ReintentoPagoTrasladoProcesoPage(
                  referencia: referencia,
                  valor: widget.valorDerecho,
                  onTransaccionAprobada: widget.onTransaccionAprobada,
                ),
              ));
              break;

            default:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("El pago fue rechazado. Por favor, intenta nuevamente."),
                ),
              );
          }
        }
      }
    });
  }

}
