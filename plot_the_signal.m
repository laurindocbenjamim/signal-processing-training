function [new_signal] = plot_the_signal(dataset_signal)
    % Função otimizada para plotagem de sinais de grandes volumes de dados
    % Retorna o sinal processado (com ou sem downsampling)
    
    % Configurações para melhor performance com grandes datasets
    set(0, 'DefaultFigureVisible', 'off');
    
    % Verificar se é struct ou matriz direta
    if ~isstruct(dataset_signal)
        ecg_signal = dataset_signal;
    else
        % Busca eficiente pelos campos possíveis
        possible_fields = {'Data', 'signals', 'ECG', 'ecg', 'signal', 'SIGNAL'};
        ecg_signal = [];
        
        for i = 1:length(possible_fields)
            if isfield(dataset_signal, possible_fields{i})
                ecg_signal = dataset_signal.(possible_fields{i});
                break;
            end
        end
        
        % Se não encontrou nos campos comuns, busca no primeiro campo
        if isempty(ecg_signal)
            fields = fieldnames(dataset_signal);
            if ~isempty(fields)
                first_field = fields{1};
                ecg_signal = dataset_signal.(first_field);
                fprintf('Usando campo: %s\n', first_field);
            else
                error('Estrutura vazia ou sem dados válidos');
            end
        end
    end
    
    % Validação do sinal
    if isempty(ecg_signal)
        error('Sinal ECG não encontrado ou vazio');
    end
    
    % Guardar sinal original para retorno
    original_signal = ecg_signal;
    num_points = numel(ecg_signal);
    
    % Otimização para grandes volumes de dados
    max_points_to_plot = 100000; % Limite para evitar sobrecarga gráfica
    
    if num_points > max_points_to_plot
        fprintf('Sinal muito grande (%d pontos). Aplicando downsampling...\n', num_points);
        
        % Fator de downsampling mantendo representatividade
        downsample_factor = ceil(num_points / max_points_to_plot);
        
        % Para downsampling inteligente mantendo características do sinal
        if downsample_factor > 10
            % Para downsample muito agressivo, usar média móvel
            window_size = downsample_factor;
            ecg_downsampled = movmean(ecg_signal, window_size);
            ecg_signal = ecg_downsampled(1:window_size:end);
        else
            % Downsampling simples para fatores menores
            ecg_signal = ecg_signal(1:downsample_factor:end);
        end
        
        fprintf('Plotando %d pontos (fator downsampling: %d)\n', numel(ecg_signal), downsample_factor);
    end
    
    % Criar figura com configurações otimizadas
    fig = figure('Visible', 'on', 'NumberTitle', 'off');
    
    % Plot otimizado para performance
    if numel(ecg_signal) > 10000
        % Para muitos pontos, usar plot simplificado
        plot(ecg_signal, 'r', 'LineWidth', 0.5);
    else
        plot(ecg_signal, 'r', 'LineWidth', 1);
    end
    
    % Configurações do gráfico
    title('ECG Signal - Processado', 'FontSize', 10);
    xlabel('Amostras', 'FontSize', 9);
    ylabel('Amplitude', 'FontSize', 9);
    grid on;
    
    % Limitar número de ticks no eixo X para melhor performance visual
    if numel(ecg_signal) > 5000
        xticks('auto');
    end
    
    % Ajustar limites do eixo Y para melhor visualização
    y_limits = [min(ecg_signal) - 0.1 * range(ecg_signal), ...
                max(ecg_signal) + 0.1 * range(ecg_signal)];
    ylim(y_limits);
    
    % Adicionar informações no gráfico - CORREÇÃO DO INTERPRETADOR
    info_text = sprintf('Pontos: %d', num_points);
    if exist('downsample_factor', 'var')
        info_text = sprintf('%s\nDownsampling: %dx', info_text, downsample_factor);
    end
    
    text(0.02, 0.98, info_text, 'Units', 'normalized', ...
         'VerticalAlignment', 'top', 'FontSize', 8, ...
         'BackgroundColor', 'white', 'EdgeColor', 'black', ...
         'Interpreter', 'none'); % CORREÇÃO AQUI
    
    % Melhorar performance de renderização
    set(fig, 'Renderer', 'painters');
    
    % ATRIBUIÇÃO DA SAÍDA - CORREÇÃO PRINCIPAL
    new_signal = original_signal; % Retorna o sinal original sem downsampling
    
    fprintf('Plot concluído. %d pontos processados.\n', numel(ecg_signal));
end