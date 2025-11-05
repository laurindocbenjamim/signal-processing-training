%% Configuração inicial
clear; close all; clc;

%% Parâmetros do ECG
fs = 500;  % Frequência de amostragem
fc_low = 40;   % Frequência de corte alta (Hz)
fc_high = 0.5; % Frequência de corte baixa (Hz)
ordem_filtro = 2; % Ordem do filtro Butterworth

%% Carregar resultados anteriores
load('resultados_processamento_ecg.mat');

%% 1. EQUAÇÕES DE FILTRAGEM - Função para filtro passa-banda ECG
function sinal_filtrado = filtrar_ecg_passa_banda(sinal, fs, fc_low, fc_high, ordem)
    % Converter para double
    sinal = double(sinal(:));
    
    % Normalizar frequências
    w_low = fc_low / (fs/2);
    w_high = fc_high / (fs/2);
    
    % Projetar filtro passa-baixa
    [b_low, a_low] = butter(ordem, w_low, 'low');
    
    % Projetar filtro passa-alta  
    [b_high, a_high] = butter(ordem, w_high, 'high');
    
    % Aplicar filtragem zero-phase (filtfilt)
    sinal_filtrado = filtfilt(b_low, a_low, sinal);
    sinal_filtrado = filtfilt(b_high, a_high, sinal_filtrado);
end

%% 2. EQUAÇÃO DE REMOÇÃO DE BASELINE WANDER (VERSÃO CORRIGIDA)
function sinal_sem_baseline = remover_baseline_wander(sinal, fs)
    % Implementação alternativa sem iirnotch
    % Usando filtro passa-alta mais agressivo para remover baseline
    
    fc_high = 0.3; % Frequência mais baixa para melhor remoção de baseline
    w_high = fc_high / (fs/2);
    
    % Filtro Butterworth de 2ª ordem
    [b_high, a_high] = butter(2, w_high, 'high');
    
    % Aplicar filtragem
    sinal_sem_baseline = filtfilt(b_high, a_high, sinal);
end

%% 3. EQUAÇÃO DE DETECÇÃO DE ARTEFATOS POR VARIÂNCIA MÓVEL
function [artefato_detectado, metricas_variancia] = detectar_artefatos_variancia(sinal, fs)
    artefato_detectado = false;
    metricas_variancia = struct();
    
    sinal = double(sinal(:));
    N = length(sinal);
    
    % Tamanho da janela (1 segundo)
    window_size = fs;
    num_windows = floor(N / window_size);
    
    if num_windows < 3
        artefato_detectado = true;
        return;
    end
    
    variancias = zeros(num_windows, 1);
    
    for i = 1:num_windows
        inicio = (i-1) * window_size + 1;
        fim = i * window_size;
        janela = sinal(inicio:fim);
        variancias(i) = var(janela);
    end
    
    % Estatísticas das variâncias
    media_var = mean(variancias);
    std_var = std(variancias);
    
    if media_var > 0
        cv_var = std_var / media_var; % Coeficiente de variação
    else
        cv_var = inf;
    end
    
    metricas_variancia.media_variancia = media_var;
    metricas_variancia.std_variancia = std_var;
    metricas_variancia.coef_variacao = cv_var;
    metricas_variancia.variancias = variancias;
    
    % Critério: se coeficiente de variação > 1, sinal muito variável
    if cv_var > 1.0
        artefato_detectado = true;
    end
    
    % Critério: se alguma janela tem variância muito baixa
    if any(variancias < 0.001)
        artefato_detectado = true;
    end
end

%% 4. EQUAÇÃO DE DETECÇÃO DE SATURAÇÃO
function [artefato_detectado, metricas_saturacao] = detectar_saturacao(sinal)
    artefato_detectado = false;
    metricas_saturacao = struct();
    
    sinal = double(sinal(:));
    
    if length(sinal) < 10
        artefato_detectado = true;
        return;
    end
    
    % Calcular limiares de saturação
    media = mean(sinal);
    desvio = std(sinal);
    
    if desvio == 0
        artefato_detectado = true;
        return;
    end
    
    limiar_superior = media + 4 * desvio;
    limiar_inferior = media - 4 * desvio;
    
    % Detectar amostras saturadas
    amostras_saturadas = sum(sinal > limiar_superior | sinal < limiar_inferior);
    percentual_saturado = (amostras_saturadas / length(sinal)) * 100;
    
    metricas_saturacao.amostras_saturadas = amostras_saturadas;
    metricas_saturacao.percentual_saturado = percentual_saturado;
    metricas_saturacao.limiar_superior = limiar_superior;
    metricas_saturacao.limiar_inferior = limiar_inferior;
    
    % Critério: mais de 2% das amostras saturadas
    if percentual_saturado > 2
        artefato_detectado = true;
    end
end

%% 5. EQUAÇÃO DE DETECÇÃO DE RUÍDO POR ANÁLISE ESPECTRAL
function [artefato_detectado, metricas_espectro] = detectar_ruido_espectral(sinal, fs)
    artefato_detectado = false;
    metricas_espectro = struct();
    
    sinal = double(sinal(:));
    
    if length(sinal) < fs
        artefato_detectado = true;
        return;
    end
    
    % Análise espectral
    N = min(length(sinal), 10*fs); % Usar até 10 segundos
    [Pxx, F] = pwelch(sinal(1:N), [], [], [], fs);
    
    % Bandas de frequência típicas do ECG
    idx_ecg = (F >= 0.5 & F <= 40);   % Banda do ECG
    idx_ruido = (F > 40 & F <= 100);  % Banda de ruído
    
    if sum(idx_ecg) == 0 || sum(idx_ruido) == 0
        artefato_detectado = true;
        return;
    end
    
    potencia_ecg = mean(Pxx(idx_ecg));
    potencia_ruido = mean(Pxx(idx_ruido));
    
    if potencia_ecg == 0
        razao_ruido_ecg = inf;
    else
        razao_ruido_ecg = potencia_ruido / potencia_ecg;
    end
    
    metricas_espectro.potencia_ecg = potencia_ecg;
    metricas_espectro.potencia_ruido = potencia_ruido;
    metricas_espectro.razao_ruido_ecg = razao_ruido_ecg;
    metricas_espectro.frequencias = F;
    metricas_espectro.espectro = Pxx;
    
    % Critério: razão ruído/ECG > 0.1
    if razao_ruido_ecg > 0.1
        artefato_detectado = true;
    end
end

%% 6. EQUAÇÃO DE DETECÇÃO DE PICOS ANÔMALOS (ARTEFATOS DE MOVIMENTO)
function [artefato_detectado, metricas_picos] = detectar_picos_anomalos(sinal, fs)
    artefato_detectado = false;
    metricas_picos = struct();
    
    sinal = double(sinal(:));
    
    if length(sinal) < 2
        artefato_detectado = true;
        return;
    end
    
    % Calcular derivada (variação entre amostras)
    derivada = diff(sinal);
    
    % Estatísticas da derivada
    media_deriv = mean(abs(derivada));
    std_deriv = std(derivada);
    
    if std_deriv == 0
        artefato_detectado = true;
        return;
    end
    
    limiar_deriv = media_deriv + 3 * std_deriv;
    
    % Detectar picos anômalos na derivada
    picos_anomalos = sum(abs(derivada) > limiar_deriv);
    percentual_picos = (picos_anomalos / length(derivada)) * 100;
    
    metricas_picos.media_derivada = media_deriv;
    metricas_picos.std_derivada = std_deriv;
    metricas_picos.limiar_derivada = limiar_deriv;
    metricas_picos.picos_anomalos = picos_anomalos;
    metricas_picos.percentual_picos = percentual_picos;
    
    % Critério: mais de 1% de picos anômalos
    if percentual_picos > 1
        artefato_detectado = true;
    end
end

%% FUNÇÃO PRINCIPAL DE DETECÇÃO DE ARTEFATOS
function [artefato_detectado, motivo, metricas_completas] = detectar_artefatos_completo(sinal, fs, filename)
    artefato_detectado = false;
    motivo = 'Sinal válido';
    metricas_completas = struct();
    
    if isempty(sinal) || length(sinal) < 2*fs
        artefato_detectado = true;
        motivo = 'Sinal muito curto';
        return;
    end
    
    % Aplicar todas as detecções
    [art_var, metricas_var] = detectar_artefatos_variancia(sinal, fs);
    [art_sat, metricas_sat] = detectar_saturacao(sinal);
    [art_esp, metricas_esp] = detectar_ruido_espectral(sinal, fs);
    [art_picos, metricas_picos] = detectar_picos_anomalos(sinal, fs);
    
    % Combinar resultados
    metricas_completas.variancia = metricas_var;
    metricas_completas.saturacao = metricas_sat;
    metricas_completas.espectral = metricas_esp;
    metricas_completas.picos = metricas_picos;
    
    % Verificar cada critério
    motivos = {};
    
    if art_var
        motivos{end+1} = sprintf('Variância anômala (CV=%.2f)', metricas_var.coef_variacao);
        artefato_detectado = true;
    end
    
    if art_sat
        motivos{end+1} = sprintf('Saturação (%.1f%%)', metricas_sat.percentual_saturado);
        artefato_detectado = true;
    end
    
    if art_esp
        motivos{end+1} = sprintf('Ruído espectral (razão=%.3f)', metricas_esp.razao_ruido_ecg);
        artefato_detectado = true;
    end
    
    if art_picos
        motivos{end+1} = sprintf('Picos anômalos (%.1f%%)', metricas_picos.percentual_picos);
        artefato_detectado = true;
    end
    
    if artefato_detectado
        motivo = strjoin(motivos, '; ');
    end
    
    metricas_completas.artefato_detectado = artefato_detectado;
    metricas_completas.motivo = motivo;
end

%% PROCESSAMENTO COM NOVOS CRITÉRIOS (VERSÃO CORRIGIDA)
fprintf('=== PROCESSAMENTO COM FILTRAGEM E DETECÇÃO AVANÇADA ===\n');

resultados_melhorados = [];

for i = 1:length(resultados)
    fprintf('\n[%d/%d] Processando: %s\n', i, length(resultados), resultados(i).filename);
    
    sinal_original = resultados(i).sinal_original;
    filename = resultados(i).filename;
    
    try
        % 1. Aplicar filtragem passa-banda
        sinal_filtrado = filtrar_ecg_passa_banda(sinal_original, fs, fc_low, fc_high, ordem_filtro);
        
        % 2. Remover baseline wander (versão corrigida)
        sinal_sem_baseline = remover_baseline_wander(sinal_filtrado, fs);
        
        % 3. Detectar artefatos com critérios mais rigorosos
        [artefato, motivo, metricas] = detectar_artefatos_completo(sinal_sem_baseline, fs, filename);
        
        % Armazenar resultados
        resultados_melhorados(i).filename = filename;
        resultados_melhorados(i).sinal_original = sinal_original;
        resultados_melhorados(i).sinal_filtrado = sinal_filtrado;
        resultados_melhorados(i).sinal_sem_baseline = sinal_sem_baseline;
        resultados_melhorados(i).artefato_detectado = artefato;
        resultados_melhorados(i).motivo = motivo;
        resultados_melhorados(i).metricas = metricas;
        resultados_melhorados(i).fs = fs;
        
        if artefato
            fprintf('  → ❌ REMOVIDO: %s\n', motivo);
        else
            fprintf('  → ✅ VÁLIDO: %s\n', motivo);
        end
        
    catch ME
        fprintf('  → ⚠️  ERRO no processamento: %s\n', ME.message);
        
        % Armazenar resultado com erro
        resultados_melhorados(i).filename = filename;
        resultados_melhorados(i).sinal_original = sinal_original;
        resultados_melhorados(i).sinal_filtrado = [];
        resultados_melhorados(i).sinal_sem_baseline = [];
        resultados_melhorados(i).artefato_detectado = true;
        resultados_melhorados(i).motivo = sprintf('Erro no processamento: %s', ME.message);
        resultados_melhorados(i).fs = fs;
    end
end

%% RELATÓRIO FINAL MELHORADO
fprintf('\n\n=== RELATÓRIO FINAL MELHORADO ===\n');

if ~isempty(resultados_melhorados)
    sinais_validos_melhorados = sum(~[resultados_melhorados.artefato_detectado]);
    sinais_removidos_melhorados = sum([resultados_melhorados.artefato_detectado]);
    
    fprintf('Total de sinais processados: %d\n', length(resultados_melhorados));
    fprintf('Sinais válidos: %d\n', sinais_validos_melhorados);
    fprintf('Sinais removidos: %d\n', sinais_removidos_melhorados);
    
    if length(resultados_melhorados) > 0
        fprintf('Taxa de remoção: %.1f%%\n', (sinais_removidos_melhorados/length(resultados_melhorados))*100);
    else
        fprintf('Taxa de remoção: 0.0%%\n');
    end
else
    fprintf('Nenhum resultado processado.\n');
end

%% VISUALIZAÇÃO DETALHADA (VERSÃO SEGURA)
fprintf('\n=== VISUALIZAÇÃO DOS RESULTADOS ===\n');

% Encontrar sinais válidos para visualização
idx_validos = find(~[resultados_melhorados.artefato_detectado]);
idx_removidos = find([resultados_melhorados.artefato_detectado]);

if ~isempty(idx_validos) || ~isempty(idx_removidos)
    figure('Position', [50, 50, 1400, 1000]);
    
    % Mostrar até 3 exemplos
    num_exemplos = min(3, length(resultados_melhorados));
    
    for i = 1:num_exemplos
        r = resultados_melhorados(i);
        
        % Subplot para cada sinal
        subplot(3, 4, (i-1)*4 + 1);
        if ~isempty(r.sinal_original)
            plot(r.sinal_original, 'b', 'LineWidth', 1);
            title(sprintf('%s - Original', r.filename));
            xlabel('Amostras'); ylabel('Amplitude'); grid on;
        end
        
        subplot(3, 4, (i-1)*4 + 2);
        if ~isempty(r.sinal_filtrado)
            plot(r.sinal_filtrado, 'r', 'LineWidth', 1);
            title('Filtrado (0.5-40 Hz)');
            xlabel('Amostras'); ylabel('Amplitude'); grid on;
        end
        
        subplot(3, 4, (i-1)*4 + 3);
        if ~isempty(r.sinal_sem_baseline)
            plot(r.sinal_sem_baseline, 'g', 'LineWidth', 1);
            title('Sem Baseline Wander');
            xlabel('Amostras'); ylabel('Amplitude'); grid on;
        end
        
        subplot(3, 4, (i-1)*4 + 4);
        if isfield(r, 'metricas') && isfield(r.metricas, 'espectral') && ~isempty(r.metricas.espectral.frequencias)
            plot(r.metricas.espectral.frequencias, 10*log10(r.metricas.espectral.espectro), 'm', 'LineWidth', 1.5);
            title(sprintf('Espectro - Status: %s', r.motivo));
            xlabel('Frequência (Hz)'); ylabel('Potência (dB)'); grid on;
            xlim([0, 100]);
        end
    end
else
    fprintf('Não há dados suficientes para visualização.\n');
end

%% SALVAR RESULTADOS MELHORADOS
try
    save('resultados_processamento_melhorado.mat', 'resultados_melhorados');
    fprintf('\nResultados salvos em: resultados_processamento_melhorado.mat\n');
catch
    fprintf('\nAviso: Não foi possível salvar os resultados.\n');
end

fprintf('\n=== PROCESSAMENTO CONCLUÍDO ===\n');