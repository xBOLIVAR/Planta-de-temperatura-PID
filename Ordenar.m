%% Programa de identificación
load('planta.mat')
plot(ts,us,ts,ys,'linewidth',2),grid
title('Datos de la identificación')
xlabel('Tiempo (s)')
ylabel('Temperatura (°C)')

%% Escalón donde se hizo la identificación
b = 12;

%% Buscar el momento donde se inicia el escalon
i = 1;
while(us(i) < b)
    i= i + 1;
end
 
x1 = i;
while(us(i) == b)
    i= i + 1;
end

x2 = i - 1;

%% Recortar datos hasta el origen
ur = us(x1:x2)';
yr = ys(x1:x2)'; 
tr = ts(x1:x2)';

%% Trasladar Ios datos
ut = ur - us(1);
yt = yr - ys(2);
tt = tr - ts(1); 

%% Graficar datos trasladados
figure(2)
plot(tt,ut,tt,yt, 'linewidth', 2),grid
title('Datos trasladados')
xlabel('Tiempo (s)')
ylabel('Temperatura (°C)')