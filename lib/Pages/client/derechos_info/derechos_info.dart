import 'package:flutter/material.dart';
import 'package:tuprocesoya/commons/main_layaout.dart';
import 'package:tuprocesoya/src/colors/colors.dart';

class DerechosInfoPage extends StatelessWidget {
  const DerechosInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      pageTitle: 'Derecho Penitenciario',
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(6.0),
        child: Center(
          child: SizedBox(
            // Limita el ancho máximo para una mejor legibilidad en pantallas grandes.
            width: MediaQuery.of(context).size.width >= 1000 ? 1000 : double.infinity,
            child: const Column(
              children: [
                SizedBox(height: 30),
                Text("Derechos de la persona privada de la libertad", style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                  height: 1
                )),
                SizedBox(height: 15),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 16, height: 1.3, color: Colors.black, fontWeight: FontWeight.normal),
                    children: [
                      TextSpan(
                        text:
                        "En el ordenamiento jurídico colombiano la libertad ocupa un lugar prevalente y de máxima importancia, esta es "
                            "concebida como un derecho fundamental; asimismo un principio y el sustento de cualquier democracia."
                          " No obstante, este derecho no es absoluto y en algunas ocasiones, excepcionales, puede ser restringido, "
                            "siempre y cuando se reúnan ciertos requisitos.\n\nEsto tiene fundamento en el artículo 28 de la "
                            "Constitución Política de Colombia, el cual sostiene que: \n\n",
                          style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w400)
                      ),
                      TextSpan(
                        text: '“toda persona es libre. Nadie puede ser molestado en su persona o familia, ni reducido a prisión o arresto, ni detenido, '
                            'ni su domicilio registrado, sino en virtud de mandamiento escrito de autoridad judicial competente, con las '
                            'formalidades legales y por motivo previamente definido en la ley.”\n\n',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris),
                      ),
                      TextSpan(
                          text:
                          "En ese sentido, el ordenamiento jurídico colombiano permite limitaciones a la libertad cuando estas estén claramente "
                              "definidas por la ley. Esto se ve reflejado en el artículo 6 de la Ley 599 de 2000, el cual incorpora el "
                              "principio de legalidad, que dice así: \n\n", style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                        text: '“(…) nadie podrá ser juzgado sino conforme a las leyes preexistentes al acto que se le imputa, ante el juez o tribunal '
                            'competente y con la observancia de la plenitud de las formas propias de cada juicio”\n\n',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris),
                      ),
                      TextSpan(
                          text:
                          " En Colombia solo se le puede privar de la libertad a una persona en virtud de la "
                              "imposición de una medida preventiva de aseguramiento y la condena por la comisión "
                              "de un delito. En el caso de la medida preventiva de aseguramiento, esta solo procede "
                              "cuando es necesaria para garantizar la comparecencia, la preservación de la prueba o "
                              "la protección de la comunidad, especialmente de las víctimas. En el caso de la imposición"
                              "de una sentencia privativa de la libertad, esta debe realizarse por una autoridad "
                              "judicial competente, en un juicio justo, imparcial y sin violación del debido proceso. "
                              "Por lo anterior, las reglas, procedimientos, formalidades y motivos por los cuales se "
                              "puede privar de la libertad deben estar lo suficientemente claros y prestablecidos en "
                              "la ley, en caso de que la privación no se haga conforme a dichas reglas se estará ante una "
                              "detención arbitraria o una privación injusta de la libertad.\n\n", style: TextStyle(fontSize: 14)
                      ),

                      // Subtítulo 1.2 y contenido
                      TextSpan(
                        text: "La relación especial de sujeción\n",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                        "Una vez las personas son privadas de la libertad por el Estado, este asume de manera "
                            "objetiva y certera la responsabilidad de garantizar los derechos de los reclusos, esto "
                            "en virtud de aquello que la doctrina jurídica y la jurisprudencia han denominado la relación especial de sujeción.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                        text:
                        " Esta relación, es aquella que se genera cuando la persona privada de la libertad queda "
                            "subordinada (sujeta) al poder estatal debido a la suspensión y restricción de sus derechos "
                            "y libertades, razón por la que ya no puede desenvolverse como lo haría en libertad para "
                            "proveerse a sí misma de lo fundamental y suplir sus necesidades básicas. Es por ello que el "
                            "Estado asume una posición de garante derivada de dicha relación de sujeción.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          " La reclusión de personas bajo la custodia del Estado genera una responsabilidad sobre los "
                              "mismos. Según la Corte Constitucional en la sentencia T-143 de 2017, implica:\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                        text: ' “… por un lado, responsabilidades relativas a su seguridad y a su conminación bajo el '
                            'perímetro carcelario (potestad disciplinaria y administrativa) y, por el otro, obligaciones '
                            'en relación con sus condiciones materiales de existencia e internamiento.”\n\n',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris),
                      ),
                      TextSpan(
                          text:
                          "En la misma sentencia se afirma que la relación especial de sujeción genera derechos "
                              "y obligaciones a cargo de ambas partes, esto se manifiesta de la siguiente manera:\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                        text: '“el deber a cargo del Estado de asegurar un trato humano y digno, el de proporcionar alimentación '
                            'adecuada y suficiente, vestuario, utensilios de aseo e higiene personal, instalaciones en condiciones '
                            'de sanidad y salud adecuadas con ventilación e iluminación y el deber de asistencia médica. Por su '
                            'parte, el interno tiene derecho al descanso nocturno en un espacio mínimo vital, a no ser expuesto '
                            'a temperaturas extremas, a que se le garantice su seguridad, a las visitas íntimas, a ejercitarse físicamente, '
                            'a la lectura, al ejercicio de la religión y el acceso a los servicios públicos como energía y agua '
                            'potable, entre otros supuestos básicos que permitan una supervivencia decorosa.”\n\n',
                        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris),
                      ),

                      TextSpan(
                          text:
                          "En síntesis, la relación especial de sujeción entre reclusos y el estado nos permite entender la "
                              "correspondencia mutua de los derechos y deberes entre personas privadas "
                              "de la libertad y las autoridades penitenciarias. Pues gracias a la sujeción a la que están "
                              "obligados los reclusos se crea un:\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          '"régimen jurídico peculiar que se traduce en un especial tratamiento de la libertad y de los derechos fundamentales",',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris)
                      ),
                      TextSpan(
                          text:
                          " poniéndolos en una situación de indefensión; razón por la que:\n\n ",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "El estado asume la obligatoriedad de PROTEGER, RESPETAR Y GARANTIZAR "
                              "los derechos fundamentales, inclusive aquellos que permiten su limitación.\n\n",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),

                      // Subtítulo 1.3 y contenido
                      TextSpan(
                        text: "Derechos suspendidos\n",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text:
                          "Desde el momento en que la persona queda bajo la custodia del estado en virtud de "
                              "la imposición de una medida de aseguramiento o de una sentencia condenatoria de "
                              "privación de la libertad, empieza a operar una suspensión de dos derechos fundamentales, "
                              "en particular de:",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          " la libertad física y de la libertad de locomoción\n\n",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      TextSpan(
                          text:
                          "Esta suspensión "
                              "trae como consecuencia la imposibilidad de ejercer cualquiera de estos derechos "
                              "durante un tiempo específico, el cual se corresponde con el de la imposición de la "
                              "pena previamente descrita por la sentencia condenatoria, la cual debe estar en "
                              "concordancia con la ley.\n\nEn el caso de las personas condenadas también puede "
                              "operar la suspensión de derechos políticos, durante el tiempo que haya determinado "
                              "la sentencia condenatoria. Contrario sucede con las personas que se encuentran en "
                              "calidad de sindicadas, quienes a pesar de estar privadas de la libertad fruto de "
                              "una medida de aseguramiento, en teoría sus demás derechos no le pueden ser suspendidos, "
                              "pues la suspensión seria irrazonable y despro porcionada a la luz de los fines preventivos "
                              "de la medida de aseguramiento.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),

                      // Subtítulo 1.4 y contenido
                      TextSpan(
                        text: "Derechos limitados\n",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text:
                          "Fruto de la privación del derecho fundamental a la libertad y el surgimiento de la "
                              "relación especial de sujeción, la cual genera deberes del Estado con los internos y "
                              "obligaciones de los privados de la libertad con los regímenes disciplinarios y penitenciarios; "
                              "se crea una gama de derechos cuyo goce y ejercicio está limitado, es decir, no "
                              "se pueden ejercer de manera plena y absoluta.\n\nLa limitación de ciertos derechos fundamentales "
                              "de las personas privadas de la libertad contempla la posibilidad de que estos sean ejercidos "
                              "en el marco de unas circunstancias específicas derivadas de la privación de la libertad, como "
                              "lo es la sujeción a un régimen disciplinario, la seguridad, la salubridad y otras disposiciones "
                              "penitenciarias y administrativas.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "Al respecto, la Corte Constitucional en la sentencia T-049 de 2016 sostiene que existen\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          '“Los derechos restringidos o limitados por la especial sujeción del interno al Estado, con lo cual '
                              'se pretende contribuir al proceso de resocialización y garantizar la disciplina, la seguridad y la '
                              'salubridad en las cárceles. Entre estos derechos se encuentran el de la intimidad personal y '
                              'familiar, unidad familiar, de reunión, de asociación, libre desarrollo de la personalidad, libertad '
                              'de expresión, trabajo y educación.\n\n',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris)
                      ),
                      TextSpan(
                          text:
                          "Lo anterior, no quiere decir que sean permitidos los obstáculos o barreras injustificadas en el ejercicio de "
                              "derechos restringidos. Toda limitación debe estar sujeta a los principios de necesidad, racionalidad o razonabilidad y "
                              "proporcionalidad. Estos principios son los que adecuan los medios con los fines, es decir, "
                              "los medios disciplinarios, penitenciarios y administrativos deben ser adecuados para el cumplimiento "
                              "del fin resocializador, reparador y preventivo de privación de la libertad. \n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          " En el caso que las actuaciones de las autoridades de custodia y vigilancia no estén "
                              "orientadas por dichos principios, su accionar dejaría de estar justificado y podría "
                              "tornarse en arbitrario. En ese mismo sentido la Corte Constitucional ha sostenido que \n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          '“La razonabilidad y proporcionalidad de la medida son pues, los parámetros con que cuenta la '
                              'administración y el poder judicial, para distinguir los actos amparados constitucionalmente, de aquellos actos arbitrarios”.\n\n',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris)
                      ),
                      TextSpan(
                          text:
                          " Al no encontrarse las decisiones penitenciarias plenamente justificadas por tales criterios, "
                              "se convierten en una medida caprichosa, susceptible de ser demandada por ser violatoria de los derechos y garantías fundamentales.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "Se dice que ",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "una medida es necesaria, ",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      TextSpan(
                          text:
                          "cuando no hay ninguna otra que pudiera "
                              "garantizar mejor el fin perseguido. Por ejemplo, la imposición de las esposas mientras la "
                              "persona se encuentra en un traslado o remisión, para evitar una fuga o incidente que ponga "
                              "en peligro la vida del privado de la libertad y sus custodios.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "La aplicación de la ",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          " razonabilidad o racionalidad, ",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      TextSpan(
                          text:
                          " se predica de un ejercicio de valoración objetiva de las circunstancias que rodean la orden "
                              "impartida y la finalidad que persigue. Utilizando el mismo caso de la restricción de seguridad durante "
                              "un traslado, supongamos que al interno se le impusieron las esposas durante 6 horas antes de la remisión y "
                              "6 horas posteriores a la misma. Aquí se podría observar que hay un tiempo irrazonable de utilización "
                              "de la medida de restricción, pues las circunstancias de contexto indicarían que las medidas solo se usarían "
                              "mientras estaba siendo trasladado a otro lugar.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          " Ahora, supongamos que no solo le fueron puestas las esposas en las manos sino que también le fueron aseguradas "
                              "las piernas, la cintura y la cabeza. Esto -además de ser violatorio de la dignidad humana- vulneraria el",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "  principio de proporcionalidad",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                      ),
                      TextSpan(
                          text:
                          ", toda vez que el medio para garantizar el fin que es la seguridad ante una fuga o una agresión, resulta "
                              "desmesurado, exagerado y no se corresponde las posibilidades reales de que el riesgo se materialice "
                              "pues la restricción se extralimita y lesiona más derechos que los que busca proteger.\n\nEntonces, podemos "
                              "decir que la limitación de los derechos de las personas privadas de la libertad opera de manera práctica, en "
                              "la forma en que se ejerce un determinando derecho, pero no quiere decir ello que el estado se pueda "
                              "abstener de la garantía de una parte, así sea menor o en determinadas condiciones, de ese derecho.\n\nUn ejemplo "
                              "de ello es la unidad familiar, la limitación consiste en no poder recibir visitas de la familia en todo "
                              "momento. No obstante, esta se garantizara en horarios limitados, en días específicos y con ciertos "
                              "controles, pero de ningún modo se pueden eliminar ni suspender las visitas familiares de manera total.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "Son múltiples los derechos que resultan limitados en el marco de la privación de la libertad, dentro de ellos "
                              "se destaca: \n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "1. Restricciones a la intimidad personal y familiar\n2. Unidad familiar\n3. Restrición de reunión\n4. Restricción de asociación\n"
                              "5. Libre desarrollo de la personalidad\n6. Libertad de expresión\n7. Libertad al trabajo y educación\n8. Restricción "
                              "de asociación\n9. Restricción de visitas\n",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                      ),
                      TextSpan(
                          text:
                          "entre muchos otros.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "No obstante, como se dijo con anterioridad la restricción no significa que no puedan ser garantizados aun con "
                              "sus limitaciones. \n\n",
                          style: TextStyle(fontSize: 14)
                      ),

                      // Subtítulo 1.5 y contenido
                      TextSpan(
                        text: "Derechos inalterables\n",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text:
                          "Ahora, es importante mencionar que existen una serie de derechos que no pueden ser suspendidos ni limitados bajo "
                              "ninguna circunstancia, pues su garantía está estrechamente ligada con la dignidad humana.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          "Este tipo de derechos son los de mayor protección por parte de las autoridades judiciales y penitenciarias cuando "
                              "tienen bajo su tutela a una persona privada de la libertad. Esta obligación ha sido reconocida por la Corte "
                              "Constitucional en la sentencia T-208 de 2018, en la cual sostiene que: \n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          '“Se ha dicho que existe un contenido mínimo de obligaciones estatales frente a este sector marginado de la '
                              'sociedad, independientemente de los hechos por los que hayan sido condenados o acusados o del grado del '
                              'nivel de desarrollo socioeconómico del país donde se encuentren purgando la pena o la medida de '
                              'seguridad, pues lo que está en juego, en estos contextos, es la dignidad inherente del ser humano, que '
                              'constituye justamente el pilar central de la relación entre el Estado y los sujetos con restricciones en su libertad”\n\n ',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris)
                      ),
                      TextSpan(
                          text:
                          "A saber, la jurisprudencia colombiana ha reiterado en múltiples ocasiones que existen derechos que no podrán "
                              "ser sometidos a ninguna restricción para su ejercicio, garantía y cumplimiento. En ese sentido, en la "
                              "sentencia T-153 de 1998, la Corte Constitucional dijo:\n\n",
                          style: TextStyle(fontSize: 14)
                      ),
                      TextSpan(
                          text:
                          ' “Asimismo, derechos como los de la intimidad personal y familiar, reunión, asociación, libre desarrollo de la '
                              'personalidad y libertad de expresión se encuentran restringidos, en razón misma de las condiciones que '
                              'impone la privación de la libertad. Con todo, otro grupo de derechos, tales como:\n\n',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: gris)
                      ),
                      TextSpan(
                          text:
                          "1. La vida e integridad personal\n2. La dignidad\n3. La igualdad\n4. La libertad religiosa\n5. Reconocimiento "
                              "de la personalidad jurídica\n6. El derecho a la salud\n7. El derecho al debido proceso\n8. El derecho de petición\n\n todos ellos, mantienen su incolumidad "
                              "a pesar del encierro a que es sometido su titular.\n\n",
                          style: TextStyle(fontSize: 14)
                      ),

                    ],
                  ),
                  textAlign: TextAlign.justify,
                ),
                Divider(height: 1, color: negro,),
                Text("Fuente: Fundación Comité de Solidaridad con los Presos Políticos; "
                    "'Manual de Derecho Penitenciario; Bogotá Diciembre de 2020.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: negroLetras),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
