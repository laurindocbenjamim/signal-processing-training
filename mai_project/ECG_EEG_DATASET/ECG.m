clear;
close all;
clc;
%% Loading 1 ECG recording(1 channels)
clear
load('ECGDAta.mat');
fsECG=256;
dataECG = ECGData.Data(1,:);

figure
t=0:1/fsECG: (length(dataECG)-1)/fsECG;
plot(t,dataECG)



%% Signal Normalization

FNyquist = fsECG/2; % Frequência de Nyquist
WinTime = 1; % time in seconds for each window
windowSize = fsECG * WinTime;


a=1;
for k = 1:windowSize:length(dataECG(1,:))-windowSize-1
    d = (dataECG(1,k:k+windowSize-1)./(sum(dataECG(1,k:k+windowSize-1))^2)); % normallize the signal
    ECGSignalNormalized{a,1} = d - mean(d); % subtract by it's average
    a=a+1;
end

%% Signal Filtering

for k = 1:length(ECGSignalNormalized(:,1))
    [y, b]=bandpass(ECGSignalNormalized{k,1},[1 60],fsECG); % band pass between 1 to 40;
    ECGFilteredNormalized{k,1} = filter(b,ECGSignalNormalized{k,1});
    %ECGFilteredNormalized{k,1} = filtfilt(b,ECGSignalNormalized{k,1});

end

%plot(ECGFilteredNormalized{1,1})
%% Cross Power Spectral Density 
for k = 1:length(ECGSignalNormalized(:,1))
    % --- Computing signal spectrum via FFT with equal to signal length
    Lsig = length(ECGFilteredNormalized{1,1});
    Nfft = Lsig;
    freq = fsECG*(0:Nfft-1)'/Nfft;

    % --- Computing Power Spectral Density (PSD) of the entire signal
    Cpsd = cpsd(ECGFilteredNormalized{k,1},ECGFilteredNormalized{k,1},hamming(Lsig),[],Nfft,fsECG);
    Cpsd =Cpsd/sum(Cpsd); % Power Spectral Normalization

    %Cpsd = pwelch(ECGFilteredNormalized{k,1},[],[],Nfft,fsECG);
    if k ==1
        figure
        plot(freq(1:Nfft/2+1),Cpsd)
        xlabel('Frequency (Hz)')
        ylabel('Power/Frequency (dB/Hz)')
        title('Power Density Spectrum of Channel 1')
        grid on;
    end

    % --- Computing Subband Powers
    energy(k,1) = sum(abs(Cpsd).^2); % Energy
end

%% Data Compressor: Average
features = mean(energy);
