class PrisionDomiciliariaTemplate {
  final String dirigido;
  final String entidad;
  final String referencia;
  final String nombrePpl;
  final String apellidoPpl;
  final String identificacionPpl;
  final String centroPenitenciario;
  final String consideraciones;
  final String fundamentosDeDerecho;
  final String peticionConcreta;
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

  PrisionDomiciliariaTemplate({
    required this.entidad,
    required this.dirigido,
    required this.referencia,
    required this.nombrePpl,
    required this.apellidoPpl,
    required this.identificacionPpl,
    required this.centroPenitenciario,
    required this.consideraciones,
    required this.fundamentosDeDerecho,
    required this.peticionConcreta,
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
  });

  String generarTextoHtml() {
    return """
    <html>
      <body>
        <b>$dirigido</b><br>
        <b>$entidad</b><br><br>
        Asunto: <b>Solicitud de prisión domiciliaria - $numeroSeguimiento</b>.<br>
        Ref: <b>$referencia</b>.<br><br>
        Radicado del proceso: <b>$radicado</b>.<br><br>
        Me dirijo a usted en representación de <b>$nombrePpl $apellidoPpl</b>, con número de identificación <b>$identificacionPpl</b>, actualmente recluido en <b>$centroPenitenciario</b>, NUI : <b>$nui</b>, TD : <b>$td</b>, Patio : <b>$patio</b>, para presentar formalmente solicitud de prisión domiciliaria, con base en lo siguiente:<br><br>

        <b>I. HECHOS</b><br><br>
        La condenada fue declarada por el <b>$jdc</b> a una pena de <b>$condena</b> <b>meses</b> por el delito de <b>$delito</b>. A la presente fecha ya ha purgado <b>$purgado</b> <b>meses</b>, incluyendo el tiempo físico y redimido, por lo cuál, ya ha cumplido con el 50% de la condena.<br><br>

        <b>II. FUNDAMENTOS DE DERECHO</b><br><br>
        1. El precepto 38G versa sobre el cumplimiento de la pena privativa de la libertad en el lugar de residencia o morada del condenado siempre que haya purgado la mitad (½) de la pena; satisfaga los numerales 3° y 4° del artículo 38B del Estatuto Punitivo, es decir que se demuestre su arraigo familiar y social y se garantice a través de caución el cumplimiento de las obligaciones legales; el penado no pertenezca al grupo familiar de la víctima y no haya sido sentenciado por uno de los delitos exceptuados por el propio artículo 38G.<br><br>
        2. Ha satisfecho los numerales 3° y 4° del artículo 38B del Estatuto Punitivo, es decir demuestra su arraigo familiar y social, como lo reafirma lo siguiente:<br><br>
        2.1. Estará cumpliendo con su condena bajo el beneficio de prisión domiciliaria en la $direccionDomicilio, $municipio - $departamento, al lado de $nombreResponsable quien es su $parentesco.<br><br>
        Lo anterior demuestra que tiene “la pertenencia a una familia, a un grupo, a una comunidad, a un trabajo o actividad, o la posesión de bienes…” en los términos que ha indicado la jurisprudencia de la Corte Suprema de justicia en sentencia de Casación Penal, Radicado 46930 de 2017, p. 25, citando a Sentencia de Casación Penal, Radicado 46647 de 2016, M.P. José Leónidas Bustos Martínez.<br><br>
        3. No pertenece al grupo familiar de la víctima.<br><br>
        4. No ha sido sentenciado por uno de los delitos exceptuados por el propio artículo 38G.<br><br>
        <b>III. PRETENCIONES</b><br><br>
        <b>Única:</b> Se le conceda el sustituto de prisión domiciliaria en la medida que ha cumplido con los requisitos previstos en la norma penal.<br><br>
        <b>IV. PRUEBAS</b><br><br>
        1. Ruego tener como tales el (los) expediente(s) del (los) proceso(s), para lo cual solicito su verificación, así como del trámite surtido.<br>
        2. Igualmente, ruego tener como tales los certificados expedidos por la oficina jurídica de los Centros Penitenciarios donde ha permanecido, para lo cual solicito se oficie al Centro de Reclusión para que allegue tales documentos.<br>
        3. Declaración extrajuicio de la persona que le acogerá en el sitio de domicilio.<br>
        4. Declaración extrajuicio donde consta su insolvencia económica<br>
        5. Registro civil de sus hijos<br><br>
        <b>V. COMPETENCIA</b><br><br>
        Es usted competente, Señor Juez, por encontrarse vigilando actualmente mí condena.<br><br><br><br>
       

       <b>Información del domicilio donde se cumpliría la medida:</b><br>
      <span style="font-size: 13px;">
      Dirección: <b>$direccionDomicilio</b>, <b>$municipio</b> - <b>$departamento</b><br>
      Nombre de la persona responsable: <b>$nombreResponsable</b><br>
      Número de identificación: <b>$cedulaResponsable</b><br>
      Número de celular: <b>$celularResponsable</b><br><br><br><br>
      </span>
      
      Por favor enviar las notificaciones a la siguiente dirección electrónica:<br>
        $emailAlternativo<br>
        $emailUsuario<br><br><br>
    

        Agradezco enormemente la atención prestada a la presente.<br><br>
        
        

        Atentamente,<br>
        <div style=\"margin-top: 80px;\">
          <img src=\"https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635\" width=\"150\" height=\"50\"><br>
        </div>
      </body>
    </html>
    """;
  }
}
