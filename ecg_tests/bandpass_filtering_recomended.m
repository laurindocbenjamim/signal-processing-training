%%
function [ECG_filtered_final] = bandpass_filtering_recomended(ECG_mV, Fs, Ordem)
    % Parâmetros
    % Fs = 1000; % Frequência de Amostragem
    % Ordem = 2; % Ordem do filtro (ajustável)
    
    % Frequências de corte para o passa-banda: 
    % 0.5 Hz (mínimo, para remover baseline wander)
    % 40 Hz (máximo, para remover ruído muscular/EMG)
    Fc_bandpass = [0.5, 40]; 
    
    % Frequências de corte normalizadas [Wn_min, Wn_max]
    Wn_bandpass = Fc_bandpass / (Fs/2); 
    
    % 1. Criação do Filtro Bandpass (Passa-Banda)
    % O comando 'butter' assume 'bandpass' se receber um vetor de 2 elementos.
    [b_band, a_band] = butter(Ordem, Wn_bandpass); 
    
    % 2. Aplicação do Filtro Bandpass (Zero-Fase)
    ECG_filtered_bandpass = filtfilt(b_band, a_band, ECG_mV); 
    
    % 3. Adicionar o Filtro Notch (para 50 Hz, se necessário)
    % Você deve aplicar o Notch (rejeita-banda) DEPOIS do Bandpass.
    F_power = 50; 
    W_stop = [F_power - 1, F_power + 1] / (Fs/2); 
    [b_notch, a_notch] = butter(4, W_stop, 'stop'); 
    ECG_filtered_final = filtfilt(b_notch, a_notch, ECG_filtered_bandpass);
end

% O MATLAB permite que você defina o filtro como 
% Bandpass de uma vez só, passando um vetor de 
% frequências de corte ([F_inferior, F_superior]). 
% Esta é a forma mais elegante e eficiente.