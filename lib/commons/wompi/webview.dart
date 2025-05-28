import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tuprocesoya/commons/wompi/reintento_extiocion_pena.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Importa todas las páginas de éxito y reintento...
import 'package:tuprocesoya/commons/wompi/pagoExitosoCondicional.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoDomiciliaria.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoPermiso72h.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitosoTrasladoProceso.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitoso_suscripcion.dart';
import 'package:tuprocesoya/commons/wompi/pagoExitoso_tutela.dart';
import 'package:tuprocesoya/commons/wompi/pago_exitoso_acumulacion.dart';
import 'package:tuprocesoya/commons/wompi/pago_exitoso_redenciones.dart';
import 'package:tuprocesoya/commons/wompi/pagoExistoso_peticion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_72h.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_acumulacion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_condicional.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_domiciliaria.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_peticion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_redenciones.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_subscripcion.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_traslado_proceso.dart';
import 'package:tuprocesoya/commons/wompi/reintento_pago_tutela.dart';
import '../../src/colors/colors.dart';
import 'PagoExitosoExtincionPena.dart';

class WompiWebView extends StatefulWidget {
  final String url;
  final String referencia;
  final bool esPagoDerechoPeticion;
  final int? valorDerecho;
  final VoidCallback? onTransaccionAprobada;

  const WompiWebView({super.key, required this.url, required this.referencia, this.esPagoDerechoPeticion = false, this.valorDerecho, this.onTransaccionAprobada});

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
    _webViewController = WebViewController()..loadRequest(Uri.parse(widget.url));
    _monitorearTransaccion(widget.referencia);
  }

  void _monitorearTransaccion(String referencia) {
    debugPrint("\u{1F4E1} Escuchando cambios en recargas para referencia: $referencia");

    _firestore
        .collection("recargas")
        .where("reference", isEqualTo: referencia)
        .snapshots()
        .listen((event) async {
      if (event.docs.isEmpty) {
        debugPrint("! No se encontró ningún documento con esa referencia aún.");
        return;
      }

      final doc = event.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      final String status = data["status"];
      final String transaccionId = data["transactionId"] ?? "N/A";
      final double amount = (data["amount"] ?? 0).toDouble();
      final DateTime fecha = (data["createdAt"] as Timestamp).toDate();
      final int segundosTranscurridos = DateTime.now().difference(fecha).inSeconds;
      final tipo = referencia.split("_").first;

      debugPrint("\u{1F4E5} Documento encontrado. Status: $status. Tipo: $tipo");

      if (_callbackEjecutado) {
        debugPrint("⛔ Callback ya ejecutado.");
        return;
      }

      if (status == "APPROVED") {
        _callbackEjecutado = true;
        await _navegarSiMontado(_paginaExito(tipo, amount, transaccionId, fecha));
      }


      debugPrint("⌛ Tiempo transcurrido desde creación del doc: $segundosTranscurridos segundos");

      if (status == "DECLINED" && segundosTranscurridos > 2) {
        _callbackEjecutado = true;
        final page = _paginaReintento(tipo);
        await _navegarSiMontado(page); // 👈 también aquí
      }

    });
  }

  Widget _paginaExito(String tipo, double monto, String id, DateTime fecha) {
    switch (tipo) {
      case 'peticion':
        return PagoExitosoDerechoPeticionPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'suscripcion':
        return PagoExitosoSuscripcionPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'tutela':
        return PagoExitosoTutelaPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'domiciliaria':
        return PagoExitosoPrisionDomiciliariaPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'permiso':
        return PagoExitosoPermiso72hPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'condicional':
        return PagoExitosoLibertadCondicionalPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'extincion':
        return PagoExitosoExtincionPenaPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'traslado':
        return PagoExitosoTrasladoProcesoPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'redenciones':
        return PagoExitosoRedencionPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      case 'acumulacion':
        return PagoExitosoAcumulacionPenasPage(
          montoPagado: monto,
          transaccionId: id,
          fecha: fecha,
          onContinuar: () async {
            widget.onTransaccionAprobada?.call();
          },
        );
      default:
        return const Scaffold(
          body: Center(
            child: Text("Tipo de pago no reconocido"),
          ),
        );
    }

  }

  Widget _paginaReintento(String tipo) {
    switch (tipo) {
      case 'peticion':
        return ReintentoPagoPeticionPage(
          referencia: widget.referencia,
          valorDerecho: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'suscripcion':
        return ReintentoPagoSuscripcionPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho, // ✅ Se agregó el valor
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'tutela':
        return ReintentoPagoTutelaPage(
          referencia: widget.referencia,
          valorTutela: widget.valorDerecho, // ✅ FALTA ORIGINAL
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'domiciliaria':
        return ReintentoPagoPrisionDomiciliariaPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'permiso':
        return ReintentoPagoPermiso72hPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'condicional':
        return ReintentoPagoLibertadCondicionalPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'extincion':
        return ReintentoPagoExtincionPenaPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'traslado':
        return ReintentoPagoTrasladoProcesoPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'redenciones':
        return ReintentoPagoRedencionPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      case 'acumulacion':
        return ReintentoPagoAcumulacionPenasPage(
          referencia: widget.referencia,
          valor: widget.valorDerecho,
          onTransaccionAprobada: widget.onTransaccionAprobada,
        );

      default:
        return const Scaffold(
          body: Center(child: Text("No se pudo procesar el pago. Intenta de nuevo.")),
        );
    }
  }


  Future<void> _navegarSiMontado(Widget page) async {
    if (!mounted) {
      debugPrint("⛔ Contexto desmontado, cancelando navegación.");
      return;
    }

    debugPrint("🚀 Navegando a: ${page.runtimeType}");
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
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
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _webViewController)),
          Container(
            color: Colors.amber.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Por favor, no cierres esta página hasta que el pago haya sido completado.", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
