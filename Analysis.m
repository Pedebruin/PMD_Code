%{
This script serves as analysis for the wafer positioning system of PMD. 
%}
clear;
close all;
set(0,'defaultTextInterpreter','latex'); %trying to set the default

%% Settings
    userSettings.animate = true;       % Animate the cooldown?
        T0 = 273.15;                    % [K] From staring temperature
        T1 = 0.0015;                    % [K] To ending tempeature
    userSettings.Amplification = 50;    % Amplifies the schrink with a factor A for all bodies.
    userSettings.PlotMaterials = true;  % Show separate material model plot?
    userSettings.PlotContact = true;    % Move the wafer with the contact pins?
    userSettings.PlotTC = false;         % Show the thermal center of the bodies?
    userSettings.PlotNames = true;     % Show the names of th bodies?
    userSettings.pauseStart = false;     % Pause before the start of the simulation
    
%% Initialisation (Creating the objects)
% Creating wafer at T0 = 273.15K (Default)
    name = 'Wafer';
    waferRadius = 300;                              % mm
    material = 'Silicon';
    alpha_L = @alphaSilicon;                        % Thermal expansion model   
    color = 'k';
    position = [0,0]';

    % Create wafer object 
    flatAngle = 30;
    angles = linspace(-(180-flatAngle), 180-flatAngle, 50);
    Pos = waferRadius*[cosd(angles); sind(angles)];

    wafer = body(name, Pos, position, alpha_L, material, waferRadius, 'k', userSettings);     % Actual wafer object


% Creating support
    material = 'Copper';
    alpha_L = @alphaCopper;
    pinRadius = 30;                                 % mm
    pin1Angle = 90;                                 % Angle of pin 1 w.r.t. pos x axis
    d_pins = 200;                                         % Distance between pin 2&3
    
    % Pin locations
    pos_pin1 = [cosd(pin1Angle), -sind(pin1Angle);
                sind(pin1Angle), cosd(pin1Angle)]*[waferRadius+pinRadius,0]';
    pos_pin2 = [-waferRadius*cosd(flatAngle)-pinRadius,d_pins/2]';
    pos_pin3 = [-waferRadius*cosd(flatAngle)-pinRadius,-d_pins/2]';
   
    % Pin shape
    angles = linspace(0,359,50);
    Pos_pin = pinRadius*[cosd(angles); sind(angles)];
    
    % Create three pins
    pin1 = body('pin1', Pos_pin, pos_pin1, alpha_L, material, pinRadius, 'c', userSettings);    
    pin2 = body('pin2', Pos_pin, pos_pin2, alpha_L, material, pinRadius, 'c', userSettings);
    pin3 = body('pin3', Pos_pin, pos_pin3, alpha_L, material, pinRadius, 'c', userSettings);

    bodies = {wafer, pin1, pin2, pin3}; % Package bodies it for easy looping
%% Analysis
% Thermal expansion coefficients plot to test. 
    if userSettings.PlotMaterials == true
        plotMaterials();
    end 

% Test operations!
    wafer.move([0,0]',0);
    wafer.TC = [0,0]';
  
% Make nice analysis plot
    figure('Name','Kinematic Coupling')
    hold on
    axis equal
    grid on
    title('Thermal cooldown analysis')
    xlabel('[mm]')
    ylabel('[mm]')
    xlim([-waferRadius, waferRadius]*1.5);
    
    if userSettings.animate == true
        N = 75;
    else
        N = 1;
    end
    
    T_v = linspace(T0, T1, N+1);
    Plots = [];
    for T = T_v
        % Cool down       
        for i = 1:size(bodies,2)
            bodies{i}.cool(T);
        end
        if userSettings.PlotContact == true
            pin2pos = pin2.pos;
            while norm(wafer.pos-pin1.pos) < (wafer.R+pin1.R) || abs(pin2pos(1)-wafer.pos(1)) < (wafer.R*cosd(flatAngle)+pin2.R)
                % Check contacts (Bit crude stepping, Look at this next time!)
                % Contact 1 only
                if norm(wafer.pos-pin1.pos) < (wafer.R+pin1.R) 
                    d = (pin1.pos - wafer.pos) - (wafer.R+pin1.R)*(pin1.pos - wafer.pos)/norm(pin1.pos - wafer.pos);
                    wafer.move(wafer.pos+d,0);
                    wafer.TC = wafer.TC+d;
                    pin1.color = 'r';
                else
                    pin1.color = 'c';
                    % DO nothing, the pin has moved away from the wafer, so wafer
                    % stays stationary
                end

                % Contact 2 & 3 only
                if abs(pin2pos(1)-wafer.pos(1)) < (wafer.R*cosd(flatAngle)+pin2.R)
                    d = abs(pin2pos(1)-wafer.pos(1))-(wafer.R*cosd(flatAngle)+pin2.R);
                    wafer.move(wafer.pos+[-d,0]',0);
                    wafer.TC = wafer.TC+[-d,0]';
                    pin2.color = 'r';
                    pin3.color = 'r';
                else
                    pin2.color = 'c';
                    pin3.color = 'c';
                    % DO nothing, the pin has moved away from the wafer, so wafer
                    % stays stationary            
                end
            end
        end
        
        % Plot wafer
        for i = 1:size(bodies,2)
            Plots = [Plots, bodies{i}.show(gca)];
        end
        
        % Update text
        Text = text(200 + wafer.pos(1),300+wafer.pos(2),['T = ',num2str(round(T,2)),' K']);
        Plots = [Plots,Text];
        
        % Housekeeping
        if userSettings.pauseStart == true && userSettings.animate == true
            if T == T_v(1)
                disp('Press any key to continue!')
                pause;
                
            end
        end
        if userSettings.animate == true && T ~= T1
            pause(0.05);
            delete(Plots);
        end

    end
     