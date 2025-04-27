class Permiso72HorasTemplate {
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
  final String situacion;
  final List<Map<String, String>>? hijos;
  final List<String>? documentosHijos;

  Permiso72HorasTemplate({
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
    required this.situacion,
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
        Asunto: <b>Solicitud de Permiso de 72 horas - $numeroSeguimiento</b>.<br><br>

        “Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.”<br><br>
        E.S.D<br><br>
    """);

    buffer.writeln("""
  yo, <b>$nombrePpl $apellidoPpl</b>, identificado con el número de cédula <b>$identificacionPpl</b>, actualmente recluido en el establecimiento <b>$centroPenitenciario</b>, con el NUI: <b>$nui</b> y TD: <b>$td</b>, ubicado en el Patio No: <b>$patio</b>.<br><br>
""");


    buffer.writeln("""
        <span style="font-size: 16px;"><b>I. SINOPSIS PROCESAL</b></span><br>
        ${convertirParrafos(sinopsis)}<br><br>

        <span style="font-size: 16px;"><b>II. CONSIDERACIONES</b></span><br>
        ${convertirParrafos(consideraciones)}<br><br>

        <span style="font-size: 16px;"><b>III. FUNDAMENTOS DE DERECHO</b></span><br>
        ${convertirParrafos(fundamentosDeDerecho)}<br><br>

        <span style="font-size: 16px;"><b>IV. PRETENSIONES</b></span><br>
        ${convertirParrafos(pretenciones)}<br><br>

        <span style="font-size: 16px;"><b>V. ANEXOS</b></span><br>
        ${convertirParrafos(anexos)}<br><br>

        <b>Información del domicilio donde se disfrutará del permiso:</b><br>
        <span style="font-size: 13px;">
        Dirección: <b>$direccionDomicilio</b>, <b>$municipio</b> - <b>$departamento</b><br>
        Nombre de la persona responsable: <b>$nombreResponsable</b><br>
        Número de identificación: <b>$cedulaResponsable</b><br>
        Número de celular: <b>$celularResponsable</b><br><br><br>
        </span>
    """);


    buffer.writeln("""    
        Agradezco enormemente la atención prestada a la presente.<br><br><br>
        Por favor enviar las notificaciones a la siguiente dirección electrónica:<br>
        $emailAlternativo<br>
        $emailUsuario<br><br><br>        

        Atentamente,<br><br><br>
        <b>$nombrePpl $apellidoPpl</b><br>
        CC. $identificacionPpl<br>
        <div style="margin-top: 50px;">
          <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br>
        </div>

        <b>NOTA IMPORTANTE</b><br>
        <p style="font-size: 13px;">
          Este mensaje también será enviado a la Oficina Jurídica del establecimiento <strong>$centroPenitenciario</strong>, con el fin de dejar constancia formal de esta solicitud y facilitar el inicio oportuno de los trámites correspondientes.
        </p>
      </body>
    </html>
    """);

    return buffer.toString();
  }
}
