class DerechoPeticionTemplate {
  final String entidad;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String textoPrincipal;
  final String razonesPeticion;
  final String emailUsuario;
  final String emailAlternativo;
  final String nui;
  final String td;

  DerechoPeticionTemplate({
    required this.entidad,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.textoPrincipal,
    required this.razonesPeticion,
    required this.emailUsuario,
    this.emailAlternativo = "peticiones@tuprocesoya.com.co",
    required this.nui,
    required this.td,
  });

  String generarTextoHtml() {
    return """
    <html>
      <body>
        <b>Señores</b><br>
        <b>$entidad</b><br><br>
        Referencia: <b>Derecho fundamental de petición</b>.<br><br>
        Me dirijo a ustedes en representación de <b>$nombrePpl $apellidoPpl</b>, con número de identificación <b>$identificacionPpl</b>, NUI : <b>$nui</b>, TD : <b>$td</b>, actualmente recluido en <b>$centroPenitenciario</b>, actuando en ejercicio del derecho de petición consagrado en el artículo 23 de la Constitución Política y la Ley 1755 de 2015, de manera respetuosa elevo a ustedes lo siguiente:<br><br>
        <b>I. Peticiones</b><br>
        $textoPrincipal<br><br>
        <b>II. Razones de las peticiones:</b><br>
        $razonesPeticion<br><br><br><br>
        Por favor enviar las notificaciones a las siguientes direcciones electrónicas:<br>
        $emailAlternativo<br>
        $emailUsuario<br><br><br>
        Atentamente,<br><br>
        <img src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635" width="150" height="50"><br>
        www.tuprocesoya.com.co<br><br>
      </body>
    </html>
    """;
  }
}