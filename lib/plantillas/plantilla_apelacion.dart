class ApelacionTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String fundamentosDeHecho;
  final String fundamentosDeDerecho;
  final String manifestacionPerdon;
  final String peticion;
  final String pruebas;
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
  final String fechaAuto;
  final String beneficioSolicitado;
  final String numeroSeguimiento;

  ApelacionTemplate({
    required this.dirigido,
    required this.entidad,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.fundamentosDeHecho,
    required this.fundamentosDeDerecho,
    required this.manifestacionPerdon,
    required this.peticion,
    required this.pruebas,
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
    required this.fechaAuto,
    required this.beneficioSolicitado,
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
      <body>
        <b>$dirigido</b><br>
        <b>$entidad</b><br><br>

        Condenado: <b>$nombrePpl $apellidoPpl</b>.<br>
        Radicado del proceso: <b>$radicado</b>.<br>
        Delito: <b>$delito</b>.<br>
        Asunto: <b>Presentación de recurso de apelación - $numeroSeguimiento</b><br><br>

        “Me amparo en el artículo 85 de la Constitución Política de Colombia y art 14 de ley 1437/2011.”<br><br>
        E.S.D<br><br>

        Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con número de cédula <b>$identificacionPpl</b>, actualmente recluido en <b>$centroPenitenciario</b>, NUI: <b>$nui</b>, TD: <b>$td</b>, Patio No: <b>$patio</b>.<br><br>
        De manera respetuosa, interpongo formalmente el <b>RECURSO DE APELACIÓN</b> contra el auto proferido el $fechaAuto, 
        mediante el cual se negó la solicitud de $beneficioSolicitado, por las razones de hecho y derecho que expongo:.<br><br>

        <span style="font-size: 16px;"><b>I. FUNDAMENTOS DE HECHO</b></span><br>
        ${convertirParrafos(fundamentosDeHecho)}<br><br>

        <span style="font-size: 16px;"><b>II. FUNDAMENTOS DE DERECHO</b></span><br>
        ${convertirParrafos(fundamentosDeDerecho)}<br><br>

        <span style="font-size: 16px;"><b>III. MANIFESTACIÓN PERSONAL DE PERDÓN Y COMPROMISO</b></span><br>
        ${convertirParrafos(manifestacionPerdon)}<br><br>

        <span style="font-size: 16px;"><b>IV. PETICIÓN</b></span><br>
        ${convertirParrafos(peticion)}<br><br>

        <span style="font-size: 16px;"><b>V. PRUEBAS</b></span><br>
        ${convertirParrafos(pruebas)}<br><br><br>
       

        Agradezco la atención prestada a esta solicitud.<br><br><br>
        Por favor compulsar copia de esta comunicación a los siguientes correos:<br>
        $emailAlternativo<br>
        $emailUsuario<br><br>

        Atentamente,<br><br>
        <b>$nombrePpl $apellidoPpl</b><br>
        CC. $identificacionPpl<br>
        TD. $td<br>
        NUI. $nui<br>
        PATIO. $patio<br>

        <div style="margin-top: 50px;">
          <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br>
        </div>

        <div style="margin-top: 40px; color: #444; font-size: 12px;">
      <b style="color: black;">NOTA IMPORTANTE</b><br><br>
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
    </div>
      </body>
    </html>
    """);

    return buffer.toString();
  }
}
