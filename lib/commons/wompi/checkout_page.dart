import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import 'package:tuprocesoya/commons/wompi/webview.dart';
import 'package:tuprocesoya/commons/wompi/wompi_service.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../helper/pago_helper.dart';

class CheckoutPage extends StatefulWidget {
  final String tipoPago; // 'derecho_peticion', 'tutela', 'prision_domiciliaria', etc.
  final int valor;
  final String? referencia;
  final VoidCallback? onTransaccionAprobada;

  const CheckoutPage({
    super.key,
    required this.tipoPago,
    required this.valor,
    this.referencia,
    this.onTransaccionAprobada,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WompiService _wompiService = WompiService();
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat("#,###", "es_CO");
  final Uuid _uuid = const Uuid();

  bool? _isPaid;
  int? _subscriptionValue;
  int? _valorPago;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection("Ppl").doc(user.uid).get();
    setState(() {
      _isPaid = userDoc["isPaid"];
    });

    if (_isPaid == false) {
      QuerySnapshot config = await _firestore.collection("configuraciones").limit(1).get();
      if (config.docs.isNotEmpty) {
        setState(() {
          _subscriptionValue = config.docs.first["valor_subscripcion"];
        });
      }
    }
  }

  void _actualizarValor(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    int parsed = int.tryParse(clean) ?? 0;
    setState(() {
      _valorPago = parsed == 0 ? null : parsed;
      _controller.text = _formatter.format(parsed);
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
  }

  void _seleccionarMonto(int monto) {
    setState(() {
      _valorPago = monto;
    });
  }

  void _pagarSuscripcion() async {
    User? user = _auth.currentUser;
    if (user == null || _subscriptionValue == null) return;

    String referencia = "suscripcion_${user.uid}_${_uuid.v4()}";
    int centavos = _subscriptionValue! * 100;

    await PagoHelper.iniciarFlujoPago(
      context: context,
      centavos: centavos,
      referencia: referencia,
      buildCheckoutWidget: (url) => WompiWebView(
        url: url,
        referencia: referencia,
        onTransaccionAprobada: () async {
          print("✅ Suscripción pagada con referencia: $referencia");
          await FirebaseFirestore.instance
              .collection("Ppl")
              .doc(user.uid)
              .update({
            "isPaid": true,
            "fechaSuscripcion": FieldValue.serverTimestamp(),
          });

          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(context, 'home', (r) => false);
          }
        },
      ),
    );
  }


  void iniciarPagoRecarga() async {
    User? user = _auth.currentUser;

    if (user == null || _valorPago == null || _valorPago! < 20000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes ingresar una recarga mínima de \$20.000."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String referencia = "recarga_${user.uid}_${_uuid.v4()}";
    int centavos = _valorPago! * 100;

    await PagoHelper.iniciarFlujoPago(
      context: context,
      centavos: centavos,
      referencia: referencia,
      buildCheckoutWidget: (url) => WompiWebView(url: url, referencia: referencia),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si es un pago por algún servicio específico
    final tiposPagos = {
      'peticion': 'Derecho de petición',
      'tutela': 'Tutela',
      'domiciliaria': 'Prisión domiciliaria',
      'permiso': 'Permiso de 72 horas',
      'condicional': 'Libertad condicional',
      'extincion': 'Extinción de la pena',
      'traslado': 'Traslado de proceso',
      'redenciones': 'Redenciones',
      'acumulacion': 'Acumulación de penas',
      'apelacion': 'Apelación'
    };

    if (tiposPagos.containsKey(widget.tipoPago)) {
      String nombre = tiposPagos[widget.tipoPago]!;
      String referencia = widget.referencia ?? "${widget.tipoPago}_${_auth.currentUser?.uid}_${_uuid.v4()}";

      return MainLayout(
        pageTitle: nombre,
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                  children: [
                    const TextSpan(text: "Para enviar tu solicitud de "),
                    TextSpan(
                      text: nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const TextSpan(text: ", debes realizar el pago respectivo."),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 10),
                child: Column(
                  children: [
                    const Text("Valor", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(" \$${_formatter.format(widget.valor)}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: () async {
                  int centavos = widget.valor * 100;
                  await PagoHelper.iniciarFlujoPago(
                    context: context,
                    centavos: centavos,
                    referencia: referencia,
                    buildCheckoutWidget: (url) => WompiWebView(
                      url: url,
                      referencia: referencia,
                      esPagoDerechoPeticion: widget.tipoPago == 'derecho_peticion',
                      valorDerecho: widget.valor,
                      onTransaccionAprobada: widget.onTransaccionAprobada,
                    ),
                  );
                },
                child: const Text("Pagar ahora", style: TextStyle(color: blanco)),
              )
            ],
          ),
        ),
      );
    }

    if (_isPaid == null) {
      return const Scaffold(
        backgroundColor: blanco,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isPaid == false) {
      return MainLayout(
        pageTitle: "Pagar suscripción",
        content: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text("Gracias por confiar en nosotros. Esta herramienta está diseñada para brindarte apoyo real y facilitar el ejercicio de tus derechos. Estamos contigo en cada paso.",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, height: 1.2), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              const Text(
                "Para acceder a todos nuestros servicios a precios justos, necesitas una suscripción activa. Esta se renueva cada 6 meses y te permite usar la plataforma sin límites, enviar solicitudes legales, hacer seguimiento detallado y recibir notificaciones sobre tus trámites. Además, toda tu información estará protegida y respaldada.",
                style: TextStyle(fontSize: 14, height: 1.2),
                textAlign: TextAlign.center,
              ),

              // const SizedBox(height: 10),
              // const Text("¡Este valor se paga una única vez!",
              //     style: TextStyle(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              if (_subscriptionValue != null)
                Container(
                  color: blanco,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      const Text("Valor de la suscripción", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 11)),
                      Text("\$${_formatter.format(_subscriptionValue)}", style: const TextStyle(fontSize: 22, color: negro)),
                    ],
                  ),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 70),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primary),
                onPressed: _pagarSuscripcion,
                child: const Text("Pagar Suscripción", style: TextStyle(color: blanco)),
              )
            ],
          ),
        ),
      );
    }

    return MainLayout(
      pageTitle: "Recargar cuenta",
      content: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text("Ingresa el monto a recargar"),
            const SizedBox(height: 15),
            SizedBox(
              width: 180,
              height: 45,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: "\$ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: _actualizarValor,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [60000, 100000, 150000].map((monto) {
                return ElevatedButton(
                  onPressed: () {
                    _seleccionarMonto(monto);
                    _controller.clear();
                  },
                  child: Text("\$${_formatter.format(monto)}"),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            if (_valorPago != null)
              Column(
                children: [
                  Text("Valor a recargar: \$${_formatter.format(_valorPago)}"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: iniciarPagoRecarga,
                    child: const Text("Pagar ahora"),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }
}
