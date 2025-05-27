import 'package:intl/intl.dart';

class SolicitudRedencionesTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado;
  final String jdc;
  final String numeroSeguimiento;
  final String situacion;
  final String fechaInicio;
  final String fechaFinal;
  final String nui;
  final String td;
  final String patio;

  SolicitudRedencionesTemplate({
    required this.dirigido,
    required this.entidad,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.jdc,
    required this.numeroSeguimiento,
    required this.situacion,
    required this.fechaInicio,
    required this.fechaFinal,
    required this.nui,
    required this.td,
    required this.patio,
  });

  String generarTextoHtml() {
    final fechaInicioFormateada =
    DateFormat("d 'de' MMMM 'de' y", 'es').format(DateTime.parse(fechaInicio));
    final fechaFinalFormateada =
    DateFormat("d 'de' MMMM 'de' y", 'es').format(DateTime.parse(fechaFinal));

    final buffer = StringBuffer();

    buffer.writeln("""
  <html>
    <body style="font-family: Arial, sans-serif;">
      <b>$dirigido</b><br>
      <b>$entidad</b><br><br>

      Asunto: <b>Solicitud de Cómputo de Redención – $numeroSeguimiento</b><br>
      Radicado del proceso: <b>$radicado</b><br><br>

      Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

      E.S.D.<br><br>

      Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, TD: <b>$td</b>, NUI: <b>$nui</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, Patio <b>$patio</b>, presento ante usted la siguiente solicitud:<br><br>

      <span style="font-size: 16px;"><b>I. CONSIDERACIONES</b></span><br><br>

De manera atenta, acudo ante su despacho con el fin de solicitar el cómputo y abono de redención de pena por las actividades desarrolladas durante el período comprendido entre el <b>$fechaInicioFormateada</b> y el <b>$fechaFinalFormateada</b>, en el marco del régimen penitenciario vigente. Esta solicitud tiene como propósito que, previa verificación por parte de la administración penitenciaria, se remita al juzgado el respectivo certificado que acredite los días redimidos, para su correspondiente valoración y aplicación al cómputo de la pena.<br><br>


      <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br><br>

      Conforme a lo dispuesto en los artículos 82, 97 y 98 de la Ley 65 de 1993, las personas privadas de la libertad tienen derecho a la redención de su pena mediante la participación en actividades laborales, educativas o de enseñanza, siempre que se cumplan las condiciones y proporciones establecidas normativamente.<br><br>

      <span style="font-size: 16px;"><b>III. PRETENSIÓN</b></span><br><br>

      <b>ÚNICA:</b> Que se ordene a la autoridad penitenciaria certificar el cómputo y redención de pena correspondiente al periodo indicado, y se abonen los días que resulten procedentes al tiempo de la pena privativa de la libertad impuesta.<br><br>

      <span style="font-size: 16px;"><b>IV. PRUEBAS</b></span><br><br>

      1. Copia del expediente del proceso penal de la referencia.<br>
      2. Certificación del INPEC sobre actividades desarrolladas y cómputo de redención entre las fechas mencionadas.<br><br><br>

      Por favor compulsar copias de notificaciones a la siguiente dirección electrónica:<br>
      $emailAlternativo<br>
      $emailUsuario<br><br><br>

      Atentamente,<br><br><br>
      <b>$nombrePpl $apellidoPpl</b><br>
      CC: $identificacionPpl<br>
      TD: $td<br>
      NUI: $nui<br><br><br>

      <div style="margin-top: 40px;">
        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="160" height="50"/>
      </div>

      <div style="margin-top: 40px;">
        <b>NOTA IMPORTANTE</b><br>
        <p style="font-size: 13px; margin-top: 5px;">
          Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.
        </p>
      </div>
    </body>
  </html>
  """);

    return buffer.toString();
  }
}
