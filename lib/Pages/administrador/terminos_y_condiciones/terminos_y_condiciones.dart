import 'package:flutter/material.dart';
import '../../../commons/main_layaout.dart';

class TerminosCondicionesPage extends StatelessWidget {
  const TerminosCondicionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Términos y Condiciones',
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14.0, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                text: 'TÉRMINOS Y CONDICIONES DE USO DE LA PLATAFORMA TU PROCESO YA\n\n',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '1. OBJETO\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Tu Proceso Ya tiene como finalidad facilitar la redacción y gestión de derechos de petición y tutelas para personas privadas de la libertad en calidad de condenados en Colombia. No constituye un servicio de asesoría o representación jurídica, ya que tanto los derechos de petición como las tutelas pueden ser instaurados directamente por cualquier ciudadano sin la necesidad de ser abogado. La plataforma actúa como un medio de apoyo documental para quienes deseen presentar estos recursos.\n\n',
              ),
              TextSpan(
                text: '2. REQUISITOS Y OBLIGACIONES DEL USUARIO\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '2.1. Veracidad de la información: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'El usuario está obligado a proporcionar información completa, exacta y veraz. La falsificación de datos, la omisión de información relevante o el suministro de datos engañosos podrá generar el rechazo de la solicitud y la posibilidad de tomar acciones legales.\n\n',
              ),
              TextSpan(
                text: '2.2. Uso personal e intransferible: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'La cuenta del usuario es personal e intransferible. Cualquier intento de suplantación de identidad, uso de documentos falsos o de terceros sin autorización constituirá una falta grave y podrá dar lugar a la cancelación de los servicios.\n\n',
              ),
              TextSpan(
                text: '2.3. Prohibición de manipulación o entorpecimiento de trámites: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'El usuario no podrá realizar acciones que entorpezcan el normal desarrollo de los procesos o que tengan como finalidad afectar de manera fraudulenta la ejecución de los trámites jurídicos. Cualquier conducta que busque alterar el debido proceso podrá ser reportada a las autoridades competentes.\n\n',
              ),
              TextSpan(
                text: '2.4. Responsabilidad en la gestión documental: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'La carga y envío de documentos debe cumplir con los requisitos legales. La plataforma no se hará responsable por errores en la información suministrada por el usuario ni por consecuencias derivadas de la inexactitud o falsedad de la misma.\n\n',
              ),
              TextSpan(
                text: '3. ALCANCE DEL SERVICIO\n\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '3.1. La plataforma no ofrece asesoría jurídica personalizada ni representación legal en procesos judiciales',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '. Su función se limita a facilitar la gestión documental para la elaboración y presentación de derechos de petición y tutelas.\n\n',
              ),
              TextSpan(
                text: '3.2. No se garantiza el resultado favorable de las solicitudes tramitadas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '. La resolución final de cada petición o tutela depende exclusivamente de las entidades judiciales y penitenciarias competentes. Los tiempos de respuesta pueden variar según la carga administrativa y los procedimientos internos de cada entidad, por lo que la plataforma no es responsable de retrasos o demoras en la resolución de los casos.\n\n',
              ),
              TextSpan(
                text: '3.3. La plataforma se reserva el derecho de rechazar solicitudes que:\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '3.3.1. No cumplan con los requisitos legales o presenten errores en su redacción.\n',
              ),
              TextSpan(
                text: '3.3.2. Contengan información falsa, fraudulenta o contradictoria.\n',
              ),
              TextSpan(
                text: '3.3.3. Estén relacionadas con asuntos ajenos a su alcance o que impliquen asesoría jurídica personalizada.\n\n',
              ),
              TextSpan(
                text: '4. SANCIONES Y CONSECUENCIAS POR INCUMPLIMIENTO\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Cualquier intento de suplantación, falsificación de documentos o información será motivo de cancelación inmediata del acceso a la plataforma y la denegación del servicio. Dependiendo de la gravedad del incumplimiento, la plataforma podrá tomar acciones legales ante las autoridades competentes.\n\n',
              ),
              TextSpan(
                text: '5. LIMITACIÓN DE RESPONSABILIDAD\n\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: '5.1. La plataforma no se hace responsable por errores, omisiones o demoras atribuibles a las entidades a las cuales se dirigen las solicitudes.\n',
              ),
              TextSpan(
                text: '5.2.  Los tiempos de respuesta de las solicitudes dependen exclusivamente de las entidades judiciales y penitenciarias, y pueden estar sujetos a retrasos administrativos ajenos a la plataforma.\n',
              ),
              TextSpan(
                text: '5.3.  No garantizamos la disponibilidad ininterrumpida de la plataforma. En caso de fallas tecnológicas, se realizarán los esfuerzos razonables para restablecer el servicio.\n\n',
              ),
              TextSpan(
                text: '6. USO LEGITIMO DE LA PLATAFORMA\n\n',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(
                text: 'Nuestra plataforma no requiere intermediarios. Todos los servicios disponibles en Tu Proceso Ya pueden ser gestionados directamente por los usuarios sin la intervención de terceros. Por lo tanto, le recomendamos abstenerse de realizar pagos a personas que afirmen actuar en nombre de la plataforma o que ofrezcan gestionar trámites a cambio de dinero. Cualquier intento de cobro por servicios no autorizados deberá ser reportado de inmediato.\n\n',
              ),
              TextSpan(
                text: 'Al utilizar esta plataforma, el usuario declara haber leído y aceptado estos Términos y Condiciones.\n\n\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              TextSpan(
                text: "POLÍTICA DE TRATAMIENTO DE DATOS PERSONALES\n\n",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),


              // Sección 1: Identificación
              TextSpan(
                text: "1. IDENTIFICACIÓN DEL RESPONSABLE DEL TRATAMIENTO\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Razón Social: Tu Proceso Ya\n"),
              TextSpan(text: "Actividad Económica: Prestación de servicios de asistencia a personas privadas de la libertad en condición de condenados, facilitando la presentación de derechos de petición y tutelas.\n"),
              TextSpan(text: "Domicilio: Villavicencio - Meta\n"),
              TextSpan(text: "Correo Electrónico de Contacto: contacto@tuprocesoya.com\n\n"),

              // Sección 2: Definiciones
              TextSpan(
                text: "2. DEFINICIONES CLAVES\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Dato personal: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Cualquier información vinculada o que pueda asociarse a una persona natural determinada o determinable.\n\n"),
              TextSpan(text: "Datos sensibles: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Información que afecta la intimidad del titular o cuyo uso indebido podría generar discriminación.\n\n"),
              TextSpan(text: "Autorización: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Consentimiento previo, expreso e informado del titular para llevar a cabo el tratamiento de sus datos.\n\n"),
              TextSpan(text: "Base de datos: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Conjunto organizado de datos personales sometidos a tratamiento.\n\n"),
              TextSpan(text: "Encargado del tratamiento: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Persona natural o jurídica que realiza el tratamiento de datos por cuenta del responsable.\n\n"),
              TextSpan(text: "Responsable del tratamiento: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Persona natural o jurídica que decide sobre la base de datos y/o el tratamiento de los datos.\n\n"),
              TextSpan(text: "Titular de los datos: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Persona natural cuyos datos personales son objeto de tratamiento.\n\n"),
              // Sección 3: Información recolectada
              TextSpan(
                text: "3. INFORMACIÓN RECOLECTADA Y FINALIDAD DEL TRATAMIENTO\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "En el desarrollo de nuestras actividades, recopilamos y tratamos los siguientes datos personales:\n\n"),
              TextSpan(
                text: "3.1 Datos del PPL (Persona Privada de la Libertad)\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "• Nombre, apellidos, tipo y número de identificación.\n"),
              TextSpan(text: "• Información sobre el proceso: Número de identificación interna, TD, tiempo de condena, delito, entre otros.\n\n"),

              TextSpan(
                text: "3.2 Datos del Acudiente\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "• Nombre y apellidos.\n"),
              TextSpan(text: "• Parentesco con el PPL.\n"),
              TextSpan(text: "• Número de celular y correo electrónico.\n\n"),
              TextSpan(
                text: "3.3 Finalidad del Tratamiento\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Los datos personales son recolectados con los siguientes propósitos:\n\n"),
              TextSpan(text: "3.3.1. Prestación del servicio: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Permitir la gestión de derechos de petición y tutelas en favor del PPL.\n\n"),
              TextSpan(text: "3.3.2. Comunicación: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Contactar a los acudientes para actualizaciones sobre los procesos en curso.\n\n"),
              TextSpan(text: "3.3.3. Cumplimiento legal: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Atender requerimientos de entidades judiciales o administrativas en el marco legal colombiano.\n\n"),
              TextSpan(text: "3.3.4. Seguridad y auditoría: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Garantizar la trazabilidad de los servicios prestados.\n\n"),
              TextSpan(text: "3.3.5. Conservación histórica: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Mantener registros que puedan ser necesarios para futuras gestiones legales.\n\n"),

              // Sección 4: Base Legal
              TextSpan(
                text: "4. BASES LEGALES PARA EL TRATAMIENTO DE DATOS\n\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Esta política cumple con la Ley 1581 de 2012 y el Decreto 1377 de 2013.\n\n"),
              TextSpan(text: "• Principio de legalidad: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Solo tratamos los datos conforme a la ley.\n\n"),
              TextSpan(text: "• Principio de finalidad: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Usamos los datos únicamente para los fines mencionados.\n\n"),
              TextSpan(text: "• Principio de libertad: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Los titulares pueden decidir sobre sus datos en cualquier momento.\n\n"),
              TextSpan(text: "• Principio de seguridad: ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "Aplicamos medidas técnicas y organizativas para proteger la información.\n\n"),

              // Sección 5: Seguridad
              TextSpan(
                text: "5. ALMACENAMIENTO Y SEGURIDAD DE LOS DATOS\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Los datos personales se almacenan en servidores de Google, un sistema con altos estándares de seguridad y cifrado. Para "
                  "evitar el acceso no autorizado, implementamos medidas como:\n\n"),
              TextSpan(text: "• Autenticación de usuarios con credenciales seguras.\n\n"),
              TextSpan(text: "• Restricciones de acceso según el rol dentro de la organización.\n\n"),
              TextSpan(text: "• Monitoreo y auditoría de accesos a la información.\n\n"),
              TextSpan(text: "No compartimos datos personales con terceros sin la autorización expresa del titular, salvo que una autoridad competente lo exija.\n\n"),

              // Sección 6: Derechos de los Titulares
              TextSpan(
                text: "6. DERECHOS DE LOS TITULARES\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Los titulares de los datos personales tienen los siguientes derechos, según la Ley 1581 de 2012:\n\n"),
              TextSpan(text: "• Acceder ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "a los datos personales que tenemos registrados.\n\n"),
              TextSpan(text: "• Rectificar ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "información inexacta o desactualizada.\n\n"),
              TextSpan(text: "• Solicitar la eliminación ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "de los datos cuando no sean necesarios para la finalidad para la que fueron recolectados.\n\n"),
              TextSpan(text: "• Revocar la autorización ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "de tratamiento de sus datos personales.\n\n"),
              TextSpan(text: "• Ser informado ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "sobre el uso que se da a sus datos personales.\n\n"),
              TextSpan(text: "Estos derechos pueden ser ejercidos en cualquier momento a través de los canales de contacto mencionados anteriormente.\n\n"),


              // Sección 7: Eliminación de Datos
              TextSpan(
                text: "7. PROCEDIMIENTO PARA ELIMINACIÓN DE DATOS\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Si un titular o su acudiente desea que sus datos sean eliminados de nuestra base de datos, debe seguir estos pasos:\n\n"),
              TextSpan(text: "7.1. Enviar una solicitud escrita ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "a nuestro correo electrónico: datospersonales@tuprocesoya.com.\n\n"),
              TextSpan(text: "7.2. Identificarse plenamente ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "para validar su titularidad sobre los datos.\n\n"),
              TextSpan(text: "7.3. Indicar la información que desea eliminar ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "especificando si desea borrar toda la información o solo algunos datos.\n\n"),
              TextSpan(text: "7.4. Esperar la confirmación ",style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: "que será enviada en un plazo máximo de 10 días hábiles.\n\n"),
              TextSpan(text: "Si la solicitud es aprobada, se eliminarán los datos de nuestra base de datos y se confirmará la eliminación al solicitante.\n\n"),

              // Sección 8: Transferencia Internacional
              TextSpan(
                text: "8. TRANSFERENCIA INTERNACIONAL DE DATOS\n",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Dado que utilizamos los servicios de Google, los datos pueden almacenarse en servidores fuera de Colombia. Sin embargo, "
                  "garantizamos que Google cumple con estándares internacionales de protección de datos, como el GDPR (Reglamento General "
                  "de Protección de Datos de la Unión Europea).\n\n"),
              TextSpan(text: "En caso de futuras transferencias de datos a terceros países, notificaremos a los titulares y obtendremos su "
                  "consentimiento cuando sea requerido..\n\n"),

              // Sección 9: Modificaciones
              TextSpan(
                text: "9. MODIFICACIONES A LA POLÍTICA\n",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Nos reservamos el derecho de modificar esta política de tratamiento de datos en cualquier momento. Cualquier cambio "
                  "será publicado en nuestra plataforma y comunicado a los usuarios registrados.\n\n"),

              // Sección 10: Contacto
              TextSpan(
                text: "10. CONTACTO PARA CONSULTAS Y RECLAMOS\n",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: "Correo: contacto@tuprocesoya.com\n\n\n"),
            ],
          ),
        ),


      ),
    );
  }
}
