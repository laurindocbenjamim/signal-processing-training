clear;
close all;
clc;
%% Loading 1 ECG recording(1 channels)
clear
cd("C:\Users\berna\Desktop\Scrips\PSI\Project\signal-processing-training\main_project\main_db\ecg_db_patient_01\")

[signal, Fs, tm] =rdsamp('s0010_re.dat',[],[],0);

leads= size(signal,2);

for i=1:leads
        
    figure, plot(tm,signal(:,i))
    

end



%% Signal Normalization

FNyquist = Fs/2; % Frequência de Nyquist
WinTime = 1; % time in seconds for each window
windowSize = Fs * WinTime;


a=1;
for k = 1:windowSize:length(signal(:,1))-windowSize-1
    d = (signal(k:k+windowSize-1,1)./(sum(signal(k:k+windowSize-1,1))^2)); % normallize the signal
    ECGSignalNormalized{a,1} = d - mean(d); % subtract by it's average
    a=a+1;
end

%% Signal Filtering

for k = 1:length(ECGSignalNormalized(:,1))
    [y, b]=bandpass(ECGSignalNormalized{k,1},[1 60],Fs); % band pass between 1 to 40;
    ECGFilteredNormalized{k,1} = filter(b,ECGSignalNormalized{k,1});
    %ECGFilteredNormalized{k,1} = filtfilt(b,ECGSignalNormalized{k,1});

end



