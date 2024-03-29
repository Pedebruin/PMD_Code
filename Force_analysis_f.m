function [F] = Force_analysis_f(wafer, pin1, pin2, pin3, F_n, mu)

%Input: 
% r = radius wafer [mm]
% h = distance between flat side and origin wafer [mm]
% L_12 = distance bewteen pin 2 and 3 [mm]
% F_n = nesting force [N]
% phi = angle bewteen nesting force F_n and positive x-axis [radians]
% theta = angle between force in pin 1 and positive x-axis [radians]
% mu = approximate friction coefficient between silicon and copper [-]

%Output:
% F_1 = force at pin 1
% F_2 = force at pin 2
% F_3 = force at pin 3
% F_1_fric = friction force at pin 1
% F_2_fric = friction force at pin 2
% F_3_fric = friction force at pin 3

% Unpack
r = wafer.R;                        % radius wafer [mm]
h = wafer.R*cosd(wafer.userData);  % distance between flat side and origin wafer [mm]
L_23 = norm(pin2.pos-pin3.pos);     % distance bewteen pin 2 and 3 [mm]
theta = pin1.theta;                 % angle between force in pin 1 and positive x-axis [deg]
phi = -atand(F_n(2)/F_n(1));        % angle bewteen nesting force F_n and positive x-axis [deg]

F_n = norm(F_n);                    % nesting force [N]

if F_n == 0
    F = [0, 0, 0;
        0, 0, 0]';
else
    % Solve system of equations to get F1, F2 and F3 
    M_1 = [-cosd(theta) 1 1 ;
        sind(theta) 0 0 ;
        (sind(theta)*(r*cosd(theta) + h) - cosd(theta)*(r*sind(theta) - 0.5*L_23)) 0 -L_23];
    M_2 = F_n * [cosd(phi) ;
        sind(phi) ;
        (sind(phi)*(r*cosd(phi) + h) - cosd(phi)*(r*sind(phi) + 0.5*L_23))];
    F_123 = linsolve(M_1,M_2);

    F = [F_123, F_123*mu];
end


end
