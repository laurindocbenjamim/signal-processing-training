function helperTimeDomain(time_vector, signal, plot_title, font_size, line_width)
    % helperTimeDomain - Plota sinal no domínio do tempo
    %
    % Sintaxe:
    %   helperTimeDomain(time_vector, signal, plot_title, font_size, line_width)
    %
    % Parâmetros:
    %   time_vector - Vetor de tempo
    %   signal - Sinal a ser plotado (pode ser multicanai)
    %   plot_title - Título do gráfico
    %   font_size - Tamanho da fonte (opcional)
    %   line_width - Largura da linha (opcional)

    if nargin < 5
        line_width = 1.5;
    end
    if nargin < 4
        font_size = 12;
    end
    if nargin < 3
        plot_title = 'Time Domain Signal';
    end
    
    [num_channels, num_samples] = size(signal);
    
    % Se for sinal multicanal, plotar cada canal em subplot
    if num_channels > 1
        for i = 1:num_channels
            subplot(num_channels, 1, i);
            plot(time_vector, signal(i, :), 'LineWidth', line_width);
            title(sprintf('%s - Channel %d', plot_title, i), 'FontSize', font_size);
            xlabel('Time (s)', 'FontSize', font_size);
            ylabel('Amplitude', 'FontSize', font_size);
            grid on;
        end
    else
        % Sinal de canal único
        plot(time_vector, signal, 'LineWidth', line_width);
        title(plot_title, 'FontSize', font_size);
        xlabel('Time (s)', 'FontSize', font_size);
        ylabel('Amplitude', 'FontSize', font_size);
        grid on;
    end
end