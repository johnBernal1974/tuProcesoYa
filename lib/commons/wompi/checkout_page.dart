import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import 'package:tuprocesoya/commons/wompi/wompi_service.dart';
import 'package:tuprocesoya/src/colors/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WompiService _wompiService = WompiService();
  final TextEditingController _controller = TextEditingController();
  final NumberFormat _formatter = NumberFormat("#,###", "es_CO");
  final Uuid _uuid = Uuid();

  bool? _isPaid; // Estado de suscripción
  int? _subscriptionValue; // Valor de la suscripción
  int? _valorPago; // Monto ingresado o seleccionado

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }


  @override
  Widget build(BuildContext context) {
    if (_isPaid == null) {
      return const Scaffold(
        backgroundColor: blanco,
        body: Center(child: CircularProgressIndicator()), // Cargando datos
      );
    }

    if (_isPaid == false) {
      return MainLayout(
        pageTitle:"Pagar suscripción",
        content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Mantiene el logo a la izquierda
                children: [
                  // Logo alineado a la izquierda
                  Image.asset(
                    'assets/images/logo_tu_proceso_ya_transparente.png',
                    height: 30,
                  ),
                  const SizedBox(height: 50),

                  // Centrar todo el contenido excepto el logo
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      // Asegura que el contenido esté centrado
                      children: [
                        const Text(
                          "Gracias por confiar en nosotros, para obtener todos los beneficios de nuestra plataforma debes hacer el pago de la suscripción.",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, // Texto centrado
                        ),
                        const SizedBox(height: 20),

                        // Valor de la suscripción centrado
                        _subscriptionValue != null
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Valor de la suscripción",
                              style: TextStyle(fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                            Text(
                              "\$${_formatter.format(_subscriptionValue)}",
                              style: const TextStyle(fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        )
                            : const CircularProgressIndicator(),

                        const SizedBox(height: 30),

                        // Botón de pago centrado
                        ElevatedButton(
                          onPressed: _pagarSuscripcion,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: const Text("Pagar Suscripción"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      );
    }

    // Si isPaid es true, mostrar el campo de recarga
    return MainLayout(
      pageTitle:"Recargar cuenta",
      content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Mantiene el logo alineado a la izquierda
              children: [
                // Logo alineado a la izquierda
                Image.asset(
                  'assets/images/logo_tu_proceso_ya_transparente.png',
                  height: 30,
                ),
                const SizedBox(height: 30),

                // Centrar todo el contenido debajo del logo
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    // Asegura que el contenido esté centrado
                    children: [
                      const Text(
                        "Ingresa el monto a recargar",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),

                      // Campo de entrada del monto
                      SizedBox(
                        width: 180,
                        height: 45,
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixText: "\$ ",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey), // Borde gris por defecto
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.grey), // Borde gris cuando NO está enfocado
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: primary, width: 2), // Borde azul cuando está enfocado
                            ),
                          ),
                          onChanged: _actualizarValor,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botones rápidos para seleccionar monto
                      const Text("O selecciona un monto rápido:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [60000, 100000, 150000].map((monto) {
                          return ElevatedButton(
                            onPressed: () {
                              _seleccionarMonto(monto);
                              _controller.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Fondo blanco
                              foregroundColor: Colors.black, // Texto negro
                              side: const BorderSide(color: Colors.grey, width: 1), // Borde gris
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Espaciado
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Tamaño del texto
                            ),
                            child: Text("\$${_formatter.format(monto)}"),
                          );

                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      // Mostrar el monto seleccionado
                      _valorPago != null
                          ? Column(
                        children: [
                          const Text("Valor a recargar:", style: TextStyle(fontSize: 20,
                              fontWeight: FontWeight.bold, color: Colors.grey)),

                          Text("\$${_formatter.format(_valorPago)}",
                            style: const TextStyle(fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.black),
                          ),
                        ],
                      )
                          : const SizedBox(),

                      const SizedBox(height: 30),

                      // Botón de pagar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primary
                        ),
                        onPressed: iniciarPagoRecarga,
                        child: const Text("Pagar ahora", style: TextStyle(color: blanco)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }


  /// Obtiene el UID del usuario y verifica el estado de la suscripción
  Future<void> _checkSubscriptionStatus() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("⚠️ No hay usuario autenticado");
      return;
    }

    String uid = user.uid;
    print("🔹 UID del usuario: $uid");

    try {
      // Consultar Firestore para verificar el estado de pago del usuario
      DocumentSnapshot userDoc = await _firestore.collection("Ppl").doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _isPaid = userDoc["isPaid"];
        });

        if (_isPaid == false) {
          // Si no ha pagado, buscar el primer documento en "subscription"
          QuerySnapshot subscriptionSnapshot = await _firestore.collection("suscribcion").limit(1).get();

          if (subscriptionSnapshot.docs.isNotEmpty) {
            DocumentSnapshot subscriptionDoc = subscriptionSnapshot.docs.first;
            setState(() {
              _subscriptionValue = subscriptionDoc["valor"];
            });
          } else {
            print("⚠️ No se encontró información de la suscripción en Firestore.");
          }
        }

      }
    } catch (e) {
      print("⚠️ Error obteniendo datos de suscripción: $e");
    }
  }

  /// Permite la edición del monto y actualiza el valor a recargar
  void _actualizarValor(String value) {
    // ✅ Eliminamos caracteres no numéricos
    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    int parsedValue = int.tryParse(cleanValue) ?? 0;

    if (parsedValue == 0) {
      setState(() {
        _valorPago = null;
        _controller.clear();
      });
      return;
    }

    // ✅ Aplicamos formato con separador de miles
    String formattedValue = _formatter.format(parsedValue);

    setState(() {
      _valorPago = parsedValue;
      _controller.text = formattedValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length), // Mueve el cursor al final
      );
    });
  }


  /// Selecciona un monto predefinido desde los botones
  void _seleccionarMonto(int monto) {
    setState(() {
      _valorPago = monto;
    });
  }

  /// Inicia el pago de la suscripción
  void _pagarSuscripcion() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String userId = user.uid;
    if (_subscriptionValue == null) return;

    String referencia = "suscripcion_${userId}_${_uuid.v4()}";
    int montoCentavos = _subscriptionValue! * 100;

    String? checkoutUrl = await _wompiService.generarUrlCheckout(
      monto: montoCentavos,
      referencia: referencia,
    );

    if (checkoutUrl != null) {
      if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);

        // 🔥 Monitorea Firestore para detectar cambios en el pago
        _monitorearTransaccion(referencia);
      } else {
        print("❌ No se pudo abrir la URL de pago.");
      }
    } else {
      print("⚠️ No se generó la URL de pago.");
    }
  }

  void _monitorearTransaccion(String referencia) {
    FirebaseFirestore.instance
        .collection("recargas") // O usa "transacciones", si tu colección tiene otro nombre
        .where("reference", isEqualTo: referencia)
        .snapshots()
        .listen((event) {
      if (event.docs.isNotEmpty) {
        var transaction = event.docs.first;
        if (transaction["status"] == "APPROVED") {
          print("✅ Transacción aprobada, redirigiendo al Home...");
          Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
        }
      }
    });
  }


  /// Inicia el pago de recarga de saldo
  void iniciarPagoRecarga() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Debes iniciar sesión antes de pagar."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String userId = user.uid;
    if (_valorPago == null || _valorPago! < 20000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Ingresa un monto mayor o igual a \$20.000."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String referencia = "recarga_${userId}_${_uuid.v4()}"; // 🔥 Referencia única
    int montoCentavos = _valorPago! * 100;

    String? checkoutUrl = await _wompiService.generarUrlCheckout(
      monto: montoCentavos,
      referencia: referencia,
    );

    if (checkoutUrl != null) {
      if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);

        // 🔥 Monitorea Firestore para detectar el estado de la transacción
        _monitorearTransaccion(referencia);
      } else {
        print("❌ No se pudo abrir la URL de pago.");
      }
    } else {
      print("⚠️ No se generó la URL de pago.");
    }
  }
}
