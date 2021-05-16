%{
This script serves as analysis for the wafer positioning system of PMD. 
%}
clear;
close all;
set(0,'defaultTextInterpreter','latex'); %trying to set the default

%% Settings
    userSettings.animate = false;
        T0 = 273.15;    % K
        T1 = 0.0015;    % K
    userSettings.Amplification = 100; %Amplifies the schrink with a factor A for all bodies.
    userSettings.PlotMaterials = true;
    userSettings.PlotTC = true;
 

    
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

    wafer = body(name, Pos, position, alpha_L, material,'k', userSettings);     % Actual wafer object

% Creating support
    material = 'Copper';
    alpha_L = @alphaCopper;
    pinRadius = 10;                                 % mm
    pin1Angle = 90;                                 % Angle of pin 1 w.r.t. pos x axis
    d_pins = 100;                                         % Distance between pin 2&3
    
    % Pin locations
    pos_pin1 = [cosd(pin1Angle), -sind(pin1Angle);
                sind(pin1Angle), cosd(pin1Angle)]*[waferRadius+pinRadius,0]';
    pos_pin2 = [-waferRadius*cosd(flatAngle)-pinRadius,d_pins/2]';
    pos_pin3 = [-waferRadius*cosd(flatAngle)-pinRadius,-d_pins/2]';
   
    % Pin shape
    angles = linspace(0,359,50);
    Pos_pin = pinRadius*[cosd(angles); sind(angles)];
    
    % Create three pins
    pin1 = body('pin1', Pos_pin, pos_pin1, alpha_L, material, 'c', userSettings);    
    pin2 = body('pin2', Pos_pin, pos_pin2, alpha_L, material, 'c', userSettings);
    pin3 = body('pin3', Pos_pin, pos_pin3, alpha_L, material, 'c', userSettings);

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
        % Update wafer
        wafer.cool(T); %Cool from current temperature to T
        pin1.cool(T);
        pin2.cool(T);
        pin3.cool(T);
        
        % Check contacts
        % TODO
        
        % Plot wafer
        waferP = wafer.show(gca);
        pin1P = pin1.show(gca);
        pin2P = pin2.show(gca);
        pin3P = pin3.show(gca);
        Plots = [Plots, waferP, pin1P, pin2P, pin3P];
        
        % Update text
        Text = text(200 + wafer.pos(1),300+wafer.pos(2),['T = ',num2str(round(T,2)),' K']);
        Plots = [Plots,Text];
        
        % Housekeeping
        if userSettings.animate == true && T ~= T1
            pause(0.05);
            delete(Plots);
        end
    end
     