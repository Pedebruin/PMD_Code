function [F_1,F_2,F_3,F_1_fric] = Force_analysis_f(r,h,L_12,F_n,phi,theta,mu);

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


% Solve system of equations to get F1, F2 and F3 
M_1 = [-cos(theta) 1 1 ; sin(theta) 0 0 ; (sin(theta)*(r*cos(theta) + h) - cos(theta)*(r*sin(theta) - 0.5*L_12)) 0 -L_12];
M_2 = F_n * [cos(phi) ; sin(phi) ; (sin(phi)*(r*cos(phi) + h) - cos(phi)*(r*sin(phi) + 0.5*L_12))];
F_123 = linsolve(M_1,M_2)

F_1 = F_123(1)
F_2 = F_123(2)
F_3 = F_123(3)


% Friction force at pin 1, 2 and 3
F_1_fric = F_1 * mu
F_2_fric = F_2 * mu
F_3_fric = F_3 * mu
