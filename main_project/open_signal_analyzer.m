function [reduced_signal, time_vector] = open_signal_analyzer(dataset_signal, total_channels, max_samples, Fs)
% OPEN_SIGNAL_ANALYZER - Abre sinal no Signal Analyzer e faz análise espectral robusta
%
% Uso:
%   [reduced_signal, time_vector] = open_signal_analyzer(dataset_signal);
%   [reduced_signal, time_vector] = open_signal_analyzer(dataset_signal, total_channels);
%   [reduced_signal, time_vector] = open_signal_analyzer(dataset_signal, total_channels, max_samples);
%   [reduced_signal, time_vector] = open_signal_analyzer(dataset_signal, total_channels, max_samples, Fs);
%
% Entradas:
%   dataset_signal   - Matriz [canais x amostras] ou [amostras x canais] (será transposta se necessário)
%   total_channels   - Número máximo de canais a analisar (padrão: 5)
%   max_samples      - Número máximo de amostras por canal (padrão: 10000)
%   Fs               - Frequência de amostragem em Hz (padrão: 250)
%
% Saídas:
%   reduced_signal   - Sinal reduzido [canais x amostras]
%   time_vector      - Vetor de tempo em segundos
%
% Exemplo:
%   load('ecg_data.mat');
%   [sig, t] = open_signal_analyzer(ecg_signal, 3, 5000, 360);
%
% Autor: Adaptado para robustez contra erro de pwelch
% Data: 03/11/2025

    % === Parâmetros padrão ===
    if nargin < 4, Fs = 250; end
    if nargin < 3, max_samples = 10000; end
    if nargin < 2, total_channels = 5; end
    if nargin < 1, error('dataset_signal é obrigatório.'); end

    % === Verificar orientação do sinal ===
    [num_rows, num_cols] = size(dataset_signal);
    if num_rows > num_cols
        % Assume [amostras x canais] → transpor para [canais x amostras]
        dataset_signal = dataset_signal';
        [num_rows, num_cols] = size(dataset_signal);
        fprintf('Sinal transposto: agora [%d canais x %d amostras]\n', num_rows, num_cols);
    end
    [num_channels, num_samples] = deal(num_rows, num_cols);

    % === Reduzir sinal ===
    channels_to_analyze = min(total_channels, num_channels);
    samples_to_analyze = min(max_samples, num_samples);

    reduced_signal = dataset_signal(1:channels_to_analyze, 1:samples_to_analyze);
    time_vector = (0:samples_to_analyze-1) / Fs;

    % === Informações no console ===
    fprintf('=== Análise de Sinal ===\n');
    fprintf('Sample Rate: %.1f Hz\n', Fs);
    fprintf('Canais analisados: %d de %d\n', channels_to_analyze, num_channels);
    fprintf('Amostras por canal: %d (%.2f segundos)\n', samples_to_analyze, samples_to_analyze/Fs);
    fprintf('========================\n');

    % === Tentar abrir no Signal Analyzer (opcional) ===
    try
        varNames = compose('Ch%d', 1:channels_to_analyze);
        signal_timetable = array2timetable(reduced_signal', ...
            'RowTimes', seconds(time_vector'), ...
            'VariableNames', varNames);
        signalAnalyzer(signal_timetable);
        fprintf('Signal Analyzer aberto com sucesso.\n');
    catch
        warning('Signal Analyzer não disponível. Continuando sem interface gráfica.');
    end

    % === Figura de análise espectral ===
    FIG = figure('Name', 'Análise Espectral - Power Spectrum (dB/Hz)', ...
                 'NumberTitle', 'off', 'Color', 'white');

    for i = 1:channels_to_analyze
        subplot(channels_to_analyze, 1, i);
        canal = reduced_signal(i, :);
        L = length(canal);

        % --- Sinal nulo ou NaN ---
        if all(isnan(canal)) || all(abs(canal) < 1e-12)
            plot(time_vector, canal, 'b');
            title(sprintf('Canal %d - Sinal nulo/NaN', i), 'Color', 'red');
            xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
            continue;
        end

        % --- Sinal muito curto para pwelch (< 16 amostras) ---
        if L < 16
            warning('Canal %d: apenas %d amostras (< 16). Mostrando apenas domínio do tempo.', i, L);
            plot(time_vector, canal, 'b');
            title(sprintf('Canal %d - Tempo (sinal curto)', i));
            xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
            continue;
        end

        % --- Configuração robusta da janela ---
        window_length = min(256, max(16, floor(L / 4)));  % 1/4 do sinal, entre 16 e 256
        window_length = min(window_length, L);           % não exceder L
        window = hamming(window_length);                 % JANELA COMO VETOR
        noverlap = floor(window_length * 0.5);           % 50% de overlap
        nfft = max(window_length, 2^nextpow2(window_length));  % resolução em freq

        % Diagnóstico
        fprintf('Canal %d: L=%d, window=%d, noverlap=%d, nfft=%d\n', ...
                i, L, window_length, noverlap, nfft);

        % --- Cálculo do espectro de potência ---
        try
            [pxx, f] = pwelch(canal, window, noverlap, nfft, Fs);
            plot(f, 10*log10(pxx), 'LineWidth', 1.2);
            title(sprintf('Canal %d - Espectro de Potência', i));
            xlabel('Frequência (Hz)'); ylabel('PSD (dB/Hz)');
            grid on; xlim([0 Fs/2]);
            % Opcional: destacar banda de interesse (ex: ECG 0.5-40 Hz)
            % xline([0.5 40], '--r');
        catch ME
            warning('pwelch falhou no canal %d: %s\nMostrando domínio do tempo.', i, ME.message);
            plot(time_vector, canal, 'b');
            title(sprintf('Canal %d - Tempo (pwelch falhou)', i));
            xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
        end
    end

    % --- Garantir que a figura fique visível ---
    if ishandle(FIG)
        drawnow;
        figure(FIG);  % trazer à frente
    end

end