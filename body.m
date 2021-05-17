classdef body < handle
    properties
        name;                           % Name of the body object
        material = 'testMaterial';      % Material of the body
        alpha_L;                        % Thermal expansion coefficient (requires a file)
        color;                          % Color of the body for plotting 'n shit
        R;                              % Radius of the body (assuming everything is round)
        T0       = 273.15;              % Initial temperature
        T        = 273.15;              % Current temperature
        pos      = [0, 0]';             % Center position
        theta    = 0;                   % Angle with the horizontal (cc positive) [rad]
        Pos      = 10*[-1 1 1 -1;       % Outline of the body at 0,0 ([x;y])
                       -1 -1 1 1];
        TC       = [0, 0]';             % Thermal center of the body
        userSettings;                   % Struct to move settings around
    end
   
    methods
        % body(), Constructor (set parameters at initialisation)
        function obj = body(name, Pos, pos, alpha_L, material, R, color, userSettings)
            if ~isempty(name)
                obj.name = name;
            end
            if ~isempty(Pos)
                obj.Pos = Pos;
            end
            if ~isempty(pos)
                obj.pos = pos;
            end
            if ~isempty(alpha_L)
                if isa(alpha_L,'function_handle')
                    obj.alpha_L = alpha_L;
                else
                    error('alpha_L must be a handle to a function defining the thermal expansion coefficient for a given temperature!');
                end
            end
            if ~isempty(R)
                obj.R = R;
            end
            if ~isempty(material)
                obj.material = material;
            end
            if ~isempty(color)
                obj.color = color;
            end
            if ~isempty(userSettings)
                obj.userSettings = userSettings;
            end
        end

        % move(), change position and orientation
        function move(obj,d,theta)
            % d:   Vector to move (relative to old position)
            % theta: orientation of body (cc positive)
            
            obj.theta = theta;
            obj.pos = obj.pos+d;

            R = [cosd(obj.theta), -sind(obj.theta);
                sind(obj.theta), cosd(obj.theta)];
            obj.Pos = R*obj.Pos;    % Only rotate, to allow for thermal expansion later on. 
        end
        
        % cool(), expand or contract with some temperature difference. 
        function cool(obj,T1)
            %{
                This function changes the temperature of a body from the
                current temperature (obj.T) to the provided temperature T1.
                It will integrate the nonlinear thermal expansion
                coefficient form T to T1 and changes the body's size. 
                
                Since the schrinking happens with the TC at the center, the
                entire body is also translated towards the actual TC
                (obj.TC). 
            %}
            A = obj.userSettings.Amplification; % Makes notation easier. 
            alphaInt = integral(obj.alpha_L,obj.T,T1,'ArrayValued',true); % Get NL alpha
            
            d = obj.pos-obj.TC;                 % Vector from center to TC
            dd = alphaInt*d;                    % Change in length of d 
            
            obj.pos = obj.pos + A*dd;           % Move wafer in direction of TC with dd. 
            obj.Pos = (1+A*alphaInt)*obj.Pos;   % Actually schrink
            
            obj.T = T1;                         % Update temperature
            obj.R = (1+A*alphaInt)*obj.R;             % Update radius
            
            if norm(A*dd) >= norm(d) && norm(d) ~= 0
                warnM = ['Amplification for ', obj.name,' too large!, It might invert in figure.'];
                warning(warnM);
        
            end
        end
        % show(), Plot current configuration
        function P = show(obj,axName)
            if isempty(axName)
                figure()
                axName = gca;
            end
            Pos = obj.Pos + obj.pos;
            P1 = patch(axName,Pos(1,:),Pos(2,:),obj.color);
            P = [P1];
            
            % Plot thermal center
            if obj.userSettings.PlotTC == true
                P2 = plot(axName,obj.TC(1),obj.TC(2),'*','Color',obj.color);
                P3 = text(axName,obj.TC(1)+10,obj.TC(2),'TC','Color',obj.color);
                P = [P, P2, P3];
            end
            if obj.userSettings.PlotNames == true
                P4 = text(axName,obj.pos(1),obj.pos(2),obj.name,'HorizontalAlignment','center');
                P = [P, P4];
            end
                
            alpha(0.3);
        end
   end
end