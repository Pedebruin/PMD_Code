classdef body < handle
    properties
        material = 'testMaterial';      % Material of the body
        alpha_L;                        % Thermal expansion coefficient (requires a file)
        T0       = 273.15;              % Initial temperature
        T        = 273.15;                % Current temperature
        pos      = [0, 0]';             % Center position
        theta    = 0;                   % Angle with the horizontal (cc positive) [rad]
        Pos      = 10*[-1 1 1 -1;       % Outline of the body at 0,0 ([x;y])
                       -1 -1 1 1]; 
        userSettings;
    end
   
    methods
        % body(), Constructor (set parameters at initialisation)
        function obj = body(Pos, alpha_L, material, userSettings)
            if ~isempty(Pos)
                obj.Pos = Pos;
            end
            if ~isempty(alpha_L)
                if isa(alpha_L,'function_handle')
                    obj.alpha_L = alpha_L;
                else
                    error('alpha_L must be a handle to a function defining the thermal expansion coefficient for a given temperature!');
                end
            end
            if ~isempty(material)
                obj.material = material;
            end
            if ~isempty(userSettings)
                obj.userSettings = userSettings;
            end
        end

        % move(), change position and orientation
        function move(obj,pos,theta)
            % pos:   position of center of body
            % theta: orientation of body (cc positive)
            
            obj.theta = theta;
            obj.pos = pos;

            R = [cosd(obj.theta), -sind(obj.theta);
                sind(obj.theta), cosd(obj.theta)];
            obj.Pos = R*obj.Pos;    % Only rotate, to allow for thermal expansion later on. 
        end
        
        % cool(), expand or contract with some temperature difference. 
        function cool(obj,T1)
            A = obj.userSettings.Amplification;
            
            alphaInt = integral(obj.alpha_L,obj.T,T1,'ArrayValued',true);
            obj.Pos = (1+A*alphaInt)*obj.Pos;
            obj.T = T1;
        end
        
        % show(), Plot current configuration
        function P = show(obj,axName,color)
            if isempty(axName)
                figure()
                axName = gca;
            end
            Pos = obj.Pos + obj.pos;
            P = patch(axName,Pos(1,:),Pos(2,:),color);
            alpha(0.3);
        end
   end
end