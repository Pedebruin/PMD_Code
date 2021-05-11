function alpha = alphaCopper(T)
%{
This function evaluates a nonlinear thermal expansion coefficient model for
high purity copper found at:

https://trc.nist.gov/cryogenics/materials/OFHC%20Copper/OFHC_Copper_rev1.htm

Source is in the website^

Sadly only for 4-300K so might not be very accurate...
%}
a = -17.9081289;
b = 67.131914;
c = -118.809316;
d = 109.9845997;
e = -53.8696089;
f = 13.30247491;
g = -1.30843441;

% much math, such complicated
alpha = 10^(a + b*log10(T)+c*log10(T)^2 + d*log10(T)^3 + e*log10(T)^4 + f*log10(T)^5 + g*log10(T)^6);
alpha = alpha*10^(-6);
end