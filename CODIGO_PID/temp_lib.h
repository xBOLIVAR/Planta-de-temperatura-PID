// encabezados de la libreria temp_lib.h

#include<Arduino.h>

float leerTemperatura(int sensor);
float leerCorriente(int sensor);
void update_past(float v[], int kT);
float PID_Controller(float u[], float e[3], float q0, float q1, float q2);