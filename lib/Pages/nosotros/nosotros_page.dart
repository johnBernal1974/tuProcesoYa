import 'package:flutter/material.dart';

import '../../commons/main_layaout.dart';

class NosotrosPage extends StatefulWidget {
  const NosotrosPage({super.key});

  @override
  State<NosotrosPage> createState() => _NosotrosPageState();
}

class _NosotrosPageState extends State<NosotrosPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return MainLayout(
      pageTitle: 'Nosotros',
      content: SingleChildScrollView(
        child: Container(
          padding: screenWidth > 800 // Si es pantalla grande (desktop)
              ? const EdgeInsets.symmetric(horizontal: 100) // Margen de 100px
              : const EdgeInsets.symmetric(horizontal: 10), // Si es pantalla pequeña (móvil)
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                Image.asset('assets/images/logo_tu_proceso_ya_transparente.png', height: 80), // Logo
                const SizedBox(height: 20),
                const Text(
                  'Bienvenido a Tu Proceso Ya, una plataforma comprometida con la justicia social y la defensa de los derechos humanos. Nuestra misión es facilitar el acceso a servicios legales esenciales para personas privadas de la libertad, que a menudo enfrentan barreras económicas y burocráticas para ejercer sus derechos.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify, // Justificar el texto
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sabemos que la justicia no siempre es accesible para todos, especialmente para aquellos que se encuentran en situación de vulnerabilidad. Por eso, hemos creado esta plataforma para que tú, como familiar, amigo o ser querido de una persona privada de la libertad, puedas solicitar derechos de petición y penitenciarios de manera fácil y segura.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify, // Justificar el texto
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nuestra plataforma es diseñada para ser intuitiva y accesible, sin requerir conocimientos legales previos. Nuestro objetivo es empoderarte para que puedas defender los derechos de tus seres queridos y contribuir a la justicia social en nuestro país.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify, // Justificar el texto
                ),
                const SizedBox(height: 10),
                const Text(
                  'Te has unido a una comunidad que busca hacer una diferencia en la vida de aquellos que más lo necesitan.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify, // Justificar el texto
                ),
                const SizedBox(height: 20),
                const Text(
                  'Objetivo:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'El objetivo principal de Tu Proceso Ya es facilitar el acceso a la justicia y la igualdad de oportunidades para '
                      'las Personas Privadas de Libertad (PPL) CONDENADAS y sus familiares, mediante la realización de diligencias y '
                      'la provisión de resultados actualizados sobre su situación penitenciaria y judicial.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Misión:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Nuestra misión es ser un aliado confiable y eficaz para los PPL '
                      'condenados y sus familiares, brindando apoyo y asistencia en '
                      'cada paso del proceso. Buscamos ser efectivos en lo relacionado con:',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 10),
                const Text(
                  '1).Realizar diligencias ante las autoridades penitenciarias y judiciales para obtener información actualizada '
                      'sobre la situación de los PPL condenados.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 8),
                const Text(
                   '2).Proporcionar resultados precisos y oportunos a los PPL condenados y sus familiares.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 8),
                const Text(
                      '3).Facilitar el acceso a información relevante sobre el sistema penitenciario y judicial.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 8),
                const Text(
                      '4).Promover la igualdad de oportunidades y la justicia para los PPL condenados y sus familiares.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.justify,
                ),
            const SizedBox(height: 20),
            const Text(
              'Visión:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Nuestra visión es ser la plataforma líder en la provisión de servicios de diligencias y resultados para los PPL "
                "condenados y sus familiares, contribuyendo a la creación de un sistema de justicia más justo, equitativo y "
                "accesible para todos. Nos comprometemos a ser un modelo de innovación y excelencia en la provisión "
                "de servicios para los PPL condenados y sus familiares. Expandiremos nuestros servicios a "
                "nivel nacional e internacional, alcanzando a una mayor cantidad de personas y familias afectadas por la privación de "
                "libertad. Además, buscamos establecer alianzas estratégicas con organizaciones y entidades que compartan nuestros "
                "objetivos y valores, para fortalecer nuestra capacidad de impacto y mejorar la calidad de nuestros servicios.",
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.justify,
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
