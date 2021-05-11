%{
This script serves as analysis for the wafer positioning system of PMD. 
%}
clear;
close all;
set(0,'defaultTextInterpreter','latex'); %trying to set the default

%% Settings
    userSettings.animate = true;
        T0 = 273.15;    % K
        T1 = 0.0015;    % K
    userSettings.Amplification = 1000; %Amplifies the schrink with a factor A for all bodies.
    userSettings.PlotMaterials = true;
 

    
%% Initialisation
% Creating wafer at T0 = 273.15K (Default)
    waferRadius = 300;                             % mm
    material = 'Silicon';
    alpha_L = @alphaSilicon;                        % Thermal expansion model                 

    % Create rough object 
    angles = linspace(-150, 150, 50);
    Pos = waferRadius*[cosd(angles); sind(angles)];

    wafer = body(Pos, alpha_L, material, userSettings);     % Actual wafer object

% Creating support
    material = 'Copper';
    alpha_L = @alphaCopper;
    
    radius = 30;
    
    support = body(Pos, alpha_L, material, userSettings);

%% Analysis
% Thermal expansion coefficients plot to test. 
if userSettings.PlotMaterials == true
    plotMaterials();
end 

% Move to test
    wafer.move([0,0]',0);
  
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
        % Update and plot wafer
        wafer.cool(T); %Cool from current temperature to T
        waferP = wafer.show(gca, 'k');
        Plots = [Plots, waferP];
        
        % Update text
        Text = text(200 + wafer.pos(1),300+wafer.pos(2),['T = ',num2str(round(T,2)),' K']);
        Plots = [Plots,Text];
        
        % Housekeeping
        if userSettings.animate == true && T ~= T1
            pause(0.05);
            delete(Plots);
        end
    end
     