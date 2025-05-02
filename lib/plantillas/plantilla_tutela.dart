class TutelaTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String hechos;
  final String derechosVulnerados;
  final String normasAplicables;
  final String pretensiones;
  final String pruebas;
  final String juramento;
  final String emailUsuario;
  final String emailAlternativo;
  final String nui;
  final String td;
  final String numeroSeguimiento;

  TutelaTemplate({
    required this.entidad,
    required this.dirigido,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.hechos,
    required this.derechosVulnerados,
    required this.normasAplicables,
    required this.pretensiones,
    required this.pruebas,
    required this.juramento,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com",
    required this.nui,
    required this.td,
    required this.numeroSeguimiento,
  });

  String generarTextoHtml() {
    return """
    <html>
      <body style='font-family: Arial, sans-serif; font-size: 14px; line-height: 1.6;'>        
        <p><b>$dirigido</b><br>
        <b>$entidad</b></p>

        <p>Asunto: <b>ACCIÓN DE TUTELA - $numeroSeguimiento</b><br>
        Referencia: Acción de tutela en contra la  <b>$centroPenitenciario</b>, por la violación a los derechos fundamentales de $referencia
        

        <p> Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con <b>$identificacionPpl</b>, NUI: <b>$nui</b>, TD: <b>$td</b>, actualmente privado de la libertad en el establecimiento <b>$centroPenitenciario</b>, en ejercicio del derecho consagrado en el artículo 86 de la Constitución Política de Colombia y desarrollado por el Decreto 2591 de 1991, interpongo la presente <b>acción de tutela</b> por la vulneración de mis derechos fundamentales. </p>

        <p><b>I. HECHOS</b><br>$hechos</p>

        <p><b>II. DERECHOS FUNDAMENTALES VULNERADOS</b><br>$derechosVulnerados</p>

        <p><b>III. NORMAS APLICABLES</b><br>$normasAplicables</p>

        <p><b>IV. PRETENSIONES</b><br>$pretensiones</p>

        <p><b>V. PRUEBAS</b><br>$pruebas</p>

        <p><b>VI. CUMPLIMIENTO AL ARTÍCULO 37 DEL DECRETO 2591 DE 1991 – JURAMENTO</b><br>$juramento</p>

        <p>Solicito que las notificaciones sean enviadas a las siguientes direcciones electrónicas:<br>
        $emailAlternativo<br>
        $emailUsuario</p>

        <p>Gracias por su atención y pronta respuesta.</p>

        <p>Atentamente,</p><br>

        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br>
        <a href='https://www.tuprocesoya.com'>www.tuprocesoya.com</a>

      </body>
    </html>
    """;
  }
}
