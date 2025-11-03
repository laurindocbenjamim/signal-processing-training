function helperFrequencyDomain(signal, Fs, plot_title, color)
    % helperFrequencyDomain - Plota espectro de frequência do sinal
    %
    % Sintaxe:
    %   helperFrequencyDomain(signal, Fs, plot_title, color)
    %
    % Parâmetros:
    %   signal - Sinal a ser analisado (pode ser multicanai)
    %   Fs - Frequência de amostragem
    %   plot_title - Título do gráfico (opcional)
    %   color - Cor do plot (opcional)

    if nargin < 4
        color = 'b';
    end
    if nargin < 3
        plot_title = 'Frequency Spectrum';
    end
    
    [num_channels, num_samples] = size(signal);
    
    % Se for sinal multicanal, plotar cada canal em subplot
    if num_channels > 1
        for i = 1:num_channels
            subplot(num_channels, 1, i);
            plot_single_channel_spectrum(signal(i, :), Fs, color);
            title(sprintf('%s - Channel %d', plot_title, i));
            grid on;
        end
    else
        % Sinal de canal único
        plot_single_channel_spectrum(signal, Fs, color);
        title(plot_title);
        grid on;
    end
end

function plot_single_channel_spectrum(channel_data, Fs, color)
    % Função auxiliar para plotar espectro de um canal
    N = length(channel_data);
    
    % Calcular FFT
    Y = fft(channel_data);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    % Vetor de frequências
    f = Fs*(0:floor(N/2))/N;
    
    % Plotar
    plot(f, P1, color, 'LineWidth', 1.5);
    xlabel('Frequency (Hz)');
    ylabel('|Amplitude|');
    xlim([0 Fs/2]); % Mostrar apenas até Nyquist
end