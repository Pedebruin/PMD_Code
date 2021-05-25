%{
This script serves as analysis for the wafer positioning system of PMD. 
Authors:

Thami Fischer
Mansour Khaleqi
Olivia Taal
Jos Boetzkes
Pim de Bruin

The script is set up in three main sections:
%% Settings
    Here, some settings for the script are determined. Mainly about the
    output of the script

%% Initialisation
    Here, the objects are made. The objects are all instances of the class
    'body'. They are also given their properties here. 

%% Analysis
    Here, the actual analysis is performed. This is done in a main loop
    which iterates from T0 to T1. 

The script is dependant on 
body.m              % Class defenition
plotMaterials.m     % Separate plot function for materials plot

All material models:
    Material models available:
    @alphaSilicon           - Nonlinear silicon model
    @alphaSilicon_Linear    - Linear silicon model
    @alphaCopper            - Nonlinear copper model
    @alphaCoppper_Linear    - Linear Copper model
    @alphaZero              - Zero expansion coefficient (for testing mostly)
%}
clear;
close all;
set(0,'defaultTextInterpreter','latex');                                    % Make everything look nice 
addpath('./materialModels');                                                % Add material model folder

%% Settings
    userSettings.animate = true;                % Animate the cooldown?
        userSettings.T0 = 273.15;               % [K] From staring temperature
        userSettings.T1 = 0.0015;               % [K] To ending tempeature
        userSettings.N = 100;                   % Amount of steps from T0 to T1
        userSettings.contactTol = 1e-10;        % mm to assume contact. 
    userSettings.Amplification = 50;            % Amplifies the schrink with a factor A for all bodies.
    userSettings.PlotMaterials = false;         % Show separate material model plot?
    userSettings.PlotContact = true;            % Move the wafer with the contact pins?
    userSettings.PlotTC = false;                % Show the thermal center of the bodies?
    userSettings.PlotNames = true;              % Show the names of the bodies?
    userSettings.plotObjective = false;         % FOR DEBUGGING, OBjective function of fminsearch
    userSettings.plotd = true;                  % Plot the displacement direction d. 
    userSettings.pauseStart = false;            % Pause before the start of the simulation
    
%% Initialisation (Creating the objects)
% Wafer 
    name = 'Wafer';
    waferRadius = 300;                                                      % mm
    material = 'Silicon';
    alpha_L = @alphaSilicon;                                                % Thermal expansion model   
    color = 'k';                                                            % Plot color
    position = [0,0]';                                                      % Initial position

    % Create wafer object 
    flatAngle = 20;                                                         % Angle of the flat on the wafer
    angles = linspace(-(180-flatAngle), 180-flatAngle, 100);                 % Array of angles
    Pos = waferRadius*[cosd(angles); sind(angles)];                         % Array of points to patch

    wafer = body(name, Pos, position, alpha_L, material, waferRadius, 'k', userSettings);     % Actual wafer object
    addprop(wafer,'flatAngle');
    wafer.userData = flatAngle;
    addprop(wafer,'d');
    
% Support pins
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
    angles = linspace(0,359,100);                                            % Array of angles
    Pos_pin = pinRadius*[cosd(angles); sind(angles)];                       % Array of points to patch
    
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

% Placement error!    
    err = [0.5,-0.5]';                                                      % mm
    wafer.move(userSettings.Amplification*err,0);
    wafer.TC = wafer.TC + userSettings.Amplification*err;

    
% Make nice analysis plot
    figure('Name',['Kinematic Coupling ',num2str(userSettings.Amplification),'X'])
    hold on
    axis equal
    grid on
    title(['Thermal cooldown analysis, A= ',num2str(userSettings.Amplification),'X'])
    xlabel('[mm]')
    ylabel('[mm]')
    xlim([-waferRadius, waferRadius]*1.3);
    ylim([-waferRadius, waferRadius]*1.3);
    
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

        
        if userSettings.plotObjective == true
                n = 50;
                input = linspace(-5,5,n);
                objectivePlot = zeros(n);
                waferCopy = copy(wafer);
                for i = 1:n
                    for j = 1:n
                        objectivePlot(i,j) = objective([input(i),input(j)]',waferCopy,pin1,pin2);
                    end
                end
                figure();
                xlabel('pin1 direction [mm]')
                ylabel('pin23 direction [mm]')
                zlabel('Total separation [mm]')
                surf(input,input,objectivePlot)
                pause(2);
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
            contactTol = userSettings.contactTol;
            
            % Look for direction to move the wafer
            while contact1 || contact23 || Iter == 0                        % While there is still contact somewhere
                
                % Detect contact 1 and find direction
                [separation1, d1] = sep1(wafer,pin1);                       % Homecooked function
                if separation1 < -contactTol                    % Overlap! 
                    pin1.color = 'r';
                    contact1 = true;
                else                                                        % No overlap
                    d1 = [0,0]';
                    contact1 = false;
                end

                % Detect contact 2 & 3 and find direction
                [separation23,d23] = sep23(wafer,pin2);                     % Homecooked function
                if separation23 < -contactTol                   % Overlap!
                    pin2.color = 'r';
                    pin3.color = 'r';
                    contact23 = true;
                else % No overlap
                    d23 = [0,0]';
                    contact23 = false;           
                end
             
                %Determine move!
                if contact1 && contact23
                    options = optimset('TolX',userSettings.contactTol,...
                                       'TolFun',userSettings.contactTol);
                    [d,fval,exitflag] = fminsearch(@(d)objective(d,wafer,pin1,pin2),[0,0]',options);
                    if fval >= userSettings.contactTol
                        warning(['Not properly optimised! fval = ',num2str(fval)])
                    end
                elseif contact1 && ~contact23
                    d = d1;
                elseif ~contact1 && contact23
                    d = d23;
                else
                    d = [0,0]';
                end
                
                wafer.move(d,0);
                wafer.TC = wafer.TC + d;
                
                % Save last d
                if norm(d) ~= 0
                    wafer.d = d;
                end
                
                Iter = Iter+1;
            end
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
        if userSettings.PlotContact == true
            str1 = {['T = ',num2str(round(T,2)),' K']...
                ['sep1 = ',num2str(separation1),' mm'],...
                ['sep23 = ',num2str(separation23),' mm']};
            Text1 = text(gca, -325,325,str1);
            Plots = [Plots,Text1];
        end
        
        str2 = {'Wafer.pos:',...
                ['x = ',num2str(wafer.pos(1)),' mm'],...
                ['y = ',num2str(wafer.pos(2)),' mm']};
        Text2 = text(gca, 100, 325,str2);
        Plots = [Plots,Text2];
        
        
        % Update d arrow
        if userSettings.plotd == true
            d = wafer.d;
            if norm(d) ~= 0
                d = userSettings.Amplification*wafer.d/norm(d);
                X = [wafer.pos(1), wafer.pos(1) + d(1)];
                Y = [wafer.pos(2),wafer.pos(2) + d(2)];

                dplot = plot(gca,X,Y,'r');
                Plots = [Plots,dplot];
            end
        end

        % Housekeeping
        if userSettings.pauseStart == true && userSettings.animate == true
            if T == T_v(1)
                disp('Press any key to continue!')
                pause;
            end
        end
    end
    
        
%% Function defenitions
    function absSep = objective(d,wafer,pin1,pin23)
        wafer.move(d,0);
        
        [separation1,~] = sep1(wafer,pin1);
        [separation23,~] = sep23(wafer,pin23);
        

        absSep = abs(separation1) + abs(separation23);

        wafer.move(-d,0);
    end
    
    function [separation1, d1] = sep1(wafer, pin1)
    %{
        This function checks the separation of pin1 and the wafer and
        returns the amount of separation, and the direcion in which the
        separation occurs. 
    %}
        currDist1 = pin1.pos - wafer.pos;                                   % Current distance between centers
        contactDist1 = (wafer.R+pin1.R)*currDist1/norm(currDist1);          % Distance between centes for contact
        separation1 = norm(currDist1)-norm(contactDist1);
        d1 = currDist1 - contactDist1;
    end

    function[separation23, d23] = sep23(wafer,pin2)
    %{
        This function checks the separation of pin2 and the wafer and
        returns the amount of separation, and the direcion in which the
        separation occurs.
    %}

        currDist23 = abs(pin2.pos(1) - wafer.pos(1));                       % Current distance between centers
        contactDist23 = wafer.R*cosd(wafer.userData)+pin2.R;                     % Distance between centers for contact
        separation23 = currDist23-contactDist23;
        d23 = contactDist23 - norm(currDist23);                             % Assume 2&3 can only push in X direction. 
        d23 = [d23,0]'; 
    end