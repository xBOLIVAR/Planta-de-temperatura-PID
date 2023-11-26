#define sensorPlanta A2
#define sensorAmbiente A1
#define sensorCorriente A3
#define actuador 10
#define alarma 9

#define alarma_ON digitalWrite(alarma, HIGH)
#define alarma_OFF digitalWrite(alarma, LOW)

#include "temp_lib.h"
#include <TimerOne.h>

//Seleccion de intefaz grafica con matlab
// 0: Usa el serial plotter de arduino
// 1: Usa la interfaz de matlab


//=========================================
//Variable Globales
//=========================================

float T1, T2, I1, ACT = 0.0;
float w = 0;                             //Referencia
float e[3] = { 0, 0, 0 };                //Vector error
float u[2] = { 0, 0 };                   //Vectro ley de control
int KU = sizeof(u) / sizeof(float) - 1;  //Obtener posicion actual
int KE = sizeof(e) / sizeof(float) - 1;
float kp, ti, td, q0, q1, q2;  // parametros del PID

// modelo del sistema Ziegler y Nichols
float K = 3.7544, tau = 226.84, theta = 13.643;
int Ts = 6;  //periodo de muestreo
float L = theta + Ts / 2;

//sintonia del PID CHR
kp = (0.35 * tau) / (K * L);
ti = 1.16 * L;
td = theta / 2;


//VARIABLES GLOBALES

bool matlab = 1;
int i, ini, fin;
String dato, degC;

int caracter, contador;

void SampleTime(void) {
  contador++;
  if (contador == 2) {
    //Actualizar vectores u e
    update_past(u, KU);
    update_past(e, KE);

    //Calcular error actual
    e[KE] = w - T1;

    //Calcular la accion del controlador PID
    u[KU] = PID_Controller(u, e, q0, q1, q2);
    ACT = u[KU];

    //Aplica la accion de control en el PWM
    analogWrite(actuador, map(ACT, 0, 100, 0, 255));
    contador = 0;
  }
}

void setup() {
  // Configurar los pines de entrada y salida
  pinMode(alarma, OUTPUT);  //Led "Caliente"
  alarma_OFF;
  analogReference(EXTERNAL);  //Referencia Analogica PIN Aref 3.3V (solo si se los sensores lo necesitan y se mete el voltaje deseado en el pin Areference)

  // Configuracion del puerto serial
  Serial.begin(9600);
  analogWrite(actuador, 0);

  Timer1.initialize(6000000);
  Timer1.attachInterrupt(SampleTime);

  // sintonia del PID ZN
  kp = (1.2 * tau) / (K * L);
  ti = 2 * L;
  td = 0.5 * L;

  //controlador PID digital
  q0 = kp * (1 + Ts / (2 * ti) + td / Ts);
  q1 = -kp * (1 - Ts / (2 * ti) + (2 * td) / Ts);
  q0 = (kp * td) / Ts;
}

void loop() {

  // Leer valores analogos
  T1 = leerTemperatura(sensorPlanta);
  T2 = leerTemperatura(sensorAmbiente);
  //I1 = leerTemperatura(sensorCorriente);

  //Destion de alarma
  if (T1 > 40.0) {
    alarma_ON;
  } else {
    alarma_OFF;
  }

  //Recibir datos puerto serial
  // Verificar si se recibio información
  if (Serial.available()) {      // pregunta si existe dato disponible en el puerto serial
    dato = Serial.readString();  // Se almacena informacion de buffer (s35$)
    // s inicio
    // 35 Longuitud del dato
    // $ Enviar información
    for (i = 0; i < 10; i++) {
      if (dato[i] == 'S') {
        ini = i + 1;
        i = 10;
      }
    }
    for (i = 0; i < 10; i++) {
      if (dato[i] == '$') {
        fin = i;
        i = 10;
      }
    }
  }
  // Tomar dato numerico contenido entre s y $
  degC = dato.substring(ini, fin);
  ACT = degC.toInt();
  analogWrite(actuador, map(ACT, 0, 100, 0, 255));
  w = degC.toDouble();

  //Enviar datos por puerto serial
  if (matlab) {  // Potocolo: I20.0I20.0
    //Variable controlada Potocolo: I20.0I20.0
    Serial.print("I");  //Caracter de inicio
    Serial.print(T1);   //Dato de tempertaura en planta
    Serial.print("F");  //Caracter de finalización
    Serial.print("I");  //Caracter de inicio
    Serial.print(T1);   //Dato de tempertaura en planta
    Serial.print("F");  //Caracter de finalización
    //Variable manipulada Protocolo: CACTRCACTR
    Serial.print("C");  //Caracter de finalización
    Serial.print(ACT);  //Variable controlada
    Serial.print("R");  //Dato de tempertaura en planta
    Serial.print("C");  //Caracter de finalización
    Serial.print(ACT);  //Variable controlada
    Serial.print("R");  //Dato de tempertaura en planta

  }

  else {
    Serial.println("Temperatura(C),Actuador(%)");
    Serial.print(T1);
    Serial.print(",");
    Serial.print(ACT);
    Serial.print(",");
    Serial.print(T2);
  }
  /*
  //Imprimir por monitor serial
  Serial.println("-------------------------------");
  Serial.print("Contador:  ");
  Serial.println(contador);

  Serial.print("Temperatura Planta: ");
  Serial.println(T1);

  Serial.print("Temperatura Ambiente: ");
  Serial.println(T2);

  Serial.print("Potencia Actuador: ");
  Serial.println(ACT*100.0/255.0);
  
  contador++;  // Incremento del contador  */
  delay(1000);
}