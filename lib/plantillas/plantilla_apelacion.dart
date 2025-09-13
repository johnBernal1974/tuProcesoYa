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
      <p style="margin-top: 5px;">       

        La presente solicitud ha sido generada mediante la plataforma tecnológica <b>Tu Proceso Ya</b>, diseñada para facilitar el ejercicio autónomo del derecho fundamental de petición por parte de las personas privadas de la libertad o sus familiares.<br><br>

        En virtud del artículo 23 de la Constitución Política de Colombia y de las sentencias T-377 de 2014 y T-114 de 2017 de la Corte Constitucional, <b>no se requiere la firma de abogado ni apoderado para presentar una petición</b>. La plataforma actúa como medio de apoyo y canal de gestión digital, plenamente legítimo y válido. Exigir firma del apoderado o desconocer al solicitante por el solo hecho de que la petición fue tramitada por medio electrónico, constituye una barrera de acceso a la justicia e infringe el principio de eficacia del derecho fundamental de petición.
      </p>
    </div>
      </body>
    </html>
    """);

    return buffer.toString();
  }
}
