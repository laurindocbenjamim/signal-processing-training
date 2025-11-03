%% FEATURE EXTRACTION AND DETETION - PART 1
% Goal: Identify spectral features in signal using wavelet techniques

%% Steps
% Load and visualize the Signal
% Preprocess the signal to remove artifacts
% Perform wavelet based time-frequency analysis to identify features
%% Load the signal
 load("ECG_EEG_DATASET/ECGData.mat");

%% Check witch variables were loaded
clc % clear the command window 
whos % check the variables loaded


%% Explore the structure of the variable
disp('ECGData structure');
disp(ECGData);

%% Show the fields of the structure
fields = fieldnames(ECGData);
disp('Fields in ECGData structure:');
disp(fields);

%% Show the siz e and datype
disp('Show the size and datype')
whos ECGData

%% Visualize the data
% Se for uma struct com dados de ECG, tente:
% Na sua linha 31, substitua por:
%[new_signal] = plot_the_signal(ECGData);

%% Obter dimensões do sinal
[num_canais, num_amostras] = size(ecg_signal);

%% Mostrar resultados
fprintf('Total de canais: %d\n', num_canais);
fprintf('Total de amostras por canal: %d\n', num_amostras);
fprintf('Tamanho total do sinal: %d x %d\n', num_canais, num_amostras);
%% Verifique a estrutura do sinal
disp('Dimensões do sinal:');
disp(size(ecg_signal));

%% Example of Signal
% Exemplo de uso:

% t = 0:1/Fs:20;                      % 20 segundos
% x1 = sin(2*pi*5*t);                 % canal 1: 5 Hz
% x2 = sin(2*pi*15*t) + 0.5*randn(1,length(t));  % canal 2: ruído
% x3 = randn(1,length(t));            % canal 3: ruído puro
% dataset_signal = [x1; x2; x3];      % 3 canais

%% Analise apenas um canal (por exemplo, o primeiro)
%canal_ecg = ecg_signal(1, :);  % Primeira linha
% Reduzir o sinal para visualização
%canal_ecg = ecg_signal(1, 1:1000);  % Primeiro canal, primeiras 1000 amostras

% Use signalAnalyzer com um canal apenas
% Analisar 3 canais com 5000 amostras cada
% Supondo que ecg_signal seja sua variável de sinal

Fs = 250;
sample=5000;
channel=1;

[reduced_signal, time_vector] = open_signal_analyzer(ecg_signal, channel, sample, Fs);

%% Filter signal
ecg_sample_iltered = ecg_filter_signal(reduced_signal, Fs);

%% Visualize the filtered signal
figure;
% Domínio do tempo
subplot(2,2,1); 
helperTimeDomain(time_vector, reduced_signal, 'Original Signal', 12, 1.5);

% Domínio da frequência
subplot(2,2,2);
helperFrequencyDomain(reduced_signal, Fs, 'Frequency Spectrum', 'r');


%% Visualize the signal
% figure;
% plot(t,ECGData, 'r');
% grid on; title('ECG signal');
% xlabel('time (sec)');

% Or we can use 
% signalAnalyzer

%% Visualize the frequency components in the signal

% figure;
%pwelch(sinal_reduzido, [], [], [], Fs); title('Power spectrum of signal');