function plotMaterials()
%{
    Plots the different material models to check validity!. 
%}
    T = linspace(0,600,100);
    alphaS = zeros(length(T),1);
    alphaC = zeros(length(T),1);
    alphaSL = zeros(length(T),1);
    for i = 1:length(T)
        alphaS(i) = alphaSilicon(T(i));
        alphaC(i) = alphaCopper(T(i));
        alphaSL(i) = alphaSilicon_Linear(T(i));
    end

    figure('Name','alpha Silicon')
    hold on
    plot(T,alphaS);
    plot(T,alphaSL);
    plot(T,alphaC);
    title('Thermal expansion coefficient models')
    xlabel('Temperature [K]')
    ylabel('$$\alpha_L$$')
    legend('Silicon','Silicon Linear','Copper')

end