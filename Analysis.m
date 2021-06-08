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
%% Important parameters
    Here, some important parameters are moved to be easily accessible. 
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
set(0,'defaultTextInterpreter','latex','defaultAxesFontSize',12);                                    % Make everything look nice 
addpath('./materialModels');                                                % Add material model folder
g = 9.813;

%% Settings
    userSettings.animate = true;                % Animate the cooldown?
        userSettings.T0 = 300;                  % [K] From staring temperature
        userSettings.T1 = 0.0015;               % [K] To ending tempeature
        userSettings.N = 100;                   % Amount of steps from T0 to T1
        userSettings.contactTol = 1e-10;        % mm to assume contact. 
    userSettings.Amplification = 1;            % Amplifies the schrink with a factor A for all bodies.
    userSettings.PlotMaterials = false;         % Show separate material model plot?
    userSettings.PlotContact = true;            % Move the wafer with the contact pins?
    userSettings.PlotKinematics = true;         % Show kinematic analysis lines and cones and stuff
    userSettings.nestingForce = 'F_f';          % Either 'F_n' or 'F_f' to choose between friction or external nesting force. 
    userSettings.PlotTC = false;                % Show the thermal center of the bodies?
    userSettings.PlotNames = true;             % Show the names of the bodies?
    userSettings.plotObjective = false;         % FOR DEBUGGING, OBjective function of fminsearch
    userSettings.plotd = false;                 % Plot the displacement direction d (only when plotKinematics is false)
    userSettings.plotRing = true;               % Show the ring around the pins? (maybe for sanity check or somehing)
    userSettings.pauseStart = false;            % Pause before the start of the simulation
           
%% Important parameters
    % Placement error
    err = [0.1,-0.1]';                               % mm 
    
    % Nesting force
    F_n_mag = 1;                                % Magnitude of nesting force
    F_n_ang = -25;                              % Angle of nesting force w.r.t. pos x axis
    
    % Friction coefficient between copper and silicon
    mu = 0.4;                                   % Friction coefficient silicon and copper. 
    
    % Pin 1 angle
    pin1Angle = 130;                            % Angle of pin 1 w.r.t. pos x axis


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialisation (Creating the objects)
% Wafer!
    name = 'Wafer';
    waferRadius = 150;                                                      % mm
    material = 'Silicon';
    alpha_L = @alphaSilicon;                                                % Thermal expansion model   
    color = 'k';                                                            % Plot color
    position = [0,0]';                                                      % Initial position

    % Create wafer object 
    flatAngle = 20;                                                         % Angle of the flat on the wafer
    angles = linspace(-(180-flatAngle), 180-flatAngle, 100);                % Array of angles
    Pos_wafer = waferRadius*[cosd(angles); sind(angles)];                         % Array of points to patch

    wafer = body(name, Pos_wafer, position, alpha_L, material, waferRadius, 'k', userSettings);     % Actual wafer object
   
    addprop(wafer,'flatAngle');
    addprop(wafer,'weight');
    addprop(wafer,'d');
    wafer.h = 775e-6;   % Thickness of wafer
    wafer.rho = 2330;   % Density silicon [kg/m3]
    wafer.flatAngle = flatAngle;
    wafer.weight = wafer.R/1000*pi^2*wafer.h*wafer.rho;
    wafer.d = [0,0]';
    wafer.userData = flatAngle;
    
% Support!
    material = 'Copper';
    alpha_L = @alphaCopper;
    pinRadius = 12;                                                         % mm
    d_pins = 50;                                                            % Distance between pin 2&3
   
    % Pin locations
    pos_pin1 = R(pin1Angle)*[waferRadius+pinRadius,0]';
    pos_pin2 = [-waferRadius*cosd(flatAngle)-pinRadius,d_pins/2]';
    pos_pin3 = [-waferRadius*cosd(flatAngle)-pinRadius,-d_pins/2]';
    
    % PIN 4
    initSpace = [0,0]';
    pin4Angle = -45;
    pos_pin4 = R(pin4Angle)*[waferRadius+pinRadius,0]' + initSpace;
    
    % Pin shape
    angles = linspace(0,359,100);                                            % Array of angles
    Pos_pin = pinRadius*[cosd(angles); sind(angles)];                       % Array of points to patch
    
    % Create three pins
    pin1 = body('pin 1', Pos_pin, pos_pin1, alpha_L, material, pinRadius, 'c', userSettings);    
    pin2 = body('pin 2', Pos_pin, pos_pin2, alpha_L, material, pinRadius, 'c', userSettings);
    pin3 = body('pin 3', Pos_pin, pos_pin3, alpha_L, material, pinRadius, 'c', userSettings);
    pin4 = body('pin 4', Pos_pin, pos_pin4, alpha_L, material, pinRadius, 'c', userSettings); 
    
    pin1.theta = pin1Angle;
    pin4.theta = pin4Angle;
    
    % Create Ring
    ringInnerRadius = 160;
    ringOuterRadius = 180;
    Pos_ring = [Pos_pin/pinRadius*ringInnerRadius, Pos_pin/pinRadius*ringOuterRadius];
    pos_ring = [0,0]';
    
      
    ring = body('Ring', Pos_ring, pos_ring, alpha_L, material, ringOuterRadius, [0.9290, 0.6940, 0.1250], userSettings); 

    if userSettings.plotRing == true
        bodies = {wafer, pin1, pin2, pin3, ring};                                     % Package bodies it for easy looping
    else
        bodies = {wafer, pin1, pin2, pin3};
    end
%% Termal cooldown analysis
% Thermal expansion coefficients plot? 
    if userSettings.PlotMaterials == true
        plotMaterials();
    end 

% Placement error!    
    wafer.move(userSettings.Amplification*err,0);
    wafer.TC = wafer.TC + userSettings.Amplification*err;

% Nesting force (Through center)
    F_n = F_n_mag*[cosd(F_n_ang), sind(F_n_ang)];
    if F_n_mag <= wafer.weight*g*mu && strcmp(userSettings.nestingForce,'F_n')
        warning(['Nesting force lower then friction force on wafer! ',num2str(F_n_mag),' < ',num2str(wafer.weight*g*mu)])
    end
    
% Make nice analysis plot
    name = 'Kinematic Coupling ';
    figure('Name',name)
    sgtitle([name, 'A = ', num2str(userSettings.Amplification),'X, ','$$',userSettings.nestingForce,'$$'])
    subplot(2,3,[1 2 4 5])
        ax1 = gca;
        hold on
        axis equal
        grid on
        xlabel(ax1,'[mm]')
        ylabel(ax1,'[mm]')
        xlim(ax1,[-waferRadius, waferRadius]*1.5);
        ylim(ax1,[-waferRadius, waferRadius]*1.5);

        
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

        % Plot the objective function to show convexity!
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
                    options = optimset('TolX',contactTol,...
                                       'TolFun',contactTol,...
                                       'maxFunEvals',1000);
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
            pause(0.001)
            delete(Plots);
        elseif userSettings.animate == false
            if size(Plots,2) >= 2
                delete(Plots(end-1:end));
            end
        end
        
        % Make new bodies
            % Bodies
            for i = 1:size(bodies,2)
                Plots = [Plots, bodies{i}.show(ax1)];
            end    
            
            % Cones and lines
            if userSettings.PlotKinematics == true
                
                % Plot & calculate nesting force line
                if strcmp(userSettings.nestingForce,'F_n')
                    nestingForceLine = infLine(ax1,[0,0],F_n,'--g');
                    Plots = [Plots,nestingForceLine];
                    F_n = F_n;
                elseif strcmp(userSettings.nestingForce,'F_f')
                    if norm(wafer.d) ~= norm([0,0])
                        movementLine = infLine(ax1, wafer.pos,wafer.pos-wafer.d,'--r');
                        Plots = [Plots, movementLine];
                        F_f = wafer.weight*g*mu*wafer.d/norm(wafer.d);
                        F_n = F_f;
                    else
                        F_n = [0,0]'; 
                    end
                end
                
                
                F = Force_analysis_f(wafer, pin1, pin2, pin3, F_n, mu);
                coneAngle = atand(mu);                                      % Sorry, didn't know it was this easy...
                
                % If pin 1 contact
                if strcmp(pin1.color,'r')
                    pin1Cone = frictionCone(ax1, pin1, pin1.pos, wafer.pos, pin1.pos, coneAngle);
                    Plots = [Plots,pin1Cone];
                end
                
                % If pin 2 contact
                if strcmp(pin2.color,'r')
                    pin2Cone = frictionCone(ax1, pin2, pin2.pos, [0,pin2.pos(2)]', pin2.pos,coneAngle);
                    pin3Cone = frictionCone(ax1, pin3, pin3.pos, [0,pin3.pos(2)]', pin3.pos,coneAngle);
                    Plots = [Plots,pin2Cone,pin3Cone];
                end
            end

        % Update text
        separation4 = sep1(wafer,pin4);
        if userSettings.PlotContact == true
            xlim = get(ax1,'XLim');
            ylim = get(ax1,'YLim');
            str1 = {['T = ',num2str(round(T,2)),' K']...
                ['sep1 = ',num2str(separation1),' mm'],...
                ['sep23 = ',num2str(separation23),' mm'],...
                [''],...
                ['Wafer position :'],...
                ['x = ',num2str(wafer.pos(1)),' mm'],...
                ['y = ',num2str(wafer.pos(2)),' mm'],...
                [''],...
                ['Weight = ',num2str(wafer.weight),' Kg'],...
                ['F_{nesting} = ',num2str(norm(F_n)),' N'],...
                ['F_{friction} = ',num2str(norm(wafer.weight*g*mu)),' N'],...
                [''],...
                ['F_1 = ',num2str(F(1,1)),' N'],...
                ['F_2 = ',num2str(F(2,1)),' N'],...
                ['F_3 = ',num2str(F(3,1)),' N']};
            Text1 = annotation('textbox', [0.65, 0.2, 0.3, 0.65], 'String',str1,'FitBoxToText','on');
            Plots = [Plots,Text1];
        end
        
        % Update d arrow
        if userSettings.plotd == true && userSettings.PlotKinematics == false
            d = wafer.d;
            if norm(d) ~= 0
                d = userSettings.Amplification*wafer.d/norm(d);
                X = [wafer.pos(1), wafer.pos(1) + d(1)];
                Y = [wafer.pos(2),wafer.pos(2) + d(2)];

                dplot = plot(ax1,X,Y,'r');
                Plots = [Plots, dplot];
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
    
    function Line = infLine(ax, center1, center2, linespec)
    %{
        This function draws an infinite line between two points specified
        by center1 and center2 of color 'linespec'
    %}
        if isequal(center1, center2)
            Line = yline(ax,center1(2),linespec);
        else
            
        % Sort out order
        if center1(1) > center2(1)
            temp = center2;
            center2 = center1;
            center1 = temp;
        end
        
        xlim = get(ax,'XLim');
        a = (center2(2)-center1(2))/(center2(1)-center1(1));
        y1 = center1(2)-a*(center1(1)-xlim(1));
        y2 = center1(2)+a*(xlim(2)-center1(1));
        
        Line = plot(ax, [xlim(1) xlim(2)], [y1 y2],linespec);
        end
    end
    
    function cone = frictionCone(ax,pin,center1, center2, coneCenter, coneAngle)
    
        % Determine cone direction
        if isequal(center1, coneCenter)
            coneDir = center2;
        else 
            coneDir = center1;
        end
        
        coneCenter = coneCenter + pin.R*(coneDir-coneCenter)/norm(coneDir-coneCenter);
        
        % Temporary points through which to draw the cone lines
        tempPoint1 = coneCenter + 10*R(coneAngle)*(coneDir - coneCenter);
        tempPoint2 = coneCenter + 10*R(-coneAngle)*(coneDir - coneCenter);
        
        % Cone lines
        coneLine1 = infLine(ax,coneCenter, tempPoint1, '--b');
        coneLine2 = infLine(ax,coneCenter, tempPoint2, '--b');
            
        % Patch cones
        p = patch(ax,[tempPoint1(1),coneCenter(1),tempPoint2(1)],[tempPoint1(2),coneCenter(2),tempPoint2(2)],...
            'b','faceAlpha',0.1,'edgeAlpha',0);
        
        
        % Contact action line
        Line = infLine(ax,center1, center2, '--k');
        
        cone = [Line, coneLine1, coneLine2, p];
    end
    
    function rotMatrix = R(rotAngle)
    rotMatrix = [cosd(rotAngle) -sind(rotAngle)
            sind(rotAngle) cosd(rotAngle)];
    end
    