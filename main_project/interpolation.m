% Program demo_2_4.m
% Spectrum of interpolated signal
clear all, close all
% Input signal ‘x’
F = [0,0.2,0.9,1]; A = [0,1,0,0]; % Setting the input parameters for fir2
x = fir2(128,F,A); % Generating the original signal ‘x’
X = fft(x,1024); % Computing the spectrum of the original signal
f = 0:1/1024:(512-1)/1024; % Normalized frequencies
figure (1)
subplot(3,1,1), plot(f,abs(X(1:512)),'LineWidth',3)
title('|X(e^j^\omega)| - Original Signal'), text(0.9,0.5,'(a)'), set(gca,'FontSize',18)
L = 4; % Up-sampling factor
xu = zeros(1,L*length(x));
xu([1:L:length(xu)]) = x; % Up-sampled signal
Xu = fft(xu,1024); % Computing the spectrum of the up-sampled signal
subplot(3,1,2), plot(f,abs(Xu(1:512)),'LineWidth',3)
title('|X_u(e^j^\omega)| - Original Signal up-sampled by a factor of 4'), text(0.9,0.5,'(b)'), set(gca,'FontSize',18)
y = interp(x,L); % Interpolated signal
Y = fft(y,1024); % Computing the spectrum of the up-sampled signal
subplot(3,1,3), plot(f,abs(Y(1:512)),'LineWidth',3)
title('|(Y(e^j^\omega)| - Original Signal interpolated by a factor of 4'), xlabel('\omega/(2\pi)'), text(0.9,2, '(c)'), set(gca,'FontSize',18)

figure,
subplot(3,1,1),plot(x,'LineWidth',3), title('Original Signal'), axis([0 length(x) min(x) max(x)]); set(gca,'FontSize',18)
subplot(3,1,2),plot(xu,'LineWidth',3), title('Original Signal up-sampled by a factor of 4'); axis([0 length(xu) min(xu) max(xu)]);set(gca,'FontSize',18)
subplot(3,1,3),plot(y,'LineWidth',3), title('Original Signal interpolated by a factor of 4'); axis([0 length(y) min(y) max(y)]);set(gca,'FontSize',18)