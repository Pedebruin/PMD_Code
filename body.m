classdef body < handle
    properties
        material = 'testMaterial';      % Material of the body
        alpha_L;                        % Thermal expansion coefficient (requires a file)
        T0       = 273.15;              % Initial temperature
        T        = 0.15;                % Current temperature
        pos      = [0, 0]';             % Center position
        theta    = 0;                   % Angle with the horizontal (cc positive) [rad]
        Pos      = 10*[-1 1 1 -1;       % Outline of the body at 0,0 ([x;y])
                       -1 -1 1 1];             
    end
   
    methods
        % body(), Constructor (set parameters at initialisation)
        function obj = body(Pos, alpha_L, material)
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
        end

        % move(), change position and orientation
        function move(obj,pos,theta)
            % pos:   position of center of body
            % theta: orientation of body (cc positive)
            
            obj.theta = theta;
            obj.pos = pos;

            R = [cosd(obj.theta), -sind(obj.theta);
                sind(obj.theta), cosd(obj.theta)];
            obj.Pos = R*obj.Pos + obj.pos;
        end
        
        % schrink(), expand or contract with some temperature difference. 
        function schrink(T1)
            
        end
        
        % show(), Plot current configuration
        function P = show(obj,axName,color)
            if isempty(axName)
                figure()
                axName = gca;
            end
            P = patch(axName,obj.Pos(1,:),obj.Pos(2,:),color);
        end
   end
end