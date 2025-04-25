import 'package:flutter/material.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

import '../../widgets/preguntas_expandibles.dart';
import '../../widgets/redes_sociales.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final isDesktop = screenWidth >= 1000;
    final contentPadding = EdgeInsets.symmetric(horizontal: isDesktop ? 200 : isTablet ? 100 : 25);

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

            Padding(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  Center(
                    child: Image.asset(
                      "assets/images/logo_tu_proceso_ya_transparente.png",
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacementNamed(context, 'login'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Ingresar a la Aplicación',
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
                      onPressed: () => Navigator.pushReplacementNamed(context, 'login'),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          'Ingresar a la Aplicación',
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
