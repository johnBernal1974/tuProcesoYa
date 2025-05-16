import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../commons/wompi/checkout_page.dart';
import '../../../src/colors/colors.dart';
import '../../../widgets/selector_centro_reclusion.dart';
import '../solicitud_exitosa_extincion_pena/solicitud_exitosa_extincion_pena.dart';
import '../solucitud_exitosa_traslado_proceso/solucitud_exitosa_traslado_proceso.dart';

class SolicitudTrasladoProcesoPage extends StatefulWidget {
  const SolicitudTrasladoProcesoPage({super.key});

  @override
  State<SolicitudTrasladoProcesoPage> createState() => _SolicitudTrasladoProcesoPageState();
}

class _SolicitudTrasladoProcesoPageState extends State<SolicitudTrasladoProcesoPage> {

  String? selectedCentro;
  String? selectedRegional;
  List<Map<String, String>> centrosReclusionTodos = [];
  String? selectedCentroNombre;

  String? centroOrigenId;
  String? centroOrigenNombre;
  String? centroOrigenRegional;

  String? centroDestinoId;
  String? centroDestinoNombre;
  String? centroDestinoRegional;

  bool _errorCentroOrigen = false;
  bool _errorCentroDestino = false;
  bool _errorCiudadOrigen = false;
  bool _errorCiudadDestino = false;


  static const List<String> ciudadesConCarceles = [
    'Acacías',
    'Apartadó',
    'Armenia',
    'Barranquilla',
    'Bogotá',
    'Bucaramanga',
    'Cali',
    'Cartagena',
    'Cereté',
    'Ciénaga',
    'Cúcuta',
    'Espinal',
    'Facatativá',
    'Florencia',
    'Fusagasugá',
    'Girardot',
    'Guaduas',
    'Honda',
    'Ibagué',
    'Inírida',
    'Ipiales',
    'Jamundí',
    'Leticia',
    'Manizales',
    'Medellín',
    'Mitú',
    'Mocoa',
    'Montería',
    'Neiva',
    'Palmira',
    'Pasto',
    'Pereira',
    'Popayán',
    'Puerto Carreño',
    'Quibdó',
    'Riohacha',
    'San Andrés',
    'San José del Guaviare',
    'Santa Marta',
    'Sincelejo',
    'Soacha',
    'Sogamoso',
    'Tunja',
    'Tuluá',
    'Valledupar',
    'Villavicencio',
    'Yopal',
    'Zipaquirá',
  ];


  String? ciudadCentroOrigen;
  String? ciudadCentroDestino;



  @override
  void initState() {
    super.initState();
    _fetchTodosCentrosReclusion();
  }

  Future<void> _fetchTodosCentrosReclusion() async {
    final snapshot = await FirebaseFirestore.instance.collectionGroup('centros_reclusion').get();
    setState(() {
      centrosReclusionTodos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, String>{
          'id': doc.id,
          'nombre': data['nombre']?.toString() ?? '',
          'regional': doc.reference.parent.parent?.id.toString() ?? '',
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: const Text('Solicitud traslado de proceso', style: TextStyle(color: blanco)),
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: '🧾 Solicitud de traslado de proceso de ejecución de la pena\n\n',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const TextSpan(
                      text:
                      'En algunos casos, las personas privadas de la libertad son trasladadas a centros penitenciarios ubicados en ciudades distintas a donde se dictó su condena. '
                          'Esto puede generar dificultades para acceder a beneficios como la ',
                    ),
                    const TextSpan(
                      text: 'libertad condicional, los permisos de 72 horas o las redenciones',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                      ', ya que el juez que lleva su proceso sigue estando en otro lugar.\n\n',
                    ),
                    const TextSpan(
                      text: 'Con esta solicitud, puedes pedir que el ',
                    ),
                    const TextSpan(
                      text: 'proceso de ejecución de la pena sea trasladado ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                      'al juzgado de ejecución de penas del lugar donde actualmente estás recluido, facilitando así el ',
                    ),
                    const TextSpan(
                      text:
                      'acceso a la justicia, el seguimiento de tu condena y la presentación de nuevas solicitudes.\n\n',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(
                      text:
                      'Este trámite no cambia tu condena, pero permite que el juez que vigila su cumplimiento esté más cerca de ti.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Divider(color: gris),
              const SizedBox(height: 25),
              const Text('Suministra la siguiente información', style: TextStyle(fontSize: 18, color: negro, fontWeight: FontWeight.w900)),
              const SizedBox(height: 25),
              const Text('Centro penitenciario donde se encontraba', style: TextStyle(fontSize: 14, color: negro, fontWeight: FontWeight.w700)),
              const Text('Ingresa el nombre de la ciudad y te aparecerá la opción para seleccionar el centro de reclusión',
                  style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              // Centro ORIGEN
              CentroReclusionSelector(
                centros: centrosReclusionTodos,
                centroSeleccionadoNombre: centroOrigenNombre,
                error: _errorCentroOrigen,
                onSelected: (centro) {
                  setState(() {
                    centroOrigenNombre = centro['nombre'];
                    centroOrigenRegional = centro['regional'];
                    _errorCentroOrigen = false; // limpia error si selecciona bien
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildDropdownCiudad(
                label: 'Ciudad del centro de reclusión de origen',
                valorSeleccionado: ciudadCentroOrigen,
                onChanged: (val) => setState(() => ciudadCentroOrigen = val),
              ),
              const SizedBox(height: 30),
              const Text('Centro penitenciario a donde fue trasladado', style: TextStyle(fontSize: 14, color: negro, fontWeight: FontWeight.w700)),
              const Text('Ingresa el nombre de la ciudad y te aparecerá la opción para seleccionar el centro de reclusión',
                  style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              // Centro DESTINO
              CentroReclusionSelector(
                centros: centrosReclusionTodos,
                centroSeleccionadoNombre: centroDestinoNombre,
                error: _errorCentroDestino,
                onSelected: (centro) {
                  setState(() {
                    centroDestinoNombre = centro['nombre'];
                    centroDestinoRegional = centro['regional'];
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildDropdownCiudad(
                label: 'Ciudad del centro re reclusión de destino',
                valorSeleccionado: ciudadCentroDestino,
                onChanged: (val) => setState(() => ciudadCentroDestino = val),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: () async {
                  if (!_validarCentrosSeleccionados()) return;

                  final confirmado = await mostrarConfirmacionEnvio(context);
                  if (confirmado) {
                    await verificarSaldoYEnviarSolicitud();
                  }
                },
                child: const Text('Solicitar Traslado de proceso', style: TextStyle(fontSize: 18, color: blanco)),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> mostrarConfirmacionEnvio(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: blanco,
          title: const Text('Confirmar envío'),
          content: const Text('¿Estás seguro de solicitar el traslado de proceso? Esta acción será enviada para su revisión y trámite.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar', style: TextStyle(color: blanco)),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> verificarSaldoYEnviarSolicitud() async {
    final configSnapshot = await FirebaseFirestore.instance.collection('configuraciones').limit(1).get();
    final double valorTrasladoProceso = (configSnapshot.docs.first.data()['valor_traslado_proceso'] ?? 0).toDouble();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: blanco,
        title: const Text("Pago requerido"),
        content: const Text("Para enviar esta solicitud debes realizar el pago del servicio."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CheckoutPage(
                    tipoPago: 'traslado',
                    valor: valorTrasladoProceso.toInt(),
                    onTransaccionAprobada: () async {
                      await enviarSolicitudTrasladoProceso(valorTrasladoProceso);
                    },
                  ),
                ),
              );
            },
            child: const Text("Pagar"),
          ),
        ],
      ),
    );
  }

  Future<void> enviarSolicitudTrasladoProceso(double valorTrasladoProceso) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: blancoCards,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Enviando solicitud..."),
          ],
        ),
      ),
    );

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String docId = firestore.collection('traslado_proceso_solicitados').doc().id;
      String numeroSeguimiento = (Random().nextInt(900000000) + 100000000).toString();

      await firestore.collection('traslado_proceso_solicitados').doc(docId).set({
        'id': docId,
        'idUser': user.uid,
        'numero_seguimiento': numeroSeguimiento,
        'fecha': FieldValue.serverTimestamp(),
        'status': 'Solicitado',
        'asignadoA': "",
        // 👇 Nuevos campos
        'centro_origen_nombre': centroOrigenNombre,
        'centro_origen_regional': centroOrigenRegional,
        'centro_destino_nombre': centroDestinoNombre,
        'centro_destino_regional': centroDestinoRegional,
        'ciudad_centro_origen': ciudadCentroOrigen ?? '',
        'ciudad_centro_destino': ciudadCentroDestino ?? '',
      });


      await descontarSaldo(valorTrasladoProceso);

      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SolicitudExitosaTrasladoProcesoPage(numeroSeguimiento: numeroSeguimiento),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Hubo un problema al guardar la solicitud."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Aceptar")),
            ],
          ),
        );
      }
    }
  }

  bool _validarCentrosSeleccionados() {
    setState(() {
      _errorCentroOrigen = centroOrigenNombre == null || centroOrigenNombre!.isEmpty;
      _errorCentroDestino = centroDestinoNombre == null || centroDestinoNombre!.isEmpty;
    });

    // Validación del centro de origen
    if (_errorCentroOrigen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar el centro de reclusión de ORIGEN.")),
      );
      return false;
    }

    // Validación del centro de destino
    if (_errorCentroDestino) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar el centro de reclusión de DESTINO.")),
      );
      return false;
    }

    // Validación de que origen y destino no sean iguales
    if (centroOrigenNombre == centroDestinoNombre) {
      setState(() => _errorCentroDestino = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El centro de origen y el de destino no pueden ser el mismo.")),
      );
      return false;
    }

    // Validación de ciudad de origen
    if (ciudadCentroOrigen == null || ciudadCentroOrigen!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar la ciudad del centro de origen.")),
      );
      return false;
    }

    // Validación de ciudad de destino
    if (ciudadCentroDestino == null || ciudadCentroDestino!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar la ciudad del centro de destino.")),
      );
      return false;
    }

    return true;
  }


  Widget _buildDropdownCiudad({
    required String label,
    required String? valorSeleccionado,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.amber.shade50,
        value: valorSeleccionado,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(color: Colors.black),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 2),
          ),
        ),
        items: ciudadesConCarceles.map((ciudad) {
          return DropdownMenuItem(
            value: ciudad,
            child: Text(ciudad),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> descontarSaldo(double valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('Ppl').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final datos = snapshot.data();
      final double saldoActual = (datos?['saldo'] ?? 0).toDouble();
      final double nuevoSaldo = saldoActual - valor;

      if (nuevoSaldo >= 0) {
        await docRef.update({'saldo': nuevoSaldo});
      } else {
        debugPrint('⚠️ Saldo insuficiente, no se pudo descontar');
      }
    }
  }
}
