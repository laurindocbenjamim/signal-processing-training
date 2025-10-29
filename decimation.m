% Program demo_2_3
% Spectrum of decimated signal
clear all, close all
% Input signal 'x'
F =[0,0.1,0.46,1]; A = [0,1,0,0]; % Setting the input parameters for fir2
x1 = fir2(256,F,A); x2 = 0.01*cos(2*pi*0.35*(0:256)); % Generating the signal components
x = x1 + x2; % Original signal
X = fft(x,1024); % Computing the spectrum of the original signal
f = 0:1/512:(512-1)/512; % Normalized frequencies
figure (1)
subplot(3,1,1), plot(f,abs(X(1:512)),'LineWidth',3)
title('|X(e^j^\omega)| - Original Signal'), text(0.9,0.8,'(a)'), set(gca,'FontSize',18)
% Down-sampled signal
M = 2; % Down-sampling factor
y = downsample(x,2); % Down-sampling
Y = fft(y,1024); % Computing the spectrum of the down-sampled signal
subplot(3,1,2), plot(f,abs(Y(1:512)), 'LineWidth',3)
title('|Y(e^j^\omega)|- Original signal down-sampled by a factor of 2'), text(0.9,0.5,'(b)'), set(gca,'FontSize',18)
% Decimated signal
yd = decimate(x,M); % Decimated signal
Yd = fft(yd,1024); % Computing the spectrum of the decimated signal
subplot(3,1,3), plot(f,abs(Yd(1:512)), 'LineWidth',3)
xlabel('\omega/\pi'),title('|Y_d(e^j^\omega)| - Original signal decimated by a factor of 2'), text(0.9,0.5,'(c)'), set(gca,'FontSize',18)


figure,
subplot(3,1,1),plot(x,'LineWidth',3), title('Original Signal'), axis([0 length(x) min(x) max(x)]);set(gca,'FontSize',18)
subplot(3,1,2),plot(y,'LineWidth',3), title('Original Signal down-sampled by a factor of 2'); axis([0 length(y) min(y) max(y)]);set(gca,'FontSize',18)
subplot(3,1,3),plot(yd,'LineWidth',3), title('Original Signal decimated by a factor of 2'); axis([0 length(yd) min(yd) max(yd)]);set(gca,'FontSize',18)