class PrisionDomiciliariaTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String sinopsis;
  final String consideraciones;
  final String fundamentosDeDerecho;
  final String pretenciones;
  final String anexos;
  final String direccionDomicilio;
  final String municipio;
  final String departamento;
  final String nombreResponsable;
  final String parentesco;
  final String cedulaResponsable;
  final String celularResponsable;
  final String emailUsuario;
  final String emailAlternativo;
  final String nui;
  final String td;
  final String patio;
  final String radicado;
  final String delito;
  final String condena;
  final String purgado;
  final String jdc;
  final String numeroSeguimiento;
  final List<Map<String, String>>? hijos;
  final List<String>? documentosHijos;


  PrisionDomiciliariaTemplate({
    required this.entidad,
    required this.dirigido,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.sinopsis,
    required this.consideraciones,
    required this.fundamentosDeDerecho,
    required this.pretenciones,
    required this.anexos,
    required this.direccionDomicilio,
    required this.municipio,
    required this.departamento,
    required this.nombreResponsable,
    required this.parentesco,
    required this.cedulaResponsable,
    required this.celularResponsable,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.nui,
    required this.td,
    required this.patio,
    required this.radicado,
    required this.delito,
    required this.condena,
    required this.purgado,
    required this.jdc,
    required this.numeroSeguimiento,
    this.hijos,
    this.documentosHijos,
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
      <body>
        <b>$dirigido</b><br>
        <b>$entidad</b><br><br>

        Condenado: <b>$nombrePpl $apellidoPpl</b>.<br>
        Radicado del proceso: <b>$radicado</b>.<br>
        Delito: <b>$delito</b>.<br>
        Asunto:<br>
        <b>Solicitud Redencion de Penas</b><br>
        <b>Solicitud de prisión domiciliaria - $numeroSeguimiento</b>.<br><br>

        “Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.”<br><br>
        E.S.D<br><br>

        yo, <b>$nombrePpl $apellidoPpl</b>, identificado con el número de cédula <b>$identificacionPpl</b>, actualmente recluido en <b>$centroPenitenciario</b>, con el NUI : <b>$nui</b> y TD : <b>$td</b>, ubicado en el Patio No: <b>$patio</b>.<br><br>

        <span style="font-size: 16px;"><b>I. SINOPSIS PROCESAL</b></span><br>
        ${convertirParrafos(sinopsis)}<br><br>

        <span style="font-size: 16px;"><b>II. CONSIDERACIONES</b></span><br>
        ${convertirParrafos(consideraciones)}<br><br>

        <span style="font-size: 16px;"><b>III. FUNDAMENTOS DE DERECHO</b></span><br>
        ${convertirParrafos(fundamentosDeDerecho)}<br><br>

        <span style="font-size: 16px;"><b>IV. PRETENCIONES</b></span><br>
        ${convertirParrafos(pretenciones)}<br><br>

        <span style="font-size: 16px;"><b>V. ANEXOS</b></span><br>
        ${convertirParrafos(anexos)}<br><br>

        <b>Información del domicilio donde se cumpliría la medida:</b><br>
        <span style="font-size: 13px;">
        Dirección: <b>$direccionDomicilio</b>, <b>$municipio</b> - <b>$departamento</b><br>
        Nombre de la persona responsable: <b>$nombreResponsable</b><br>
        Número de identificación: <b>$cedulaResponsable</b><br>
        Número de celular: <b>$celularResponsable</b><br><br><br>
        </span>
    """);

    if (hijos != null && hijos!.isNotEmpty) {
      buffer.writeln("""
    <h4 style="margin-bottom: 0;">Hijos que convivirán conmigo durante el beneficio de prisión domiciliaria:</h4>
    <div style="font-size: 13px; margin-top: 2px;">
  """);

      for (var hijo in hijos!) {
        final nombre = hijo['nombre'] ?? '';
        final edad = hijo['edad'] ?? '';
        buffer.writeln('<div>- $nombre ($edad años)</div>');
      }

      buffer.writeln("""
    <p style="margin-top: 6px;">Se adjuntaron los documentos de identidad de mis hijos.</p>
    </div><br><br><br>
  """);
    }


    buffer.writeln("""    
        Agradezco enormemente la atención prestada a la presente.<br><br><br>
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
