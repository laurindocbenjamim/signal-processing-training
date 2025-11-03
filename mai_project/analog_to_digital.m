% Tranforming the Analog signal to Digital
% s(t)=3.cos(50pi*t)+10*(sin(200pi*t)
%50pi*t equivale 2pi*25pit

% t=0:1/500:2;
% y1=cos(2.*pi.*25.*t); %3.cos(50pi*t)
% y2=10.*sin(2.*pi*100.*t);
% y3=cos(2.*pi.*50.*t);
% yfinal=y1+y2+y3;
% 
% Y=fft(yfinal); % Fourier transform
% Ymod=abs(Y); % magnitude of thre Fourier transform, is the modules
% Yshift=fftshift(Ymod);
% 
% figure, plot(Yshift);
% xl=linspace(-500/2, 500/2, length(Yshift));
% figure, plot(xl, Yshift);
%% Decmate
% 
t=0:1/500:2;
y1=cos(2.*pi.*25.*t); %3.cos(50pi*t)
y2=10.*sin(2.*pi*100.*t);
y3=cos(2.*pi.*50.*t);
yfinal=y1+y2+y3;
yfinal=y1+y2-y3;
% 
% %Y=fft(yfinal); % Fourier transform
% Y=decimate(yfinal, 2);
% Ymod=abs(Y); % magnitude of thre Fourier transform, is the modules
% Yshift=fftshift(Ymod);
% 
% figure, plot(Yshift);
% xl=linspace(-500/2, 500/2, length(Yshift));
% figure, plot(xl, Yshift);
%% 
% 
% factor=4; % factor of 4
% Y=interp(yfinal, factor);
% y=y(1:length(y)-(factor-1)); % Avoid this spectrum from the signal
% 
% Y=fft(yfinal); % Fourier transform
% Ymod=abs(Y); % magnitude of thre Fourier transform, is the modules
% Yshift=fftshift(Ymod);
% 
% xl=linspace(-500*factor, 500*factor, length(Yshift));
% figure, plot(xl, Yshift);

n=


