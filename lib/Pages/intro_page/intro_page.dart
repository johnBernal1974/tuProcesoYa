import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';

import '../../src/colors/colors.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  double? valorSubscripcion;
  bool cargando = true;

  final NumberFormat formatoPesos = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0',
  );

  @override
  void initState() {
    super.initState();
    _cargarValorSubscripcion();
  }

  Future<void> _cargarValorSubscripcion() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('configuraciones')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        setState(() {
          valorSubscripcion = (data['valor_subscripcion'] as num?)?.toDouble();
          cargando = false;
        });
      } else {
        setState(() {
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error al obtener valor_subscripcion: $e');
      setState(() {
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Bienvenido',
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 800, // ancho máximo para PC
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(0.0),
            child: _buildMobileLayout(context),
          ),
        ),
      ),
    );
  }



  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLogo(),
        const SizedBox(height: 24),
        _buildTextsAndButton(context),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo_tu_proceso_ya_transparente.png',
          width: 150,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildTextsAndButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Sientes que estás solo intentando ayudar a tu ser querido que está privado de la libertad?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.deepPurple,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '¿Quieres ayudarlo, pero no sabes por dónde empezar?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.deepPurple,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Te ofrecemos una herramienta que te acerca a la justicia, te guia paso a paso en cada trámite y te mantiene informado de los avances para tu mayor tranquilidad.\n\n¡Ya no estas solo, ahora tienes un equipo!',
          style: TextStyle(fontSize: 14, height: 1.2),
        ),
        const SizedBox(height: 24),
        _buildBenefitCard(
          context,
          icon: Icons.safety_check,
          text: 'Más de 200 usuarios atendidos con éxito.',
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          context,
          icon: Icons.timer_outlined,
          text: 'Tiempos de respuesta 30% más rápidos.',
        ),

        const SizedBox(height: 24),
        const Text(
          'No dejes que los tiempos del proceso se alarguen.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.deepPurple,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Regístrate y empieza a disfrutar los beneficios de tu suscripción:',
              style: TextStyle(
                fontSize: 16, height: 1.2, fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 16),
            _buildBulletItem(
              context,
              '1. Orientación y acompañamiento personalizado en todo tipo de solicitudes, como beneficios penitenciarios, tutelas, derechos de petición, traslados de proceso y redención de penas, entre otras.',
            ),
            _buildBulletItem(
              context,
              '2. Atención directa por WhatsApp, para resolver tus dudas y guiarte paso a paso.',
            ),
            _buildBulletItem(
              context,
              '3. Seguimiento en tiempo real de la situación jurídica de tu familiar, incluyendo días efectivos de condena, días redimidos, tiempo de condena faltante y tiempo que resta para acceder a beneficios penitenciarios.',
            ),
            _buildBulletItem(
              context,
              '4. Monitoreo actualizado del estado de las solicitudes enviadas a la autoridad competente.',
            ),
            _buildBulletItem(
              context,
              '5. Acompañamiento continuo en cada etapa del proceso.',
            ),
            _buildBulletItem(
              context,
              '6. Orientación para el uso de la plataforma y apoyo en el envío de solicitudes.',
            ),
            _buildBulletItem(
              context,
              '7. Agilidad en cada trámite, evitando burocracias y demoras por procesos internos innecesarios.',
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Obtienes precios preferenciales en cada una de las solicitudes mientras la suscripción esté activa.',
                        style: TextStyle(
                          fontWeight: FontWeight.w900, height: 1.2
                        )
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _mostrarTablaPrecios(context),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.double_arrow,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Ver precios',
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),

          ],
        ),
        const SizedBox(height: 24),
        if (cargando) ...[
          const Text(
            '',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ] else if (valorSubscripcion != null) ...[
          Text(
            'El valor de la suscripción es tan solo de ${formatoPesos.format(valorSubscripcion)} y te servirá para 6 meses continuos de servicio, donde nuestro equipo de trabajo estará dispuesto y complacido en atenderte.',
            style: const TextStyle(
              fontSize: 14, height: 1.2, color: Colors.black
            )
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          '¡Toma acción ahora mismo!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.deepPurple,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text("Cada día cuenta — evita retrasos que pueden costarle meses extra a tu ser querido en prisión.", style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, height: 1.2
        ),),
        const SizedBox(height: 30),
        SizedBox(
          width: 220,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, 'info'); // Cambia a tu pantalla
            },
            child: const Text(
              'Empezar ahora',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildBenefitCard(BuildContext context, {required IconData icon, required String text}) {
    return Card(
      color: Colors.green[600], // Color verde
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Ícono tipo insignia
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: Icon(
                icon,
                color: Colors.green[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Texto blanco
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14, color: blanco
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBulletItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14, height: 1.2
              )
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _mostrarTablaPrecios(BuildContext context) async {
    // Traer la configuración
    final configSnapshot = await FirebaseFirestore.instance
        .collection('configuraciones')
        .limit(1)
        .get();

    if (configSnapshot.docs.isEmpty) return;

    final data = configSnapshot.docs.first.data();

    final NumberFormat formatoPesos = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$ ',
      decimalDigits: 0,
      customPattern: '\u00A4 #,##0',
    );

    // Servicios que quieres mostrar en la tabla
    final servicios = [
      {'nombre': 'Permiso de 72h', 'valor': data['valor_72h']},
      {'nombre': 'Acumulación de penas', 'valor': data['valor_acumulacion']},
      {'nombre': 'Libertad condicional', 'valor': data['valor_condicional']},
      {'nombre': 'Derecho de petición', 'valor': data['valor_derecho_peticion']},
      {'nombre': 'Prisión domiciliaria', 'valor': data['valor_domiciliaria']},
      {'nombre': 'Extinción de la pena', 'valor': data['valor_extincion']},
      {'nombre': 'Redención de penas', 'valor': data['valor_redenciones']},
      {'nombre': 'Suscripción (6 meses)', 'valor': data['valor_subscripcion']},
      {'nombre': 'Traslado de proceso', 'valor': data['valor_traslado_proceso']},
      {'nombre': 'Tutela', 'valor': data['valor_tutela']},
    ];

    if(context.mounted){
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.deepPurple,
                  width: double.infinity,
                  child: const Text(
                    'Precios de solicitudes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8.0),
                    child: Table(
                      border: TableBorder.all(color: Colors.grey),
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      children: [
                        // Header
                        const TableRow(
                          decoration: BoxDecoration(
                            color: Colors.deepPurpleAccent,
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Servicio',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Precio',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Generar filas automáticamente
                        ...servicios.map((serv) {
                          return TableRow(
                            decoration: const BoxDecoration(color: blanco),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(serv['nombre'].toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  formatoPesos.format(
                                    (serv['valor'] as num?)?.toDouble() ?? 0.0,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar', style: TextStyle(color: blanco)),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildBenefitItem(BuildContext context,
      {required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
