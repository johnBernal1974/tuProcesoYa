class SolicitudCopiaSentenciaTemplate {
  final String dirigido;
  final String entidad;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String emailUsuario;
  final String emailAlternativo;
  final String radicado;
  final String nui;
  final String td;
  final String patio;
  final String juzgadoep;
  final String juzgadoConocimiento;
  final String numeroSeguimiento;

  SolicitudCopiaSentenciaTemplate({
    required this.dirigido,
    required this.entidad,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.emailUsuario,
    required this.nui,
    required this.td,
    required this.patio,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.radicado,
    required this.juzgadoep,
    required this.juzgadoConocimiento,
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

      Asunto: <b>Solicitud de copia de sentencia – $numeroSeguimiento</b><br>
      Radicado del proceso: <b>$radicado</b><br> 
      Condenado: <b>$nombrePpl $apellidoPpl</b><br><br><br>
     

      Me amparo en los artículos 23 y 74 de la Constitución Política de Colombia, en el artículo 5 de la Ley 57 de 1985, y en el artículo 14 de la Ley 1437 de 2011.<br><br>

      E.S.D.<br><br>

      Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, con el NUI : <b>$nui</b> y TD : <b>$td</b>, ubicado en el Patio No: <b>$patio</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, respetuosamente solicito se me expida <b>copia auténtica de la sentencia condenatoria</b> proferida dentro del proceso radicado No. <b>$radicado</b> que cursa ante el <b>$juzgadoep</b>.

      <br><br><span style="font-size: 16px;"><b>I. FUNDAMENTOS DE DERECHO</b></span><br><br>     

1. El derecho de acceso a la información y documentos públicos se encuentra consagrado en el artículo 74 de la Constitución Política, así como en el artículo 24 de la Ley 270 de 1996 (Estatutaria de la Administración de Justicia), que faculta a toda persona para consultar y obtener copias de expedientes judiciales, salvo las excepciones expresamente señaladas en la ley.<br><br>

2. La Corte Constitucional, en sentencias como la T-1037 de 2008, T-473 de 2017 y T-301 de 2020, ha precisado que el acceso a copias de providencias judiciales hace parte del núcleo esencial del derecho fundamental de acceso a la administración de justicia (artículo 229 C.P.) y del debido proceso (artículo 29 C.P.).<br><br>

3. La copia de la sentencia solicitada es necesaria para garantizar mi derecho a la defensa técnica y material, permitiendo la verificación de términos procesales y la eventual interposición de recursos, solicitudes de beneficios o acciones constitucionales que en derecho correspondan.<br><br>

4. Conforme al artículo 13 del Código General del Proceso (Ley 1564 de 2012), toda actuación judicial es pública y cualquier interesado puede obtener copias, sin que se requiera acreditar interés jurídico distinto al ejercicio legítimo de sus derechos.<br><br>

      <span style="font-size: 16px;"><b>II. PETICIÓN</b></span><br><br> 

Solicito respetuosamente que, en virtud de lo establecido en los artículos 23, 29, 74 y 229 de la Constitución Política, el artículo 24 de la Ley 270 de 1996 y las reglas jurisprudenciales de la Corte Constitucional sobre acceso a documentos judiciales, se me expida <b>copia auténtica de la sentencia condenatoria</b> correspondiente al proceso radicado No. <b>$radicado</b>, proferida por el <b>$juzgadoConocimiento</b>.<br><br>



      <br><br><br>

      Para efectos de notificación, indico las siguientes direcciones electrónicas:<br>
      $emailAlternativo<br>
      $emailUsuario<br><br><br>

      Atentamente,<br><br><br>
      <b>$nombrePpl $apellidoPpl</b><br>
      CC: $identificacionPpl<br>
      TD. $td<br>
      NUI. $nui<br>
      PATIO. $patio<br>

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
