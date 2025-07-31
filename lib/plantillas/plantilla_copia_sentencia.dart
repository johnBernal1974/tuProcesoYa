class SolicitudCopiaSentenciaTemplate {
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
  final String juzgado;
  final String numeroSeguimiento;

  SolicitudCopiaSentenciaTemplate({
    required this.dirigido,
    required this.entidad,
    this.referencia = "Derecho de petición – Solicitud de copia de sentencia",
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.juzgado,
    required this.numeroSeguimiento,
  });

  String convertirParrafos(String texto) {
    return texto
        .split('\n\n')
        .map((p) => '<p>${p.replaceAll('\n', '<br>')}</p>')
        .join();
  }

  String generarTextoHtml() {
    final buffer = StringBuffer();

    buffer.writeln("""
  <html>
    <body style="font-family: Arial, sans-serif;">
      <b>$dirigido</b><br>
      <b>$entidad</b><br><br>

      Referencia: <b>$referencia</b><br>      
      Radicado del proceso: <b>$radicado</b><br>  
      Asunto: <b>Solicitud de copia de sentencia – $numeroSeguimiento</b><br><br>

      Me amparo en los artículos 23 y 74 de la Constitución Política de Colombia, en el artículo 5 de la Ley 57 de 1985, y en el artículo 14 de la Ley 1437 de 2011.<br><br>

      E.S.D.<br><br>

      Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, respetuosamente solicito se me expida <b>copia auténtica de la sentencia condenatoria</b> proferida dentro del proceso radicado No. <b>$radicado</b> que cursa ante el <b>$juzgado</b>.

      <br><br><span style="font-size: 16px;"><b>I. FUNDAMENTOS</b></span><br><br>     

      1. La copia solicitada es necesaria para la adecuada defensa de mis derechos, la verificación de términos y la eventual interposición de recursos o solicitudes que en derecho correspondan.<br><br>

      2. El derecho de acceso a la información y documentos públicos me faculta para obtener la copia solicitada sin necesidad de demostrar interés particular distinto al ejercicio de mis derechos fundamentales.<br><br>

      <span style="font-size: 16px;"><b>II. PETICIÓN</b></span><br><br> 

      Solicito respetuosamente que se me expida <b>copia auténtica de la sentencia condenatoria</b> correspondiente al proceso radicado No. <b>$radicado</b>, proferida por el <b>$juzgado</b>, y que se remita a las direcciones electrónicas indicadas para efectos de notificación.

      <br><br><br>

      Para efectos de notificación, indico las siguientes direcciones electrónicas:<br>
      $emailAlternativo<br>
      $emailUsuario<br><br><br>

      Atentamente,<br><br><br>
      <b>$nombrePpl $apellidoPpl</b><br>
      CC: $identificacionPpl<br><br>

      <div style="margin-top: 80px;">
        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br><br>

        <b>NOTA IMPORTANTE:</b><br>
        <p style="font-size: 13px;">
          Esta solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>

          En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido.<br><br>

          Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.
        </p>
      </div>
    </body>
  </html>
  """);

    return buffer.toString();
  }
}
