import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../widgets/html_video_player.dart';
import '../../widgets/info_tiempos_judiciales.dart';
import '../../widgets/preguntas_expandibles.dart';
import '../../widgets/red_ppl.dart';
import '../../widgets/redes_sociales.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final isDesktop = screenWidth >= 1000;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: isDesktop ? 60 : isTablet ? 40 : 20,
    );
    return Scaffold(
      backgroundColor: blancoCards,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: Colors.deepPurpleAccent,
              child: Center(
                child: Text(
                  'Caminando contigo hacia la libertad',
                  style: TextStyle(
                    fontSize: screenWidth > 600 ? 28 : 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: blanco,
              child: const Center(
                child: RedesSocialesWidget(),
              ),
            ),
            const SizedBox(height: 30),
            Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: const InfoTiemposJudiciales()),
            const SizedBox(height: 30),

            /// tarjeta que habla de la ley 2466 de 2025
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center( // 🔹 Centra el contenido
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 800, // 🔹 Máximo ancho para Desktop
                  ),
                  child: Card(
                    color: blanco,
                    surfaceTintColor: blanco,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Nuevo beneficio en vigor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const Text(
                            'Redención 2x3 según la Ley 2466 de 2025',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '¡Atención! Ya puedes invocar el beneficio del artículo 19: redime 2 días de condena por cada 3 días de trabajo certificado dentro del centro penitenciario. '
                                'Aún falta reglamentación del Ministerio de Trabajo, pero puedes anticipar tu solicitud con base en el principio de favorabilidad.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.info_outline, color: Colors.deepPurple),
                            label: const Text('Ver más', style: TextStyle(color: Colors.deepPurple)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: blanco,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  contentPadding: const EdgeInsets.all(16),
                                  content: const SizedBox(
                                    width: double.maxFinite,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Artículo 19 – Ley 2466 de 2025',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Desde el 25 de junio de 2025, está vigente un nuevo beneficio para personas condenadas. El artículo 19 permite redimir 2 días de la condena por cada 3 días de trabajo certificado dentro del centro penitenciario. '
                                                'Aunque falta el decreto reglamentario del Ministerio de Trabajo (que debe expedirse antes de diciembre de 2025), ya puedes presentar tu solicitud anticipada bajo el principio de favorabilidad.',
                                            style: TextStyle(fontSize: 12),
                                            textAlign: TextAlign.justify,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Este es el momento de actuar. Regístrate en nuestra plataforma y deja constancia de tu intención de acogerte a este beneficio.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.pushReplacementNamed(context, 'pagina_inicio_registro_page');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Ir a la aplicación'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;

                        // 🔹 Ajuste dinámico del tamaño de fuente y padding según el ancho
                        final fontSize = screenWidth > 1000
                            ? 20.0
                            : screenWidth > 600
                            ? 18.0
                            : 16.0;

                        final buttonPadding = EdgeInsets.symmetric(
                          horizontal: screenWidth > 1000
                              ? 24
                              : screenWidth > 600
                              ? 20
                              : 16,
                          vertical: screenWidth > 600 ? 12 : 10,
                        );

                        final buttonWidth = screenWidth > 1000
                            ? 250.0
                            : screenWidth > 600
                            ? 220.0
                            : 180.0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 🔹 Logo
                            Flexible(
                              flex: 1,
                              child: Image.asset(
                                "assets/images/logo_tu_proceso_ya_transparente.png",
                                height: screenWidth > 1000
                                    ? 80
                                    : screenWidth > 600
                                    ? 70
                                    : 50,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(width: screenWidth > 600 ? 40 : 16), // Espaciado adaptable

                            // 🔹 Botón responsivo
                            Flexible(
                              flex: 0,
                              child: SizedBox(
                                width: buttonWidth,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.pushReplacementNamed(
                                      context, 'pagina_inicio_registro_page'),
                                  icon: const Icon(Icons.arrow_forward, size: 20),
                                  label: Padding(
                                    padding: buttonPadding,
                                    child: Text(
                                      'Ir a la App',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.deepPurple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600; // PC/tablet → fila, móvil → columna

                        Widget buildVideo({
                          required String thumbnail,
                          required String url,
                          required String title,
                        }) {
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: blancoCards,
                                  contentPadding: const EdgeInsets.all(0),
                                  content: HtmlVideoPlayer(
                                    key: ValueKey(url), // fuerza reconstrucción con otra URL
                                    videoUrl: url,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Cerrar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    thumbnail,
                                    width: isWide ? 220 : 180,
                                    height: isWide ? 220 : 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 14 : 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return isWide
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildVideo(
                              thumbnail: 'assets/images/video_thumbnail2.jpeg',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/video_privado_libertad_familias.mp4?alt=media&token=6b110ff8-9f1b-46d6-a735-907708007b0b',
                              title: 'Su familia también paga una\ncondena silenciosa',
                            ),
                            const SizedBox(width: 24),
                            buildVideo(
                              thumbnail: 'assets/images/video_thumbnail.jpeg',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/video_introduccionTuProcesoYa.mp4?alt=media&token=319ca517-c558-4cee-8f8d-edd8c6264eea',
                              title: 'Conoce a ¡Tu Proceso Ya!\nen solo un minuto',
                            ),
                            const SizedBox(width: 24),
                            buildVideo(
                              thumbnail: 'assets/images/thumbnail_registro.png',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/como_registrarse.mp4?alt=media&token=bfb039dd-fb00-453c-8595-476bac8191b9',
                              title: 'Tutorial para\nhacer el registro',
                            ),
                            const SizedBox(width: 24),
                            buildVideo(
                              thumbnail: 'assets/images/thumnail_como_funciona.png',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/como_funciona_la_app.mp4?alt=media&token=2acccad4-5b5d-4b85-ba47-8c47ab6c3e5f',
                              title: 'Conoce como\nfunciona la app.',
                            ),
                          ],
                        )
                            : Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 16,      // espacio horizontal entre thumbnails
                          runSpacing: 20,   // espacio vertical entre filas
                          children: [
                            buildVideo(
                              thumbnail: 'assets/images/video_thumbnail2.jpeg',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/video_privado_libertad_familias.mp4?alt=media&token=6b110ff8-9f1b-46d6-a735-907708007b0b',
                              title: 'Su familia también paga una\ncondena silenciosa',
                            ),
                            buildVideo(
                              thumbnail: 'assets/images/video_thumbnail.jpeg',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/video_introduccionTuProcesoYa.mp4?alt=media&token=319ca517-c558-4cee-8f8d-edd8c6264eea',
                              title: 'Conoce a ¡Tu Proceso Ya!\nen solo un minuto',
                            ),
                            buildVideo(
                              thumbnail: 'assets/images/thumbnail_registro.png',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/como_registrarse.mp4?alt=media&token=bfb039dd-fb00-453c-8595-476bac8191b9',
                              title: 'Tutorial para\nhacer el registro',
                            ),
                            buildVideo(
                              thumbnail: 'assets/images/thumnail_como_funciona.png',
                              url:
                              'https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/como_funciona_la_app.mp4?alt=media&token=2acccad4-5b5d-4b85-ba47-8c47ab6c3e5f',
                              title: 'Conoce como\nfunciona la app.',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 20,
                    children: _buildCards(crossAxisCount: isDesktop ? 3 : isTablet ? 2 : 1),
                  ),

                  const SizedBox(height: 40),

                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nuestra Misión',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Humanizar el acceso a la justicia para las personas condenadas y sus familias, poniendo a su alcance una plataforma tecnológica accesible, segura y eficiente. A través de nuestra herramienta, facilitamos la gestión de trámites como derechos de petición y tutelas, promoviendo la participación activa de los seres queridos en los procesos legales, fortaleciendo el vínculo familiar, y brindando claridad, esperanza y autonomía en un momento de vulnerabilidad. Trabajamos para que cada acción jurídica sea un paso hacia la dignidad y el ejercicio real de los derechos.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Nuestra Visión',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aspiramos a consolidarnos como un referente nacional e internacional en la facilitación del acceso jurídico para personas condenadas y sus familias, mediante una plataforma tecnológica confiable, empática y transformadora. Buscamos impulsar un ecosistema digital que acerque a los usuarios a la justicia, promueva la participación de sus seres queridos en los procesos legales y contribuya a una sociedad más justa, informada y solidaria. Visualizamos un futuro donde la tecnología sea puente de dignidad, acompañamiento y oportunidades para quienes más lo necesitan.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: gris, height: 1),
                  const SizedBox(height: 50),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildValueCard(Icons.gavel, 'Acceso a la Justicia', 'Tecnología que elimina barreras y acerca soluciones legales.'),
                      _buildValueCard(Icons.favorite, 'Dignidad Humana', 'Cada trámite es una oportunidad para restaurar derechos y esperanza.'),
                      _buildValueCard(Icons.family_restroom, 'Conexión Familiar', 'Fortalecemos el lazo entre las personas condenadas y sus seres queridos.'),
                      _buildValueCard(Icons.lightbulb, 'Autonomía e Información', 'Facilitamos decisiones claras y simples que brindan tranquilidad a las familias.'),
                      _buildValueCard(Icons.public, 'Compromiso Social', 'Trabajamos por una justicia más humana, cercana y accesible.'),
                    ],
                  ),

                  const SizedBox(height: 80),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 750),
                      child: const PreguntasExpandiblesWidget(),
                    ),
                  ),
                  const SizedBox(height: 80),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, 'pagina_inicio_registro_page'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Ir a la App',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ... _buildValueCard, _buildCards, _buildSection, _buildCard (sin cambios)

  static Widget _buildValueCard(IconData icon, String title, String description) {
    return SizedBox(
      width: 230,
      child: Card(
        surfaceTintColor: blanco,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Colors.deepPurple),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }



  List<Widget> _buildCards({required int crossAxisCount}) {
    final List<Map<String, String>> data = [
      {
        'title': '¿Quiénes Somos?',
        'image': 'assets/images/equipo1.png',
        'description':
        'Somos una plataforma tecnológica orientada a facilitar el acceso a la justicia, promover la equidad y defender los derechos humanos. Brindamos herramientas digitales que permiten a las personas privadas de la libertad ejercer sus derechos de manera autónoma, fortaleciendo su bienestar y dignidad durante su estadía en prisión.'
      },
      {
        'title': '¿Qué Hacemos?',
        'image': 'assets/images/familia.png',
        'description':
        'Facilitamos a las personas privadas de la libertad y a sus seres queridos el acceso sencillo y seguro a servicios jurídicos como derechos de petición y tutelas. Contribuimos a que las familias mantengan el vínculo, participen activamente en la defensa de sus derechos y encuentren alivio en medio de la adversidad.'
      },
      {
        'title': '¿A Quién Va Dirigido?',
        'image': 'assets/images/equipo.png',
        'description':
        'Esta plataforma nace como un puente para quienes, desde afuera, no se resignan a quedarse de brazos cruzados. Está pensada para familiares y personas cercanas a personas condenadas, que buscan acompañar con amor, esperanza y compromiso. Les brinda una herramienta clara y accesible para apoyar el seguimiento de los procesos legales, y ser una voz activa en la defensa de los derechos de quienes más lo necesitan. '
      },
    ];

    return data.map((item) {
      return SizedBox(
        width: 400,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                item['title']!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  item['image']!,
                  height: 200,
                  width: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item['description']!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
