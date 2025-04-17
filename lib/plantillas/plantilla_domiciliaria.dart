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
  final String pruebas;
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
    required this.sinopsis,
    required this.consideraciones,
    required this.fundamentosDeDerecho,
    required this.pretenciones,
    required this.pruebas,
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
        
        Condenado: <b>$nombrePpl $apellidoPpl</b>.<br>
        Radicado del proceso: <b>$radicado</b>.<br>
        Delito: <b>$delito</b>.<br>
        Asunto: <b>Solicitud de prisión domiciliaria - $numeroSeguimiento</b>.<br><br>
        
        “Me amparo en el artículo 85 de la Constitución Política de Colombia y en el artículo 14 de la Ley 1437 de 2011.”<br><br>
        E.S.D<br><br>
              
        yo, <b>$nombrePpl $apellidoPpl</b>, identificado con el número de cédula <b>$identificacionPpl</b>, actualmente recluido en <b>$centroPenitenciario</b>, con el NUI : <b>$nui</b> y TD : <b>$td</b>, ubicado en el Patio No: <b>$patio</b>.<br><br>

        <span style="font-size: 18px;">
        <b>I. SINOPSIS PROCESAL</b><br>
        </span>
        
        $sinopsis<br><br>  
        
        <span style="font-size: 18px;">
        <b>II. CONSIDERACIONES</b><br>
        </span>
        
        $consideraciones<br><br>              

        <span style="font-size: 18px;">
        <b>III. FUNDAMENTOS DE DERECHO</b><br>
        </span>
        
        $fundamentosDeDerecho<br><br>        

        <span style="font-size: 18px;">
        <b>IV. PRETENCIONES</b><br>
        </span>
        
        $pretenciones<br><br>
        
        
        <span style="font-size: 18px;">
        <b>IV. ANEXOS</b><br>
        </span>
        
        $pruebas<br><br>       

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
    
    <b>NOTA IMPORTANTE</b><br>
    
    <p style="font-size: 13px;">
  El presente correo será copiado a la oficina jurídica de la <strong>$centroPenitenciario</strong>, para que queden informados de la presente diligencia y adelanten los trámites respectivos.
</p>

    """;
  }
}
