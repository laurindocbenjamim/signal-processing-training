 %% 3. Remoção de Artefatos (Filtragem) - secure solution
function [ECG_cleaned] = remove_artefacts_2(ECG_mV, Fs)
    % --- A. Remoção de Ruído da Linha de Base (Baseline Wander) ---
    Wn_high = 0.5 / (Fs/2); 
    [b_high, a_high] = butter(2, Wn_high, 'high'); 
    ECG_baseline_corr = filtfilt(b_high, a_high, ECG_mV); 
    
    % --- B. Remoção de Ruído de Alta Frequência / Ruído Muscular ---
    Wn_low = 40 / (Fs/2); 
    [b_low, a_low] = butter(2, Wn_low, 'low'); 
    ECG_filtered = filtfilt(b_low, a_low, ECG_baseline_corr);
    
    % --- C. Remoção de Ruído da Rede Elétrica (50 Hz) ---
    % Alternativa segura: Usando Filtro Butterworth Rejeita-Banda ('stop')
    % Esta função é básica e não deve dar erro.
    F_power = 50; % Frequência da rede elétrica
    W_stop = [F_power - 1, F_power + 1] / (Fs/2); % Banda de rejeição: 49 a 51 Hz (normalizada)
    
    % Cria um filtro Butterworth de 4ª ordem (ajustável)
    [b_notch, a_notch] = butter(4, W_stop, 'stop'); 
    
    % Aplica o filtro de forma zero-fase
    ECG_cleaned = filtfilt(b_notch, a_notch, ECG_filtered);
end