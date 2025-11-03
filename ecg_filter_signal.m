%% Filter signal
% function [ecgSampleFiltered] = ecg_filter_signal(dataset_signal, Fs)
% fprintf('=== Filtering the Signal ===\n');
% notchFilt = designfilt('bandstopiir', 'FilterOrder', 6,'HalfPowerFrequency1', 59, ...
%     'HalfPowerFrequency2', 61, 'SampleRate', Fs);
% ecgSampleFiltered = filtfilt(notchFilt, dataset_signal);

%%
%% Funções locais (DEVEM estar no final do arquivo)
% function [ecgSampleFiltered] = ecg_filter_signal(dataset_signal, Fs)
%     fprintf('=== Filtering the Signal ===\n');
%     fprintf('Tamanho do sinal: %d amostras\n', length(dataset_signal));
%     fprintf('Frequência de amostragem: %d Hz\n', Fs);
% 
%     % Design do filtro
%     notchFilt = designfilt('bandstopiir', 'FilterOrder', 6, ...
%         'HalfPowerFrequency1', 59, 'HalfPowerFrequency2', 61, 'SampleRate', Fs);
% 
%     % Aplicar filtro
%     ecgSampleFiltered = filtfilt(notchFilt, dataset_signal);
%     fprintf('Filtragem concluída!\n');
% 
%     % Criar vetor de tempo
%     t = (0:length(dataset_signal)-1) / Fs;
%     fprintf('Criando gráficos...\n');
% 
%     % Plot dos sinais
%     figure('Name', 'ECG Filtrado', 'NumberTitle', 'off');
% 
%     % Sinal original
%     subplot(2,1,1);
%     plot(t, dataset_signal, 'b-', 'LineWidth', 1);
%     title('Sinal ECG Original');
%     xlabel('Tempo (s)');
%     ylabel('Amplitude');
%     grid on;
% 
%     % Sinal filtrado
%     subplot(2,1,2);
%     plot(t, ecgSampleFiltered, 'r-', 'LineWidth', 1);
%     title('Sinal ECG Filtrado');
%     xlabel('Tempo (s)');
%     ylabel('Amplitude');
%     grid on;
% 
%     % Ajustar layout
%     sgtitle('Comparação: Sinal Original vs Filtrado');
% 
%     fprintf('Gráficos criados. Verifique a janela de figuras.\n');
%     drawnow; % Força a atualização imediata dos gráficos
% end

function [ecgSampleFiltered] = ecg_filter_signal(dataset_signal, Fs)
    fprintf('=== Filtering the Signal ===\n');
    
    % Design do filtro
    notchFilt = designfilt('bandstopiir', 'FilterOrder', 6, ...
        'HalfPowerFrequency1', 59, 'HalfPowerFrequency2', 61, 'SampleRate', Fs);
    
    % Aplicar filtro
    ecgSampleFiltered = filtfilt(notchFilt, dataset_signal);
    
    % Criar vetor de tempo
    t = (0:length(dataset_signal)-1) / Fs;
    
    % Figura de comparação
    figure('Name', 'ECG Signal Comparison', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800]);
    
    % --- SINAL ORIGINAL ---
    % Domínio do tempo - Original
    subplot(2,2,1);
    plot(t, dataset_signal, 'r', 'LineWidth', 1);
    title('Original Signal - Time Domain');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;
    
    % Domínio da frequência - Original
    subplot(2,2,2);
    plot_frequency_domain(dataset_signal, Fs, 'Original Signal - Frequency Spectrum', 'r');
    
    % --- SINAL FILTRADO ---
    % Domínio do tempo - Filtrado
    subplot(2,2,3);
    plot(t, ecgSampleFiltered, 'b', 'LineWidth', 1);
    title('Filtered Signal - Time Domain');
    xlabel('Time (s)');
    ylabel('Amplitude');
    grid on;
    
    % Domínio da frequência - Filtrado
    subplot(2,2,4);
    plot_frequency_domain(ecgSampleFiltered, Fs, 'Filtered Signal - Frequency Spectrum', 'b');
    
    sgtitle('ECG Signal: Original vs Filtered Comparison');
    drawnow;
end

% Função auxiliar para domínio da frequência
function plot_frequency_domain(signal, Fs, plotTitle, color)
    N = length(signal);
    if mod(N, 2) ~= 0
        signal = signal(1:end-1); % Garantir número par de amostras
        N = length(signal);
    end
    
    % Calcula FFT
    Y = fft(signal);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    % Vetor de frequências
    f = Fs * (0:(N/2)) / N;
    
    % Plot
    plot(f, P1, color, 'LineWidth', 1);
    title(plotTitle);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    grid on;
    xlim([0, 100]); % Foca nas frequências relevantes para ECG
end