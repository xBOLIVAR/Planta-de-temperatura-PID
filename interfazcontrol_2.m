%% Monitoreo señales en tiempo real
 function  varargout = interfazControl(varargin)
    parar = false;
    ready = true;     
    fclose('all')      %% cerrar puertos de comunicación

     %%Crear fig    ura, establecer nombre, posicion, color
    fig(1) = figure('name','Control de temperatura','menubar','none','position',[0 0 800 600],'color',[0.2 0.5 0.5]);

    %%Centrar ventana automaticamenta
    movegui(fig(1),'center')

    %% Crear AXE, Establecer posicion, limites
    axe(1) = axes('parent',fig(1),'units','pixels','Position',[60 290 600 200],'xlim',[0 40],'ylim',[10 100],'xgrid','on','ygrid','on')
    axe(2) = axes('parent',fig(1),'units','pixels','Position',[60 45 600 200],'xlim',[0 40],'ylim',[0 100],'xgrid','on','ygrid','on')

    set(get(axe(1),'xlabel'),'string','Tiempo (seg)');
    set(get(axe(1),'ylabel'),'string','Tempertaura (°C)');
    set(get(axe(2),'xlabel'),'string','Tiempo (seg)');
    set(get(axe(2),'ylabel'),'string','Control (%)');

    lin(1) = line('parent',axe(1),'xdata',[], 'ydata',[],'color','g','linewidth',2);
    lin(2) = line('parent',axe(1),'xdata',[], 'ydata',[],'color','r','linewidth',2);
    lin(3) = line('parent',axe(2),'xdata',[], 'ydata',[],'color','r','linewidth',2);

    texto(1) = uicontrol('parent',fig(1),'Style','text','string','Puerto','position',[680 460 100 30],'Background',[0.2 0.5 0.5],'fontsize',12);
    texto(2) = uicontrol('parent',fig(1),'Style','text','string','Setpoint','position',[680 197 100 50],'Background',[0.2 0.5 0.5],'fontsize',12);
    texto(3) = uicontrol('parent',fig(1),'Style','text','string','Grafico','position',[680 294 100 50],'Background',[0.2 0.5 0.5],'fontsize',12);

    bot(1) = uicontrol('parent',fig(1),'style','pushbutton','String','Detener','Position',[680 47,100,30],'callback',@stop,'fontsize',11);
    bot(2) = uicontrol('parent',fig(1),'style','pushbutton','String','Enviar','Position',[680 157,100,30],'callback',@enviar,'fontsize',11);
    bot(3) = uicontrol('parent',fig(1),'style','pushbutton','String','Salvar','Position',[680 291,100,30],'callback',@salvar,'fontsize',11);
    bot(4) = uicontrol('parent',fig(1),'style','pushbutton','String','Iniciar','Position',[680 410,100,30],'callback',@iniciar,'fontsize',11);

    txbx(1) = uicontrol('parent',fig(1),'Style','text','string','Temp','position',[680 360 100 20],'fontsize',11);
    txbx(2) = uicontrol('parent',fig(1),'Style','edit','string','0','position',[680 194 100 20],'fontsize',11);
    
    start = 0;
    
    ports = serialportlist;
    
    if isempty(ports)
        ports = 'NONE';
        clc
        disp('No se ha encontrado CONEXION con el dispositivo de control');
    else
        start = 1;
    end
    
    puerta = ports(1);
    popup = uicontrol('parent',fig(1),'Style','popup','string',ports,'position',[680 439 100 30],'fontsize',11,'Callback',@puertas);
    
    %% Funcion iniciar
    function varargout = iniciar(hObject,evendata)
        ready = false;
    end

    %% Funcion parar
    function varargout = stop(hObject,evendata)
        parar = true;
        fwrite(serialport,'S000$','uchar');
        fclose(serialport);
        delete(serialport);
        clear serialport;
    end
    
    %% Funcion enviar
    function varargout = enviar(hObject,evendata)
        deg1 = get(txbx(2),'string');
        % Se asegura de hacer que deg1 tenga 3 caracteres
        while(strlength(deg1)<3)
            deg1=["0"+deg1];
        end
        deg = ["S"+deg1+"$"+"S"+deg1+"$"];
        fwrite(serialport,deg,'uchar');
    end

    %% Funcion puerto
    function varargout = puertas(hObject,evendata)
        puerta = popup.String{popup.Value};
    end

    %% Funcion salvar
    function varargout = salvar(hObject,evendata)
        % Renombra variables
        rs = escalon;
        us = control;
        ys = salida;
        ts = tiempo;
        
        % Grafica datos
        figure 
        subplot(2,1,1);
        plot(ts,rs,ts,ys,'linewidth',3),grid
        
        title('Laboratorio de Temperatura')
        xlabel('Tiempo (s)')
        ylabel('Temperatura (°C)')
        
        subplot(2,1,2);
        plot(ts,us,'linewidth',3),grid
        xlabel('Tiempo (s)')
        ylabel('Control (%)')
        
        % Create a table with the data and varialbe names
        % T = table(ts, rs, ys, us, 'VariableNames', {'t','r','y','u'});
        T = [ts;rs;ys;us];
        filter = {'.txt';'.xls'};
        [file,path,indx] = uiputfile(filter);
        fileID = fopen(strcat(path,file),'w');
        fprintf(fileID,'%12s %12s %12s %12s\n','t','r','y','u');
        fprintf(fileID,'%12.2f %12.2f %12.2f %12.2f\n',T);
        fclose(fileID);
        file(end-2:end) = 'mat';
        save(strcat(path,file),'ts','rs','ys','us')
    end

    %% Funcion graficar
    tiempo = [0];
    salida = [0];
    escalon = [0];
    control = [0];
    deg1 = "0";
    
    dt = 1;
    limx = [0 40];
    limy = [10 100];
    set(axe(1),'xlim',limx,'ylim',limy);
    
    while(ready)
        pause(1);
    end
    
    if start
        %% Configura el puerto serial
        serialport = serial(puerta);
        set(serialport,'Baudrate',9600); % Se configura la velocidad a 9600 Baudios
        set(serialport,'StopBits',1); % Se configura bit de parada a 1
        set(serialport,'DataBits',8); % Se configura que el dato es de 8 bits, debe estar en 5 y 8
        set(serialport,'Parity','none'); % Se configura sin paridad
        
        fopen (serialport);
        
        %% Grafico
        k = 0; nit = 10000;
        while(~parar)
            % Lectura del dato por puerto serial
            variable = (fread(serialport,30,'uchar'));
            ini = find(variable == 73); % Busca el I (Primer Dato)
            ini = ini(1) + 1;
            fin = find(variable == 70); % Busca F (Ultimo Dato)
            fin = fin(find(fin > ini)) - 1;
            fin = fin(1);
            tempC = char(variable(ini:fin))';
            temp = str2num(tempC);
            
            % Lectura de la señal de control
            ini = find(variable == 67); % Busca el C (Primer Dato)
            ini = ini(1) + 1;
            fin = find(variable == 82); % Busca R (Ultimo Dato)
            fin = fin(find(fin > ini)) - 1;
            fin = fin(1);
            Con1 = char(variable(ini:fin))';
            cont = str2num(Con1);
            
            % Actualizar la temperatura numerica
            set(txbx(1),'string',tempC);
            
            tiempo = [tiempo tiempo(end) + dt];
            salida = [salida temp];
            control = [control cont];
            escalon = [escalon str2num(deg1)];
            set(lin(1),'xdata',tiempo,'ydata',salida);
            set(lin(2),'xdata',tiempo,'ydata',escalon);
            set(lin(3),'xdata',tiempo,'ydata',control);
            pause(dt); %% Espera 1 segundo para cada interacion
            
            if tiempo(end) >= limx % Actualiza grafica cuando llegaa su limite en tiempo real
                limx = [0 limx(2) + 40];
                set(axe(1),'xlim',limx);
                set(axe(2),'xlim',limx);
            end
            
            if salida(end) >= limy % Actualiza grafica cuando llegaa su limite en tiempo real
                limy = [10 limy(2) + 5];
                set(axe(1),'ylim',limy);
            end
            
            if escalon(end) >= limy % Actualiza grafica cuando llegaa su limite en tiempo real
                limy = [10 escalon(end) + 5];
                set(axe(1),'ylim',limy);
            end 
            
            k = k + 1;
            
            if(k == nit)
                parar = true;
            end
        end
        parar = false;
    end
end
