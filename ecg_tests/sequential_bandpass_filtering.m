function [ECG_filtered_bandpass] = sequential_bandpass_filtering(ECG_mV, Fs)
    % Parâmetros
    %Fs = 1000; % Frequência de Amostragem
    
    % 1. Configurar o Highpass (Passa-Altas) - Remove desvio da linha de base (f < 0.5 Hz)
    Fc_high = 0.5; % Frequência de Corte Inferior em Hz
    Wn_high = Fc_high / (Fs/2); 
    [b_high, a_high] = butter(2, Wn_high, 'high'); 
    
    % 2. Aplicar o Highpass
    ECG_passo1 = filtfilt(b_high, a_high, ECG_mV); 
    
    % 3. Configurar o Lowpass (Passa-Baixas) - Remove ruído muscular (f > 40 Hz)
    Fc_low = 40; % Frequência de Corte Superior em Hz
    Wn_low = Fc_low / (Fs/2); 
    [b_low, a_low] = butter(2, Wn_low, 'low'); 
    
    % 4. Aplicar o Lowpass ao resultado do Highpass
    ECG_filtered_bandpass = filtfilt(b_low, a_low, ECG_passo1);
end 
% 
% Vantagem: Fácil de entender e 
% depurar. Se você quiser mudar uma frequência de corte, 
% você a ajusta diretamente em seu filtro correspondente.