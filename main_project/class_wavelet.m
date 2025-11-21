%clear; clc;
fs=256;
load('ECG_EEG_DATASET/ECGData.mat');
A=ECGData.Data;
C1=A(1,:);

% Plot the first channel
figure, plot(C1);

%% Centered the signal

C1=C1-mean(C1);
%%
figure, plot(C1);

%% check the noise in the signal
Y=abs(fftshift(fft(C1)));

% Create vector of indexes
vf=linspace(-fs/2, fs/2, length(Y))
% Plot the magnitude of spectrum
figure, plot(vf, Y);

%% Applying filters 
Yfilter = filter(bPass, C1);
figure, plot(Yfilter);

%%
% Y2=abs(fftshift(fft(Yfilter)));
% Yfilter = filter(Hd2, C1);
% figure, plot(vf, Y2);
% 
% %%
% vs=256;
% Y22=abs(fftshift(fft(Y2)));
% %vf=linspace(-fs/2, fs/2, length(Y));
% %%
% vf=linspace(-fs/2, fs/2, length(Y22));
% figure, plot(vf, Y22);
% %% Using wavelet 'sym5'
% [C,L]=wavedec(Y2, 3, 'sym5'); 
% %% Get the details of selected or defined level
% A = appcoef(C,L, 'sym5', 3);
% figure, plot(A);
% %% Details of the original signal
% A=detcoef(C,L, 'sym5');
% D3=detcoef(C,L,'sym5',3);
% figure, plot(D3{3}); % Get the signal from level 3
% figure, plot(D3{3}); % Get the signal from level 3
% %%
% 
% 
