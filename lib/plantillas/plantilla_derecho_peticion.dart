import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DerechoPeticionTemplate {
  final String entidad;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String textoPrincipal;
  final String razonesPeticion;
  final String emailUsuario;
  final String emailAlternativo;
  final String nui;
  final String td;

  DerechoPeticionTemplate({
    required this.entidad,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.textoPrincipal,
    required this.razonesPeticion,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com.co",
    required this.nui,
    required this.td,
  });

  TextSpan generarTexto() {
    return TextSpan(
      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
      children: [
        const TextSpan(text: "Señores\n"),
        TextSpan(
          text: "$entidad\n\n",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(
          text: "Referencia: ",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const TextSpan(text: "Derecho fundamental de petición.\n\n", style: TextStyle(fontWeight: FontWeight.w900)),
        const TextSpan(text: "Me dirijo a ustedes en representación de "),
        TextSpan(
          text: "$nombrePpl $apellidoPpl",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ", con número de identificación "),
        TextSpan(
            text: identificacionPpl, style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        const TextSpan(text: ", NUI : "),
        TextSpan(
          text: nui,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ", TD : "),
        TextSpan(
          text: td,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(text: ", actualmente recluido en "),
        TextSpan(
          text: centroPenitenciario,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const TextSpan(
          text: ", actuando en ejercicio del derecho de petición consagrado en el artículo 23 de la Constitución Política "
              "y la Ley 1755 de 2015, de manera respetuosa elevo a ustedes lo siguiente:\n\n",
        ),
        const TextSpan(
            text: " I. Peticiones\n", style: TextStyle(fontWeight: FontWeight.w900)
        ),
        TextSpan(text: "$textoPrincipal\n\n"),
        const TextSpan(
          text: "II. Razones de las peticiones:\n",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        TextSpan(text: "$razonesPeticion\n\n\n\n"),
        const TextSpan(
          text: "Por favor enviar las notificaciones a las siguientes direcciones electrónicas:\n",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        TextSpan(text: "$emailAlternativo\n$emailUsuario\n\n\n"),
        const TextSpan(
          text: "Atentamente,\n\n",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        WidgetSpan(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0), // Espaciado superior
                child: Image.asset(
                  'assets/images/logo_tu_proceso_ya_transparente.png', // Ruta de la imagen en assets
                  width: 150, // Ajusta el tamaño según sea necesario
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 3), // Agrega espacio entre la imagen y el texto
            ],
          ),
        ),
        const TextSpan(
          text: "\nwww.tuprocesoya.com.co\n\n", // Salto de línea adicional
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }
}