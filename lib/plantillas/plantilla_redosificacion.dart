class SolicitudRedosificacionRedencionTemplate {
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
  final String nui;
  final String td;
  final String patio;
  final String consideraciones;
  final String fundamentosDeDerecho;
  final String pretenciones;

  SolicitudRedosificacionRedencionTemplate({
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
    required this.nui,
    required this.td,
    required this.patio,
    required this.consideraciones,
    required this.fundamentosDeDerecho,
    required this.pretenciones,
  });

  // 👉 Helper para que los saltos de línea se vean bien en HTML
  String _nl2br(String texto) {
    return texto.replaceAll('\n', '<br>');
  }

  String generarTextoHtml() {
    final buffer = StringBuffer();

    final consHtml = _nl2br(consideraciones);
    final fundHtml = _nl2br(fundamentosDeDerecho);
    final pretHtml = _nl2br(pretenciones);

    buffer.writeln("""
<html>
  <body style="font-family: Arial, sans-serif;">
    <b>$dirigido</b><br>
    <b>$entidad</b><br><br>

    Asunto: <b>Solicitud de Redosificación de Redención – $numeroSeguimiento</b><br>
    Radicado del proceso: <b>$radicado</b><br><br>

    Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.<br><br>

    E.S.D.<br><br>

    Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula de ciudadanía No. <b>$identificacionPpl</b>, TD: <b>$td</b>, NUI: <b>$nui</b>, actualmente recluido en el establecimiento penitenciario <b>$centroPenitenciario</b>, Patio <b>$patio</b>, presento ante usted la siguiente solicitud:<br><br>

    <span style="font-size: 16px;"><b>I. CONSIDERACIONES</b></span><br><br>
    $consHtml<br><br>

    <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br><br>
    $fundHtml<br><br>

    <span style="font-size: 16px;"><b>III. PRETENSIONES</b></span><br><br>
    $pretHtml<br><br><br>

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

    <div style="margin-top: 40px; color: #444; font-size: 12px;">
      <b style="color: black;">NOTA IMPORTANTE</b><br>
      <p style="margin-top: 5px;">
        Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.<br><br>
        La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>
        En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido.  Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.<br><br>
      </p>
    </div>

  </body>
</html>
""");

    return buffer.toString();
  }
}
