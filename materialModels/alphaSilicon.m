function alpha = alphaSilicon(T)
%{
This function evaluates a nonlinear thermal expansion coefficient model for
high purity silicon found at:

https://trc.nist.gov/cryogenics/materials/Silicon/Silicon.htm

Source is in the website^
%}
a = 1.005E-5;
b = -5.99688E-6;
c = 1.25574E-6;
d = -1.12086E-7;
e = 3.63225E-9;
f = 2.67708E-2;
g = -1.22829E-4;
h = 1.62544E-18;
i = 4.72374E2;
j = -3.58796E4;
k = -1.24191E7;
l = 1.25972E9;

x = T;

% much math, such complicated
alpha = (4.8E-5*x^3+(a*x^5+b*x^5.5+c*x^6+d*x^6.5+e*x^7)*((1+erf(x-15))/2))*((1-erf(0.2*(x-52)))/2)...
    +((-47.6+f*(x-76)^2+g*(x-76)^3+h*(x-76)^9)*((1+erf(0.2*(x-52)))/2))*((1-erf(0.1*(x-200)))/2)...
    +((i+j/x+k/x^2+l/x^3)*((1+erf(0.1*(x-200)))/2));

alpha = alpha*(10^-8);
end