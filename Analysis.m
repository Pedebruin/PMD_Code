%{
This script serves as analysis for the wafer positioning system of PMD. 

Material models available:
@alphaSilicon - Nonlinear silicon model
@alphaSilicon_Linear - Linear silicon model
@alphaCopper - Nonlinear copper model
@alphaCoppper_Linear - Linear Copper model
@alphaZero - Zero expansion coefficient (for testing mostly)
%}
clear;
close all;
set(0,'defaultTextInterpreter','latex'); %trying to set the default
addpath('./materialModels');

%% Settings
    userSettings.animate = true;                % Animate the cooldown?
        userSettings.T0 = 273.15;               % [K] From staring temperature
        userSettings.T1 = 0.0015;               % [K] To ending tempeature
        userSettings.N = 100;                    % Amount of steps from T0 to T1
        userSettings.maxIter = 10000;           % Maximum amount of loops to solve for d
        userSettings.contactTol = 0;            % Tolerance to determine contact
    userSettings.Amplification = 50;           % Amplifies the schrink with a factor A for all bodies.
    userSettings.PlotMaterials = false;         % Show separate material model plot?
    userSettings.PlotContact = true;            % Move the wafer with the contact pins?
    userSettings.PlotTC = false;                % Show the thermal center of the bodies?
    userSettings.PlotNames = true;              % Show the names of the bodies?
    userSettings.pauseStart = false;            % Pause before the start of the simulation
    userSettings.debug = false;
    
%% Initialisation (Creating the objects)
% Creating wafer
    name = 'Wafer';
    waferRadius = 300;                                                      % mm
    material = 'Silicon';
    alpha_L = @alphaSilicon;                                                % Thermal expansion model   
    color = 'k';
    position = [0,0]';

    % Create wafer object 
    flatAngle = 30;
    angles = linspace(-(180-flatAngle), 180-flatAngle, 50);
    Pos = waferRadius*[cosd(angles); sind(angles)];

    wafer = body(name, Pos, position, alpha_L, material, waferRadius, 'k', userSettings);     % Actual wafer object

% Creating support pins
    material = 'Copper';
    alpha_L = @alphaCopper;
    pinRadius = 40;                                                         % mm
    pin1Angle = 45;                                                         % Angle of pin 1 w.r.t. pos x axis
    d_pins = 150;                                                           % Distance between pin 2&3
    
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

    bodies = {wafer, pin1, pin2, pin3};                                     % Package bodies it for easy looping
    
    
%% Termal cooldown analysis
% Thermal expansion coefficients plot? 
    if userSettings.PlotMaterials == true
        plotMaterials();
    end 

% Test operations.
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
    xlim([-waferRadius, waferRadius]*1.4);
    ylim([-waferRadius, waferRadius]*1.4);
    
    if userSettings.animate == true
        N = userSettings.N;
    else
        N = 1;
    end
    
    T_v = linspace(userSettings.T0, userSettings.T1, N+1);
    Plots = [];
    for T = T_v
        % Cool down       
        for i = 1:size(bodies,2)
            bodies{i}.cool(T);
        end
        
        % Model contact kinematically!
        if userSettings.PlotContact == true
            % Initialisations & Preliminaries
            Iter = 0;
            contact1 = false;
            contact23 = false;
            pin1.color = 'c';
            pin2.color = 'c';
            pin3.color = 'c';
            
            % Look for direction to move the wafer
            while contact1 || contact23 || Iter == 0                        % While there is still contact somewhere
                % Contact 1
                currDist1 = pin1.pos - wafer.pos;                           % Current distance between centers
                contactDist1 = (wafer.R+pin1.R)*currDist1/norm(currDist1);  % Distance between centes for contact
                separation1 = norm(currDist1)-norm(contactDist1);
                if separation1 < 0 % Overlap! 
                    d1 = currDist1 - contactDist1;
                    pin1.color = 'r';
                    contact1 = true;
                else                                                        % No overlap
                    d1 = [0,0]';
                    contact1 = false;
                end

                % Contact 2 & 3
                currDist23 = abs(pin2.pos(1) - wafer.pos(1));                % Current distance between centers
                contactDist23 = wafer.R*cosd(flatAngle)+pin2.R;             % Distance between centers for contact
                separation23 = currDist23-contactDist23;
                if separation23 < 0
                    d23 = (wafer.R*cosd(flatAngle)+pin2.R) - abs(pin2.pos(1)-wafer.pos(1));
                    d23 = [d23,0]';                                         % Assume 2&3 can only push in X direction. 
                    pin2.color = 'r';
                    pin3.color = 'r';
                    contact23 = true;
                else                                                        % No overlap
                    d23 = [0,0]';
                    contact23 = false;           
                end
                
                % Move wafer in determined direction
                d = d1+d23;                                                 % Move to make
                wafer.move(d,0);                                            % Actually move wafer in one step
                wafer.TC = wafer.TC+d;                                      % Move TC with it         
                
                if Iter >= userSettings.maxIter                             % Safeguard for infinite loop
                    warning(['No good wafer move found after ',num2str(Iter-1),' iterations!'])
                    break
                end
                
                Iter = Iter+1;                                              % Update iteration variable
            end
            
            disp(['Move found after ',num2str(Iter-1),' iterations!'])      % If while is broken!
        end
        
        % Kill old bodies
        if userSettings.animate == true 
            pause(0.01);
            delete(Plots);
        end
        
        % Make new bodies
            for i = 1:size(bodies,2)
                Plots = [Plots, bodies{i}.show(gca)];
            end      

        % Update text
        str1 = {['T = ',num2str(round(T,2)),' K']...
            ['sep1 = ',num2str(separation1),' mm'],...
            ['sep23 = ',num2str(separation23),' mm']};
        Text1 = text(gca, -400,350,str1);
        Plots = [Plots,Text1];
        
        str2 = {'Wafer.pos:',...
                ['x = ',num2str(wafer.pos(1)),' mm'],...
                ['y = ',num2str(wafer.pos(2)),' mm']};
        Text2 = text(gca, 100, 350,str2);
        Plots = [Plots,Text2];
        
        % Housekeeping
        if userSettings.pauseStart == true && userSettings.animate == true
            if T == T_v(1)
                disp('Press any key to continue!')
                pause;
            end
        end
    end
     