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

    Asunto: <b>Redención de penas - Redosificación – $numeroSeguimiento</b><br>
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

     <p style="font-size:16.5px; font-weight:bold; margin-bottom:12px;">
Aclaración sobre la legitimidad del envío de la solicitud por familiar o acudiente del PPL
</p>

<p style="font-size:12px;">
En la presente fecha, <b>el familiar o acudiente debidamente autorizado de la persona privada de la libertad</b> formula igualmente solicitud ante la <strong>$centroPenitenciario</strong>, con el propósito de <b>obtener los documentos necesarios para el inicio oportuno de los trámites administrativos y judiciales correspondientes</b>, actuando <b>en nombre y representación del interno</b>, conforme a la ley.<br><br>

La presente solicitud <b>ha sido elaborada y remitida exclusivamente por el familiar o acudiente</b>, a través de la plataforma tecnológica <b>Tu Proceso Ya</b>, <b>sin que ello implique ni permita inferir que la persona privada de la libertad tenga acceso, posesión o uso de equipos tecnológicos</b>.  
La plataforma constituye <b>un medio externo, auxiliar y legítimo</b>, utilizado por terceros autorizados, para <b>canalizar solicitudes formuladas en favor del interno</b>, precisamente <b>en razón de las restricciones propias de la privación de la libertad</b>.<br><br>

Resulta jurídicamente improcedente, y contrario al orden constitucional, <b>presumir que el uso de medios electrónicos por parte de un familiar o acudiente implique el uso de dispositivos por el interno</b>, pues ello <b>desconoce el principio de buena fe (art. 83 C.P.)</b>, así como la realidad material de las limitaciones tecnológicas propias del régimen penitenciario.<br><br>

De conformidad con el <b>artículo 23 de la Constitución Política</b>, y según lo reiterado por la <b>Corte Constitucional en las sentencias T-377 de 2014 y T-114 de 2017</b>, <b>no se exige la firma de abogado ni de apoderado judicial para la presentación de derechos de petición</b>, ni puede condicionarse su validez a formalidades no previstas en la ley.  
En consecuencia, <b>la actuación del familiar o acudiente como solicitante es plenamente válida</b>, y <b>el uso de medios electrónicos no desvirtúa ni limita la eficacia jurídica de la petición</b>.<br><br>

Así mismo, <b>exigir firma de apoderado, desconocer la legitimación del familiar o acudiente, o adoptar represalias directas o indirectas contra el interno</b>, bajo el argumento de que la solicitud fue tramitada por medios tecnológicos, <b>configura una barrera ilegítima de acceso a la justicia</b>, vulnera el <b>principio de eficacia del derecho fundamental de petición</b>, y desconoce la <b>obligación reforzada del Estado de garantizar mecanismos reales y efectivos de acceso a la administración pública y judicial a favor de las personas privadas de la libertad</b>, aun cuando dicho acceso se realice <b>de manera indirecta a través de terceros</b>.
</p>

  </body>
</html>
""");

    return buffer.toString();
  }
}
