
class SolicitudAsignacionTEETemplate {
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
  final bool solicitudPorAbogado;
  final String nombreAbogado;
  final String tarjetaProfesionalAbogado;
  final String cedulaAbogado;

  SolicitudAsignacionTEETemplate({
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
    this.solicitudPorAbogado = false,
    this.nombreAbogado = '',
    this.tarjetaProfesionalAbogado = '',
    this.cedulaAbogado = '',
  });


  String _generarTextoAbogado() {
    final nombreCompletoPpl = '$nombrePpl $apellidoPpl';

    final abogado = nombreAbogado.trim().isNotEmpty
        ? nombreAbogado.trim()
        : '[NOMBRE DEL ABOGADO]';

    final cedula = cedulaAbogado.trim().isNotEmpty
        ? cedulaAbogado.trim()
        : '[CÉDULA DEL ABOGADO]';

    final tarjeta = tarjetaProfesionalAbogado.trim().isNotEmpty
        ? tarjetaProfesionalAbogado.trim()
        : '[NÚMERO DE TARJETA PROFESIONAL]';

    return """
<html>
<body style="font-family: Arial, sans-serif;">

<b>$dirigido</b><br>
<b>$entidad</b><br><br>

Asunto: <b>Solicitud de asignación a actividades de Trabajo,
Estudio o Enseñanza (TEE) – $numeroSeguimiento</b><br>

Radicado del proceso: <b>$radicado</b><br><br>

Derecho fundamental de petición – Artículo 23 de la
Constitución Política de Colombia y Ley 1755 de 2015.
<br><br>

E.S.D.<br><br>

Yo, <b>$abogado</b>, identificado con cédula de
ciudadanía No. <b>$cedula</b>, abogado en ejercicio,
portador de la tarjeta profesional No. <b>$tarjeta</b>,
actuando en representación del señor
<b>$nombreCompletoPpl</b>, identificado con cédula
de ciudadanía No. <b>$identificacionPpl</b>,
TD: <b>$td</b>, NUI: <b>$nui</b>,
actualmente privado de la libertad en el establecimiento
penitenciario <b>$centroPenitenciario</b>,
Patio <b>$patio</b>, presento respetuosamente
solicitud para que se evalúe su vinculación a las
actividades de Trabajo, Estudio o Enseñanza (TEE).
<br><br>

<span style="font-size: 16px;">
<b>I. CONSIDERACIONES</b>
</span><br><br>

Mi representado se encuentra privado de la libertad
en el establecimiento penitenciario anteriormente
identificado, cumpliendo las disposiciones correspondientes
a su situación jurídica.
<br><br>

El trabajo, el estudio y la enseñanza constituyen
actividades fundamentales dentro del tratamiento
penitenciario, orientadas a la resocialización,
formación personal, adquisición de conocimientos,
desarrollo de habilidades y preparación para
la reincorporación a la sociedad.
<br><br>

Asimismo, cuando se cumplen los requisitos legales,
la participación y certificación de estas actividades
puede dar lugar al reconocimiento de tiempo de
redención de pena por parte de la autoridad judicial
competente.
<br><br>

En ese sentido, manifiesto el interés de mi representado
en participar en las actividades laborales, educativas
o de enseñanza que se encuentren disponibles dentro
del establecimiento penitenciario, atendiendo a su perfil,
aptitudes, condiciones personales, requisitos institucionales
y disponibilidad de cupos.
<br><br>

Se considera importante que su situación sea evaluada
por el área competente, a fin de determinar las
alternativas de vinculación existentes y los
procedimientos necesarios para acceder a ellas.
<br><br>

La presente solicitud no pretende desconocer los
procedimientos de selección, clasificación o asignación
establecidos por el INPEC, sino obtener una evaluación
formal y una respuesta clara sobre las posibilidades
de incorporación de mi representado a dichas actividades.
<br><br>

<span style="font-size: 16px;">
<b>II. FUNDAMENTOS DE DERECHO</b>
</span><br><br>

• <b>Artículo 23 de la Constitución Política de Colombia:</b>
reconoce el derecho fundamental de presentar peticiones
respetuosas ante las autoridades y obtener una respuesta
de fondo, clara y oportuna.
<br><br>

• <b>Artículo 25 de la Constitución Política:</b>
consagra la protección constitucional del trabajo.
<br><br>

• <b>Artículo 67 de la Constitución Política:</b>
reconoce la educación como un derecho y un servicio
público con función social.
<br><br>

• <b>Ley 65 de 1993, Código Penitenciario y Carcelario,
y sus modificaciones:</b> regula las actividades de
trabajo, estudio y enseñanza en los establecimientos
penitenciarios, así como su relación con el tratamiento
penitenciario y la redención de pena.
<br><br>

• <b>Ley 1709 de 2014:</b> introdujo modificaciones
al régimen penitenciario y carcelario colombiano,
fortaleciendo disposiciones relacionadas con el
tratamiento penitenciario y la resocialización.
<br><br>

• <b>Ley 1755 de 2015:</b> regula el ejercicio del
derecho fundamental de petición y el deber de las
autoridades de responder las solicitudes presentadas.
<br><br>

Estas disposiciones respaldan la posibilidad de
solicitar información, evaluación y acceso a los
programas institucionales disponibles, sin que ello
implique una asignación automática o el desconocimiento
de los requisitos legalmente establecidos.
<br><br>

<span style="font-size: 16px;">
<b>III. PRETENSIONES</b>
</span><br><br>

<b>PRIMERO:</b> Que se reciba y tramite formalmente
la solicitud de vinculación de mi representado a
actividades de <b>Trabajo, Estudio o Enseñanza (TEE)</b>
dentro del establecimiento penitenciario
<b>$centroPenitenciario</b>.
<br><br>

<b>SEGUNDO:</b> Que se remita la presente solicitud
al área de tratamiento y desarrollo, junta o
dependencia competente para evaluar su perfil,
situación penitenciaria y cumplimiento de los
requisitos establecidos para acceder a dichas
actividades.
<br><br>

<b>TERCERO:</b> Que se informe cuáles programas de
trabajo, estudio o enseñanza se encuentran disponibles,
los requisitos de vinculación y el procedimiento
que debe adelantar mi representado para participar
en ellos.
<br><br>

<b>CUARTO:</b> Que, de cumplir los requisitos y existir
disponibilidad de cupos, se considere su inclusión
en alguna de las actividades TEE, conforme a los
procedimientos y criterios de asignación aplicables.
<br><br>

<b>QUINTO:</b> Que, si actualmente no existen cupos
disponibles, se informe esta circunstancia y
se indique si existe lista de espera, procedimiento
de inscripción o mecanismo para participar en
futuras convocatorias.
<br><br>

<b>SEXTO:</b> Que se comunique por escrito la decisión
adoptada, indicando de manera clara las razones
de aceptación, aplazamiento o negativa de la
solicitud, según corresponda.
<br><br>

<b>SÉPTIMO:</b> Que, en caso de ser asignado mi
representado a una actividad TEE, se realicen los
registros y controles institucionales correspondientes
para la certificación de las actividades efectivamente
desarrolladas, de conformidad con las disposiciones
aplicables a la redención de pena.
<br><br>

<span style="font-size: 16px;">
<b>IV. NOTIFICACIONES</b>
</span><br><br>

Solicito que la respuesta sea comunicada al señor
<b>$nombreCompletoPpl</b> dentro del establecimiento
penitenciario y que, adicionalmente, se remita copia
a las siguientes direcciones electrónicas:
<br><br>

$emailAlternativo<br>
$emailUsuario<br><br>

Agradezco la atención prestada y solicito una
respuesta de fondo dentro de los términos legales.
<br><br><br>

Atentamente,<br><br><br>

<b>$abogado</b><br>
C.C. No. $cedula<br>
Abogado<br>
T. P. No. $tarjeta<br>
En representación de: $nombreCompletoPpl<br>
CC del PPL: $identificacionPpl<br>
TD: $td<br>
NUI: $nui<br>
Patio: $patio<br>
Establecimiento: $centroPenitenciario
<br><br><br>

<div style="margin-top: 40px;">
  <img
    src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635"
    width="160"
    height="50"
  />
</div>

<div style="margin-top: 40px; color: #444; font-size: 12px;">
  <b style="color: black;">NOTA IMPORTANTE</b><br><br>

  <p>
    La presente solicitud ha sido preparada mediante
    la plataforma tecnológica <b>Tu Proceso Ya</b>,
    como herramienta de apoyo para su elaboración
    y gestión digital.
    <br><br>

    La modalidad de presentación mediante abogado
    requiere verificar la identidad profesional del
    firmante y la representación que invoca.
    El uso de la plataforma no constituye por sí
    mismo acreditación de poder ni representación legal.
  </p>
</div>

</body>
</html>
""";
  }

  String generarTextoHtml() {
    if (solicitudPorAbogado) {
      return _generarTextoAbogado();
    }

    final buffer = StringBuffer();

    buffer.writeln("""
<html>
  <body style="font-family: Arial, sans-serif;">

    <b>$dirigido</b><br>
    <b>$entidad</b><br><br>

    Asunto: <b>Solicitud de asignación a actividades de Trabajo,
    Estudio o Enseñanza (TEE) – $numeroSeguimiento</b><br>
    Radicado del proceso: <b>$radicado</b><br><br>

    Derecho fundamental de petición – Artículo 23 de la
    Constitución Política de Colombia y Ley 1755 de 2015.
    <br><br>

    E.S.D.<br><br>

    Yo, <b>$nombrePpl $apellidoPpl</b>, identificado con cédula
    de ciudadanía No. <b>$identificacionPpl</b>,
    TD: <b>$td</b>, NUI: <b>$nui</b>,
    actualmente recluido en el establecimiento penitenciario
    <b>$centroPenitenciario</b>, Patio <b>$patio</b>,
    presento respetuosamente solicitud para que se evalúe
    mi vinculación a las actividades de Trabajo, Estudio
    o Enseñanza (TEE), de conformidad con la normativa
    penitenciaria vigente.
    <br><br>

    <span style="font-size: 16px;">
      <b>I. CONSIDERACIONES</b>
    </span><br><br>

    Actualmente me encuentro privado de la libertad en el
    establecimiento penitenciario anteriormente identificado,
    cumpliendo las disposiciones correspondientes a mi
    situación jurídica.
    <br><br>

    El trabajo, el estudio y la enseñanza constituyen
    actividades fundamentales dentro del tratamiento
    penitenciario, orientadas a la resocialización,
    formación personal, adquisición de conocimientos,
    desarrollo de habilidades y preparación para
    la reincorporación a la sociedad.
    <br><br>

    Asimismo, cuando se cumplen los requisitos legales,
    la participación y certificación de estas actividades
    puede dar lugar al reconocimiento de tiempo de
    redención de pena por parte de la autoridad judicial
    competente.
    <br><br>

    En ese sentido, manifiesto expresamente mi interés
    y disposición para participar en las actividades
    laborales, educativas o de enseñanza que se encuentren
    disponibles dentro del establecimiento penitenciario,
    atendiendo a mi perfil, aptitudes, condiciones personales,
    requisitos institucionales y disponibilidad de cupos.
    <br><br>

    Considero importante que mi situación sea evaluada
    por el área competente, a fin de determinar las
    alternativas de vinculación existentes y los
    procedimientos necesarios para acceder a ellas.
    <br><br>

    La presente solicitud no pretende desconocer los
    procedimientos de selección, clasificación o asignación
    establecidos por el INPEC, sino obtener una evaluación
    formal y una respuesta clara sobre las posibilidades
    de incorporación a dichas actividades.
    <br><br>

    <span style="font-size: 16px;">
      <b>II. FUNDAMENTOS DE DERECHO</b>
    </span><br><br>

    • <b>Artículo 23 de la Constitución Política de Colombia:</b>
    reconoce el derecho fundamental de presentar peticiones
    respetuosas ante las autoridades y obtener una respuesta
    de fondo, clara y oportuna.
    <br><br>

    • <b>Artículo 25 de la Constitución Política:</b>
    consagra la protección constitucional del trabajo.
    <br><br>

    • <b>Artículo 67 de la Constitución Política:</b>
    reconoce la educación como un derecho y un servicio
    público con función social.
    <br><br>

    • <b>Ley 65 de 1993, Código Penitenciario y Carcelario,
    y sus modificaciones:</b> regula las actividades de
    trabajo, estudio y enseñanza en los establecimientos
    penitenciarios, así como su relación con el tratamiento
    penitenciario y la redención de pena.
    <br><br>

    • <b>Ley 1709 de 2014:</b> introdujo modificaciones
    al régimen penitenciario y carcelario colombiano,
    fortaleciendo disposiciones relacionadas con el
    tratamiento penitenciario y la resocialización.
    <br><br>

    • <b>Ley 1755 de 2015:</b> regula el ejercicio del
    derecho fundamental de petición y el deber de las
    autoridades de responder las solicitudes presentadas.
    <br><br>

    Estas disposiciones respaldan la posibilidad de
    solicitar información, evaluación y acceso a los
    programas institucionales disponibles, sin que ello
    implique una asignación automática o el desconocimiento
    de los requisitos legalmente establecidos.
    <br><br>

    <span style="font-size: 16px;">
      <b>III. PRETENSIONES</b>
    </span><br><br>

    <b>PRIMERO:</b> Que se reciba y tramite formalmente
    mi solicitud de vinculación a actividades de
    <b>Trabajo, Estudio o Enseñanza (TEE)</b> dentro del
    establecimiento penitenciario
    <b>$centroPenitenciario</b>.
    <br><br>

    <b>SEGUNDO:</b> Que se remita la presente solicitud
    al área de tratamiento y desarrollo, junta o
    dependencia competente para evaluar mi perfil,
    situación penitenciaria y cumplimiento de los
    requisitos establecidos para acceder a dichas
    actividades.
    <br><br>

    <b>TERCERO:</b> Que se informe cuáles programas de
    trabajo, estudio o enseñanza se encuentran disponibles,
    los requisitos de vinculación y el procedimiento
    que debo adelantar para participar en ellos.
    <br><br>

    <b>CUARTO:</b> Que, de cumplir los requisitos y existir
    disponibilidad de cupos, se considere mi inclusión
    en alguna de las actividades TEE, conforme a los
    procedimientos y criterios de asignación aplicables.
    <br><br>

    <b>QUINTO:</b> Que, si actualmente no existen cupos
    disponibles, se me informe esta circunstancia y
    se indique si existe lista de espera, procedimiento
    de inscripción o mecanismo para participar en
    futuras convocatorias.
    <br><br>

    <b>SEXTO:</b> Que se me comunique por escrito la
    decisión adoptada, indicando de manera clara
    las razones de aceptación, aplazamiento o negativa
    de la solicitud, según corresponda.
    <br><br>

    <b>SÉPTIMO:</b> Que, en caso de ser asignado a una
    actividad TEE, se realicen los registros y controles
    institucionales correspondientes para la certificación
    de las actividades efectivamente desarrolladas,
    de conformidad con las disposiciones aplicables
    a la redención de pena.
    <br><br>

    <span style="font-size: 16px;">
      <b>IV. NOTIFICACIONES</b>
    </span><br><br>

    Solicito que la respuesta sea comunicada al suscrito
    dentro del establecimiento penitenciario y que,
    adicionalmente, se remita copia a las siguientes
    direcciones electrónicas:
    <br><br>

    $emailAlternativo<br>
    $emailUsuario<br><br>

    Agradezco la atención prestada y solicito una
    respuesta de fondo dentro de los términos legales.
    <br><br><br>

    Atentamente,<br><br><br>

    <b>$nombrePpl $apellidoPpl</b><br>
    CC: $identificacionPpl<br>
    TD: $td<br>
    NUI: $nui<br>
    Patio: $patio<br>
    Establecimiento: $centroPenitenciario
    <br><br><br>

    <div style="margin-top: 40px;">
      <img
        src="https://firebasestorage.googleapis.com/v0/b/tu-proceso-ya-fe845.firebasestorage.app/o/logo_tu_proceso_ya_transparente.png?alt=media&token=07f3c041-4ee3-4f3f-bdc5-00b65ac31635"
        width="160"
        height="50"
      />
    </div>

    <div style="margin-top: 40px; color: #444; font-size: 12px;">
      <b style="color: black;">NOTA IMPORTANTE</b><br><br>

      <p style="margin-top: 5px;">
        La presente solicitud ha sido generada mediante
        la plataforma tecnológica <b>Tu Proceso Ya</b>,
        diseñada para facilitar el ejercicio autónomo del
        derecho fundamental de petición por parte de las
        personas privadas de la libertad o sus familiares.
        <br><br>

        De conformidad con el artículo 23 de la Constitución
        Política de Colombia y la Ley 1755 de 2015,
        el ejercicio del derecho de petición no requiere,
        por regla general, la intervención de abogado
        ni apoderado.

        La plataforma actúa como medio de apoyo y canal
        de gestión digital para la presentación de
        solicitudes respetuosas ante las autoridades
        competentes.
      </p>
    </div>

  </body>
</html>
""");

    return buffer.toString();
  }
}
