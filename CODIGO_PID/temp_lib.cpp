#include "temp_lib.h"

float leerTemperatura(int sensor)
{
	// variables locales para la función
	float promedio, aux;
	int i;

	// filtro de promedio móvil en la lectura del ADC
	aux = 0;
	for(i = 0;i < 10;i++)
	{
		aux = aux + (float(analogRead(sensor))*3.3/1023.0-0.5)/0.01;
		delay(5);
	}
	promedio = aux / 10.0;
	return(promedio);
}

float leerCorriente(int sensor)
{
	// variables locales para la función
	float promedio, aux;
	int i;

	// filtro de promedio móvil en la lectura del ADC
	aux = 0;
	for(i = 0;i < 10;i++)
	{
		aux = aux + (float(analogRead(sensor))*3.3/1023.0);
		delay(5);
	}
	promedio = aux / 10.0;
	return(promedio);
}

// función de actualización
void update_past(float v[],int kT)
{
  int i;
  for(i=1; i<=kT; i++){
    v[i-1] = v[i];
  }
}

// funcion del PID
float PID_Controller(float u[], float e[3], float q0, float q1, float q2){
  
  float lu;
  // e[2] = e(k)
  // e[1] = e(k-1)
  // e[0] = e(k-2)
  // u[0] = u(k-1)
  lu = u[0] + q0*e[2] + q1*e[1] + q2*e[0]; // ley del controlador discreto

  // anti - windup
  if(lu >= 100){
    lu = 100.0;
  }    
  if(lu <= 0.0){
    lu = 0.0;
  }   

  return(lu); 
}