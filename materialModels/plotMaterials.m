function plotMaterials()
%{
    Plots the different material models to check validity!. 
%}
    T = linspace(0,600,100);
    alphaS = zeros(length(T),1);
    alphaSL = zeros(length(T),1);
    alphaC = zeros(length(T),1);
    alphaCL = zeros(length(T),1);  
    alphaZ = zeros(length(T),1);
    
    for i = 1:length(T)
        alphaS(i) = alphaSilicon(T(i));
        alphaSL(i) = alphaSilicon_Linear(T(i));
        alphaC(i) = alphaCopper(T(i));
        alphaCL(i) = alphaCopper_Linear(T(i));
        alphaZ(i) = alphaZero(T(i));
    end

    figure('Name','alpha Silicon')
    hold on
    plot(T,alphaS,'k-');
    plot(T,alphaSL,'k--');
    plot(T,alphaC,'-','Color',[0.9290, 0.6940, 0.1250]);
    plot(T,alphaCL,'--','Color',[0.9290, 0.6940, 0.1250]);
    plot(T,alphaZ,'Color',[0.4940, 0.1840, 0.5560]);    
    title('Thermal expansion coefficient models')
    xlabel('Temperature [K]')
    ylabel('$$\alpha_L$$')
    legend('Silicon','Silicon Linear','Copper','Copper Linear','Zero')
end