%{
This script serves as analysis for the wafer positioning system of PMD. 
%}
clear;
close all;
set(0,'defaultTextInterpreter','latex'); %trying to set the default

%% Settings


%% Initialisation
% Creating wafer at T0 = 273.15K
    radius = 30;                             % mm
    material = 'Silicon';
    alpha_L = @alphaSilicon;                    

    % Create rough object 
    angles = linspace(-150, 150, 50);
    Pos = radius*[cosd(angles); sind(angles)];

    wafer = body(Pos, alpha_L, material);     % Actual wafer object

% Creating support
    testPiece = body([],[],[]);



    
%% Analysis
% Move to test
    wafer.move([0,0]',0);
    testPiece.move([0,0]',0);
    
% Plot
    figure('Name','Kinematic Coupling')
    hold on
    axis equal
    waferP = wafer.show(gca, 'k');
    testPieceP = testPiece.show(gca, 'c');
    alpha(0.3);

    
    
    
    
    
% Thermal expansion coefficient of silicon test
Plot = false;
if Plot == true
        T = linspace(0,600,100);
    alphaS = zeros(length(T),1);
    for i = 1:length(T)
        alphaS(i) = alphaSilicon(T(i));
    end

    figure('Name','alpha Silicon')
    hold on
    plot(T,alphaS);
    xlabel('Temperature [K]')
    ylabel('$$\alpha_L$$ Silicon')
end