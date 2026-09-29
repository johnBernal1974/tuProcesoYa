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

      <div style="margin-top: 40px; color: #444; font-size: 12px;">
      
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
      </div>
    </body>
  </html>
  """);

    return buffer.toString();
  }
}
