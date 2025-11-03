%Signal Processing class

%% Blocked signal

clear;
close all;
clc;

%% Loading 1 EEG recording (16 channels)

fsEEG = 128; %Sample Frequency
data = dlmread('S10W1.eea');
signal = reshape(data,7680,16);

figure
t=0:1/fsEEG: (length(signal(:,1))-1)/fsEEG;
plot(t,signal(:,1))

%% Signal Normalization

FNyquist = fsEEG/2; % Frequência de Nyquist
WinTime = 1; % time in seconds for each window
windowSize = fsEEG * WinTime;

for leads = 1:16
    a=1;
    for k = 1:windowSize:length(signal(:,1))
        d = (signal(k:k+windowSize-1,leads)./(sum(signal(k:k+windowSize-1,leads))^2)); % normallize the signal
        EEGSignalNormalized{a,leads} = d - mean(d); % subtract by it's average
        a=a+1;
    end 
end

%% Signal Filtering
for leads = 1:16
    for k = 1:length(EEGSignalNormalized(:,1))
        [y, b]=bandpass(EEGSignalNormalized{k,leads},[1 40],fsEEG); % band pass between 1 to 40;
        EEGFilteredNormalized{k,leads} = filter(b,EEGSignalNormalized{k,leads});
        %EEGFilteredNormalized{k,leads} = filtfilt(b,EEGSignalNormalized{k,leads});

    end
end

%plot(EEGFilteredNormalized{1,1})
%% Wavelet

wname = 'bior3.5'; % Wavelet name
Nlevel = 4; % Number of decomposition levels

for leads = 1:16
    for k = 1:length(EEGSignalNormalized(:,1))
        
        % --- Applying DWT to signal 1
        
        [coefs,L] = wavedec(signal(:,1),Nlevel,wname); % Computing DWT and getting all tis coeficients
        

        % --- Delta subband: 1Hz - 4Hz
        signal_delta = wrcoef('a',coefs,L,wname,4);

        % --- Theta subband: 4Hz - 8Hz
        signal_theta = wrcoef('d',coefs,L,wname,4);

        % --- Alpha subband: 8Hz - 13Hz
        signal_alpha = wrcoef('d',coefs,L,wname,3);

        % --- Beta subband: 13Hz - 30Hz
        signal_beta = wrcoef('d',coefs,L,wname,2);

        % --- Gamma subband: 30Hz - 40Hz
        signal_gamma = wrcoef('d',coefs,L,wname,1);

        % --- subplot signal bands
        if k==1 && leads==1
        figure
        subplot(1,5,1)
        plot(signal_delta)
        title('Delta')
        subplot(1,5,2)
        plot(signal_theta)
        title('Theta')
        subplot(1,5,3)
        plot(signal_alpha)
        title('Alpha')
        subplot(1,5,4)
        plot(signal_beta)
        title('Beta')
        subplot(1,5,5)
        plot(signal_gamma)
        title('Gamma')
        end

        % --- Computing Subband Powers
        featurea{1,leads}(k,1) = sum(signal_delta); % Total power
        featurea{2,leads}(k,1) = sum(signal_theta);
        featurea{3,leads}(k,1) = sum(signal_alpha);
        featurea{4,leads}(k,1) = sum(signal_beta);
        featurea{5,leads}(k,1) = sum(signal_gamma);
    end
end
%% Data Compressor: Average
featureLocation = 1;
for leads = 1:16
    for band = 1:5
        features(1,featureLocation) = mean(featurea{band,leads});
        featureLocation = featureLocation+1;
    end
end
