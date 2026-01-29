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
  final String nui;
  final String td;
  final String patio;

  // ✅ FLAG: controla redosificación (Ley 2466/2025)
  final bool incluirRedosificacion;

  final DateTime? periodoDesde;
  final DateTime? periodoHasta;



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
    required this.nui,
    required this.td,
    required this.patio,
    this.incluirRedosificacion = true, // ✅ por defecto EXACTAMENTE igual a la original
    this.periodoDesde,
    this.periodoHasta,
  });

  String _fmtFecha(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.day)}/${two(d.month)}/${d.year}";
  }

  String _buildPeriodoHtml() {
    final d = periodoDesde;
    final h = periodoHasta;

    if (d == null && h == null) return "";

    if (d != null && h != null) {
      return " en el periodo comprendido <b>del ${_fmtFecha(d)} al ${_fmtFecha(h)}</b>";
    }
    if (d != null) {
      return " en el periodo <b>desde ${_fmtFecha(d)}</b>";
    }
    return " en el periodo <b>hasta ${_fmtFecha(h!)}</b>";
  }

  String generarTextoHtml() {
    final buffer = StringBuffer();
    final String periodoHtml = _buildPeriodoHtml();

    // I. CONSIDERACIONES (condicional)
    final String bloqueConsideracionesRedosificacion = incluirRedosificacion
        ? """
Me permito acudir respetuosamente ante su despacho con el fin de solicitar el cómputo y abono de redención de pena a mi favor, conforme a lo dispuesto en la Ley 65 de 1993 y demás normas concordantes.

Así mismo, solicito que se aplique el criterio previsto en la Ley 2466 de 2025, no solo respecto de las actividades laborales, sino de manera extensiva y por analogía a las actividades de estudio y enseñanza, en atención a que dichas actividades cumplen una idéntica finalidad resocializadora, y su tratamiento diferenciado carecería de justificación objetiva y razonable.

En consecuencia, solicito que todas las actividades desarrolladas —laborales, educativas y de enseñanza— sean reconocidas bajo el mismo parámetro de redención, garantizando los principios de igualdad, resocialización y favorabilidad que orientan la ejecución de la pena.<br><br>
"""
        : """
Me permito acudir ante su despacho con el fin de solicitar el cómputo y abono de redención de pena a mi favor$periodoHtml, conforme a lo dispuesto por la <b>Ley 65 de 1993</b> y las demás disposiciones vigentes, con base en las actividades desarrolladas (laborales, educativas o de enseñanza) que proceda reconocer para efectos de redención.<br><br>
""";

    // II. FUNDAMENTOS DE DERECHO (condicional)
    final String bloqueFundamentosRedosificacion = incluirRedosificacion
        ? """
En virtud del <b>Artículo 19 de la Ley 2466 de 2025</b> —incluida en la reciente Reforma Laboral—, se amplió el alcance de este beneficio, estableciendo que por cada <b>tres (3) días de trabajo</b> se podrá redimir <b>dos (2) días de pena</b>. Esta disposición reconoce expresamente el valor resocializador de dichas actividades y fortalece su aplicación dentro del régimen penitenciario colombiano.<br><br>

Adicionalmente, esta norma reconoce dichas actividades como <b>experiencia laboral válida</b>, siempre que sean debidamente certificadas por el Instituto Nacional Penitenciario y Carcelario (INPEC) o la autoridad penitenciaria competente, contribuyendo así a la futura reintegración social y laboral del PPL.<br><br>

Así mismo, en aplicación del <b>principio de favorabilidad penal</b> consagrado en el artículo 29 de la Constitución Política de Colombia, solicito que dicha disposición legal más benigna sea aplicada en mi caso, dado que reduce proporcionalmente el tiempo de la pena mediante el reconocimiento del esfuerzo personal realizado en mi proceso de resocialización.<br><br>
"""
        : """
Solicito que se dé aplicación estricta a las disposiciones contenidas en la <b>Ley 65 de 1993</b> y demás normas vigentes que regulan la redención de pena, reconociendo las actividades laborales, educativas o de enseñanza debidamente certificadas por la autoridad penitenciaria competente, con el fin de realizar el respectivo cómputo y abono al tiempo de la pena impuesta.<br><br>
""";

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

    $bloqueConsideracionesRedosificacion

    Solicito respetuosamente que ese despacho oficie a la autoridad penitenciaria competente para que certifique formalmente las actividades adelantadas, el tiempo acumulado y los días redimidos que proceda reconocer, con el fin de que el juzgado pueda realizar el respectivo cómputo y abono al total de la pena privativa de la libertad impuesta.<br><br>

    <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br><br>

    Conforme a lo dispuesto en los artículos 82, 97, 98 y 101 de la Ley 65 de 1993, las personas privadas de la libertad tienen derecho a la redención de su pena mediante su participación en actividades laborales, educativas o de enseñanza. Este beneficio opera como un mecanismo de resocialización progresiva dentro del sistema penitenciario y está sujeto al cumplimiento de los requisitos legales y certificaciones institucionales.<br><br>

    $bloqueFundamentosRedosificacion

    <span style="font-size: 16px;"><b>III. PRETENSIONES</b></span><br><br>

    <b>PRIMERO:</b> Que se ordene a la autoridad del establecimiento penitenciario y carcelario emitir la documentación completa para el respectivo trámite.<br><br>
    <b>SEGUNDO:</b> Que se abonen los días que resulten procedentes al tiempo de la pena impuesta.<br><br><br><br>

    Por favor compulsar copias de notificaciones a la siguiente dirección electrónica:<br>
    $emailAlternativo<br>
    $emailUsuario<br><br><br>

    Atentamente,<br><br><br>
    <b>$nombrePpl $apellidoPpl</b><br>
    CC: $identificacionPpl<br>
    TD: $td<br>
    NUI: $nui<br><br><br>

    <div style="margin-top: 40px;">
      <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635"
           width="160" height="50"/>
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
 </p>
  </body>
</html>
""");

    return buffer.toString();
  }
}
