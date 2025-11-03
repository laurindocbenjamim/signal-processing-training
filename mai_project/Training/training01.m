%x(t) = sin(2πt) + 1/3 sin(6πt) + 1/5 sin(10πt) = soma (sin(2πkt)) k=1,3,5 0≤t≤1
% generate samples of x(t) at time instances 0:0.01:1.

%% Approach 01: Here we will consider a typical C or Fortran approach, that is, we will use two
% for..end loops, one each on t and k. This is the most ineﬃcient approach in
% MATLAB, but possible.

t=0:0.01:1;
N = length(t); xt = zeros(1,N);

for n = 1:N
    temp = 0;
    for k = 1:2:5
        temp = temp + (1/k)*sin(2*pi*k*t(n));
    end
    xt(n) = temp;
end

%% Approach 02: In this approach, we will compute each sinusoidal component in one step as a
% vector, using the time vector t = 0:0.01:1, and then add all components using
% one for..end loop.

t = 0:0.01:1; xt = zeros(1,length(t));
for k = 1:2:5
    xt = xt + (1/k)*sin(2*pi*k*t);
end
%%
t = 0:0.01:2; % sample points from 0 to 2 in steps of 0.01
xt = sin(2*pi*t); % Evaluate sin(2 pi t)
plot(t,xt,'b'); % Create plot with blue line
xlabel('t in sec'); ylabel('x(t)'); % Label axis
title('Plot of sin(2\pi t)'); % Title plot
%% Plot a discrete signal
% Defining the scale of the signal. index Range from 0 to 40
n=0:1:40;
xn=sin(0.1*pi*n); % Evaluate sin(0.1 pi n)
% plot the signal
figure, stem(n, xn, 'filled'); % Stem-plot
xlabel('n'); ylabel('x(n)'); % Label axis
title('Stem Plot of sin(0.1\pi n)'); % Title plot

%% Plot sinusoidal signal at the same set of axes 
plot(t,xt,'b'); hold on; % Create plot with blue line
Hs = stem(n*0.05,xn,'b','filled'); % Stem-plot with handle Hs
set(Hs,'markersize',4); hold off; % Change circle size