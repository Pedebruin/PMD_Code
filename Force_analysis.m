% Constants
r = 150         % milimeters
h = 120         % milimeters
L_12 = 100      % milimeters

% Variables
theta = deg2rad(0)          % degrees
phi = deg2rad(45)           % degrees
F_n = 1.5                   % Newton
mu = 0.4                    % Friction coefficient between copper and silicon (approximately)

% Solve matrix to get F1, F2 and F3 
M_1 = [0 0 cos(theta); 1 1 -sin(theta) ; L_12 0 (-cos(theta)*(r*sin(theta) + h) + sin(theta)*(r*cos(theta) - 0.5*L_12))];
M_2 = F_n * [cos(phi) ; sin(phi) ; (-cos(phi)*(r*sin(phi) + h) + sin(phi)*(0.5*L_12 + r*cos(phi)))];
F_123 = linsolve(M_1,M_2)
F_1 = F_123(1)
F_2 = F_123(2)
F_3 = F_123(3)

% Friction force
F_3_friction = F_3 * mu
plot(rad2deg(theta),F_3_friction,'o')
xlim([0 90])
ylim([0.4 0.6])
xlabel('theta (degrees)')
ylabel('Friction force in pin 3 (Newton)')
hold on
