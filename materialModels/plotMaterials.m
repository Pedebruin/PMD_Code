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
    d = 2;
    figure('Name','alpha Silicon')
    hold on
    plot(T,alphaS,'-','Color',[0.6350, 0.0780, 0.1840],'LineWidth',d);
    plot(T,alphaSL,'--','Color',[0.6350, 0.0780, 0.1840],'LineWidth',d);
    plot(T,alphaC,'-','Color',[0.9290, 0.6940, 0.1250],'LineWidth',d);
    plot(T,alphaCL,'--','Color',[0.9290, 0.6940, 0.1250],'LineWidth',d);
    %plot(T,alphaZ,'Color','k');    
    xline(300,':k','LineWidth',d);
    grid on
    title('Thermal expansion coefficient models')
    xlabel('Temperature [K]')
    ylabel('$$\alpha_L$$')
    legend('Nonlinear silicon','Linear silicon','Nonlinear copper','Linear copper','Initial temperature')
    
end