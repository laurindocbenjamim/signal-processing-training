% % Carregar dados e explorar
% clear all; clear; clc;
% load('resultados_processamento_ecg.mat');
% 
% fprintf('=== VARIÁVEIS DISPONÍVEIS ===\n');
% whos
% 
% % Listar todas as variáveis e seus tipos
% vars = who;
% for i = 1:length(vars)
%     var_name = vars{i};
%     var_value = eval(var_name);
%     fprintf('\n%s: ', var_name);
% 
%     if isnumeric(var_value)
%         if isscalar(var_value)
%             fprintf('escalar = %g', var_value);
%         else
%             fprintf('numérico [%s]', mat2str(size(var_value)));
%         end
%     elseif isstruct(var_value)
%         fprintf('estrutura com campos: %s', strjoin(fieldnames(var_value), ', '));
%     elseif iscell(var_value)
%         fprintf('cell [%s]', mat2str(size(var_value)));
%         % Mostrar conteúdo das células
%         for j = 1:min(3, length(var_value))
%             if isnumeric(var_value{j})
%                 fprintf('\n   célula %d: [%d elementos]', j, length(var_value{j}));
%             end
%         end
%     else
%         fprintf('%s', class(var_value));
%     end
% end
% 
% % Procurar por frequência de amostragem
% fprintf('\n\n=== PROCURANDO FREQUÊNCIA DE AMOSTRAGEM ===\n');
% fs_encontrado = [];
% for i = 1:length(vars)
%     var_name = vars{i};
%     var_value = eval(var_name);
% 
%     if isnumeric(var_value) && isscalar(var_value)
%         % Valores típicos de fs para ECG: 100-1000 Hz
%         if var_value >= 100 && var_value <= 2000
%             fs_encontrado = var_value;
%             fprintf('Possível fs: %s = %d Hz\n', var_name, var_value);
%         end
%     end
% end
% 
% if isempty(fs_encontrado)
%     fprintf('Fs não encontrado nas variáveis. Usando valor padrão: 250 Hz\n');
%     fs = 250;
% else
%     fs = fs_encontrado;
%     fprintf('Usando fs = %d Hz\n', fs);
% end
% 
% %%
% 
% % Continuar com a extração de características
% fprintf('\n=== INICIANDO EXTRAÇÃO DE CARACTERÍSTICAS ===\n');
% 
% % Verificar se sinais_validos existe
% if ~exist('sinais_validos', 'var')
%     fprintf('ERRO: Variável "sinais_validos" não encontrada!\n');
%     return;
% end
% 
% fprintf('Número de sinais válidos: %d\n', length(sinais_validos));
% 
% for sinal_idx = 1:length(sinais_validos)
%     fprintf('\n--- Processando Sinal %d ---\n', sinal_idx);
% 
%     % Obter o sinal atual
%     sinal_atual = sinais_validos{sinal_idx};
% 
%     if isnumeric(sinal_atual) && length(sinal_atual) > 10
%         fprintf('Tamanho do sinal: %d amostras\n', length(sinal_atual));
%         fprintf('Duração aproximada: %.1f segundos\n', length(sinal_atual)/fs);
% 
%         % 1. CARACTERÍSTICAS BÁSICAS DO SINAL
%         ecg_mean = mean(sinal_atual);
%         ecg_std = std(sinal_atual);
%         ecg_median = median(sinal_atual);
%         ecg_rms = rms(sinal_atual);
% 
%         % Verificar se Statistics and Machine Learning Toolbox está disponível
%         try
%             ecg_skew = skewness(sinal_atual);
%             ecg_kurt = kurtosis(sinal_atual);
%         catch
%             ecg_skew = NaN;
%             ecg_kurt = NaN;
%             fprintf('   Toolbox de estatísticas não disponível\n');
%         end
% 
%         % 2. CARACTERÍSTICAS DE AMPLITUDE
%         ecg_max = max(sinal_atual);
%         ecg_min = min(sinal_atual);
%         ecg_pp = ecg_max - ecg_min;
% 
%         % 3. CARACTERÍSTICAS SIMPLES (sem toolboxes necessárias)
%         % Zero-crossing rate simplificado
%         zcr = sum(abs(diff(sinal_atual > mean(sinal_atual)))) / length(sinal_atual);
% 
%         % 4. CARACTERÍSTICAS NO DOMÍNIO DA FREQUÊNCIA (simplificado)
%         L = min(length(sinal_atual), fs*5);
%         if L > fs/2
%             Y = fft(sinal_atual(1:L));
%             P2 = abs(Y/L);
%             P1 = P2(1:floor(L/2)+1);
%             P1(2:end-1) = 2*P1(2:end-1);
% 
%             % Encontrar frequência dominante (ignorar DC)
%             [~, dominant_idx] = max(P1(2:min(50, end))); % Limitar busca
%             dominant_freq = (dominant_idx) * (fs/L);
%         else
%             dominant_freq = NaN;
%         end
% 
%         % --- EXIBIR RESULTADOS ---
%         fprintf('CARACTERÍSTICAS EXTRAÍDAS:\n');
%         fprintf('   Média: %.4f\n', ecg_mean);
%         fprintf('   Desvio Padrão: %.4f\n', ecg_std);
%         fprintf('   Mediana: %.4f\n', ecg_median);
%         fprintf('   RMS: %.4f\n', ecg_rms);
%         fprintf('   Máximo: %.4f\n', ecg_max);
%         fprintf('   Mínimo: %.4f\n', ecg_min);
%         fprintf('   Pico-a-Pico: %.4f\n', ecg_pp);
%         fprintf('   Zero-Crossing Rate: %.4f\n', zcr);
%         fprintf('   Frequência Dominante: %.2f Hz\n', dominant_freq);
% 
%         % Plotar sinal
%         figure;
%         plot(sinal_atual);
%         title(sprintf('Sinal ECG %d - %d amostras', sinal_idx, length(sinal_atual)));
%         xlabel('Amostras');
%         ylabel('Amplitude');
%         grid on;
% 
%     else
%         fprintf('Sinal %d: não numérico ou dados insuficientes\n', sinal_idx);
%     end
% end
% 
% % Verificar estrutura resultados se existir
% if exist('resultados', 'var')
%     fprintf('\n=== EXPLORANDO ESTRUTURA RESULTADOS ===\n');
%     fprintf('Tamanho da estrutura: %d elementos\n', length(resultados));
% 
%     for i = 1:min(3, length(resultados))
%         fprintf('\nResultados(%d):\n', i);
%         campos = fieldnames(resultados(i));
%         for j = 1:length(campos)
%             campo = campos{j};
%             valor = resultados(i).(campo);
%             if isnumeric(valor) && isscalar(valor)
%                 fprintf('   %s: %g\n', campo, valor);
%             elseif isnumeric(valor) && length(valor) <= 10
%                 fprintf('   %s: %s\n', campo, mat2str(valor));
%             elseif isnumeric(valor)
%                 fprintf('   %s: [%d elementos] %s...\n', campo, length(valor), mat2str(valor(1:3)));
%             end
%         end
%     end
% end
% 
% fprintf('\n=== EXTRAÇÃO CONCLUÍDA ===\n');

%%
% 
% % EXTRAÇÃO DE CARACTERÍSTICAS DE ECG - SEM TOOLBOXES
% clear all; close all; clc;
% 
% % Carregar dados
% load('resultados_processamento_ecg.mat');
% 
% fprintf('=== EXTRAÇÃO AVANÇADA DE CARACTERÍSTICAS DE ECG ===\n');
% fprintf('Sinais disponíveis: %d\n', length(resultados));
% fprintf('Fs = %d Hz\n', resultados(1).fs);
% 
% % Inicializar estrutura para armazenar características
% caracteristicas = [];
% 
% for i = 1:length(resultados)
%     fprintf('\n--- Processando Sinal %d ---\n', i);
% 
%     % Obter sinais e parâmetros
%     sinal_filtrado = resultados(i).sinal_filtrado;
%     sinal_original = resultados(i).sinal_original;
%     fs = resultados(i).fs;
%     N = length(sinal_filtrado);
% 
%     % =============================================
%     % 1. CARACTERÍSTICAS NO DOMÍNIO DO TEMPO
%     % =============================================
% 
%     % Estatísticas básicas do sinal filtrado
%     media = mean(sinal_filtrado);
%     std_val = std(sinal_filtrado);
%     mediana = median(sinal_filtrado);
%     max_val = max(sinal_filtrado);
%     min_val = min(sinal_filtrado);
%     pp_val = max_val - min_val; % pico a pico
% 
%     % RMS (sem toolbox)
%     rms_val = sqrt(mean(sinal_filtrado.^2));
% 
%     % MAD (Mean Absolute Deviation - manual)
%     mad_val = mean(abs(sinal_filtrado - media));
% 
%     % Assimetria e Curtose (cálculo manual)
%     n = length(sinal_filtrado);
%     assimetria = (sum((sinal_filtrado - media).^3) / n) / (std_val^3);
%     curtose = (sum((sinal_filtrado - media).^4) / n) / (std_val^4);
% 
%     % Características de variabilidade
%     zcr = sum(abs(diff(sinal_filtrado > media))) / (N-1); % zero-crossing rate
% 
%     % =============================================
%     % 2. DETECÇÃO DE PICOS R E CARACTERÍSTICAS HRV
%     % =============================================
% 
%     % Detecção de picos R simplificada
%     limiar = media + 2 * std_val;
%     min_distancia = round(fs * 0.4); % 400ms entre batimentos
% 
%     % Encontrar picos manualmente
%     picos_r = [];
%     locs_r = [];
% 
%     for j = 2:length(sinal_filtrado)-1
%         if sinal_filtrado(j) > sinal_filtrado(j-1) && ...
%            sinal_filtrado(j) > sinal_filtrado(j+1) && ...
%            sinal_filtrado(j) > limiar
% 
%             % Verificar distância mínima do último pico
%             if isempty(locs_r) || (j - locs_r(end)) >= min_distancia
%                 picos_r = [picos_r, sinal_filtrado(j)];
%                 locs_r = [locs_r, j];
%             end
%         end
%     end
% 
%     num_batimentos = length(picos_r);
% 
%     if num_batimentos >= 2
%         % Intervalos RR em ms
%         rr_intervals = diff(locs_r) / fs * 1000;
% 
%         % Estatísticas HRV no domínio do tempo
%         mean_rr = mean(rr_intervals);
%         std_rr = std(rr_intervals);
% 
%         % RMSSD (manual)
%         diff_rr = diff(rr_intervals);
%         rmssd = sqrt(mean(diff_rr.^2));
% 
%         % pNN50 (manual)
%         nn50 = sum(abs(diff_rr) > 50);
%         pnn50 = (nn50 / length(diff_rr)) * 100;
% 
%         % Triangular index (aproximado)
%         [hist_rr, edges] = histcounts(rr_intervals, 10);
%         tinn = (max(edges) - min(edges)) / max(hist_rr);
%     else
%         mean_rr = NaN; std_rr = NaN; rmssd = NaN; pnn50 = NaN; tinn = NaN;
%     end
% 
%     % =============================================
%     % 3. CARACTERÍSTICAS NO DOMÍNIO DA FREQUÊNCIA
%     % =============================================
% 
%     % FFT para análise espectral
%     L = min(N, 10*fs); % Usar até 10 segundos para estabilidade
%     Y = fft(sinal_filtrado(1:L));
%     P2 = abs(Y/L);
%     P1 = P2(1:floor(L/2)+1);
%     P1(2:end-1) = 2*P1(2:end-1);
%     f = fs*(0:(L/2))/L;
% 
%     % Remover componente DC
%     P1_no_dc = P1(2:end);
%     f_no_dc = f(2:end);
% 
%     % Frequência dominante
%     [max_power, dom_idx] = max(P1_no_dc);
%     freq_dominante = f_no_dc(dom_idx);
% 
%     % Potência em bandas típicas de HRV
%     idx_vlf = (f >= 0.003) & (f <= 0.04);   % Very Low Frequency
%     idx_lf = (f >= 0.04) & (f <= 0.15);     % Low Frequency  
%     idx_hf = (f >= 0.15) & (f <= 0.4);      % High Frequency
% 
%     vlf_power = sum(P1(idx_vlf).^2);
%     lf_power = sum(P1(idx_lf).^2);
%     hf_power = sum(P1(idx_hf).^2);
%     total_power = vlf_power + lf_power + hf_power;
% 
%     % Razões de potência
%     if hf_power > 0
%         lf_hf_ratio = lf_power / hf_power;
%     else
%         lf_hf_ratio = NaN;
%     end
% 
%     if (lf_power + hf_power) > 0
%         lf_nu = (lf_power / (lf_power + hf_power)) * 100;
%         hf_nu = (hf_power / (lf_power + hf_power)) * 100;
%     else
%         lf_nu = NaN; hf_nu = NaN;
%     end
% 
%     % =============================================
%     % 4. CARACTERÍSTICAS MORFOLÓGICAS (QRS)
%     % =============================================
% 
%     if num_batimentos >= 1
%         % Características dos complexos QRS
%         amp_media_qrs = mean(picos_r);
%         amp_std_qrs = std(picos_r);
%         if amp_media_qrs > 0
%             variabilidade_amp = (amp_std_qrs / amp_media_qrs) * 100;
%         else
%             variabilidade_amp = NaN;
%         end
%     else
%         amp_media_qrs = NaN; amp_std_qrs = NaN; variabilidade_amp = NaN;
%     end
% 
%     % =============================================
%     % 5. CARACTERÍSTICAS DE COMPLEXIDADE
%     % =============================================
% 
%     % Entropia aproximada (simplificada)
%     diff_sinal = diff(sinal_filtrado);
%     if std_val > 0
%         sampen_val = -log(std(diff_sinal) / std_val);
%     else
%         sampen_val = NaN;
%     end
% 
%     % =============================================
%     % ARMAZENAR CARACTERÍSTICAS
%     % =============================================
% 
%     caracteristicas(i).sinal_id = i;
%     caracteristicas(i).fs = fs;
%     caracteristicas(i).num_amostras = N;
% 
%     % Domínio do tempo
%     caracteristicas(i).media = media;
%     caracteristicas(i).desvio_padrao = std_val;
%     caracteristicas(i).mediana = mediana;
%     caracteristicas(i).rms = rms_val;
%     caracteristicas(i).maximo = max_val;
%     caracteristicas(i).minimo = min_val;
%     caracteristicas(i).pico_a_pico = pp_val;
%     caracteristicas(i).assimetria = assimetria;
%     caracteristicas(i).curtose = curtose;
%     caracteristicas(i).mad = mad_val;
%     caracteristicas(i).zcr = zcr;
% 
%     % HRV
%     caracteristicas(i).num_batimentos = num_batimentos;
%     caracteristicas(i).mean_rr = mean_rr;
%     caracteristicas(i).std_rr = std_rr;
%     caracteristicas(i).rmssd = rmssd;
%     caracteristicas(i).pnn50 = pnn50;
%     caracteristicas(i).tinn = tinn;
% 
%     % Domínio da frequência
%     caracteristicas(i).freq_dominante = freq_dominante;
%     caracteristicas(i).total_power = total_power;
%     caracteristicas(i).vlf_power = vlf_power;
%     caracteristicas(i).lf_power = lf_power;
%     caracteristicas(i).hf_power = hf_power;
%     caracteristicas(i).lf_hf_ratio = lf_hf_ratio;
%     caracteristicas(i).lf_nu = lf_nu;
%     caracteristicas(i).hf_nu = hf_nu;
% 
%     % Morfológicas
%     caracteristicas(i).amp_media_qrs = amp_media_qrs;
%     caracteristicas(i).amp_std_qrs = amp_std_qrs;
%     caracteristicas(i).variabilidade_amp = variabilidade_amp;
% 
%     % Complexidade
%     caracteristicas(i).sampen = sampen_val;
% 
%     % =============================================
%     % EXIBIR RESULTADOS
%     % =============================================
% 
%     fprintf('   Estatísticas: M=%.4f, STD=%.4f, RMS=%.4f\n', media, std_val, rms_val);
%     fprintf('   Batimentos detectados: %d\n', num_batimentos);
%     if num_batimentos >= 2
%         fprintf('   HRV: RR=%.1f±%.1fms, RMSSD=%.1fms, pNN50=%.1f%%\n', ...
%                 mean_rr, std_rr, rmssd, pnn50);
%     end
%     fprintf('   Espectral: Dominante=%.2fHz, LF/HF=%.2f\n', freq_dominante, lf_hf_ratio);
% 
%     % =============================================
%     % PLOTAR RESULTADOS (SIMPLIFICADO)
%     % =============================================
% 
%     figure('Position', [100, 100, 1000, 600]);
% 
%     % Subplot 1: Sinal filtrado com picos R
%     subplot(2,2,1);
%     t = (0:N-1)/fs;
%     plot(t, sinal_filtrado, 'r', 'LineWidth', 1.5); hold on;
%     if num_batimentos >= 1
%         plot(locs_r/fs, picos_r, 'go', 'MarkerSize', 6, 'LineWidth', 2);
%         legend('Sinal Filtrado', 'Picos R', 'Location', 'best');
%     else
%         legend('Sinal Filtrado', 'Location', 'best');
%     end
%     title(sprintf('Sinal ECG %d - Picos R Detectados', i));
%     xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
% 
%     % Subplot 2: Espectro de frequência
%     subplot(2,2,2);
%     plot(f, P1, 'LineWidth', 1.5);
%     hold on;
%     plot(freq_dominante, max_power, 'ro', 'MarkerSize', 8, 'LineWidth', 2);
%     xlim([0 40]);
%     title('Espectro de Frequência');
%     xlabel('Frequência (Hz)'); ylabel('|P1(f)|'); grid on;
%     legend('Espectro', 'Freq. Dominante', 'Location', 'best');
% 
%     % Subplot 3: Histograma de intervalos RR (se disponível)
%     subplot(2,2,3);
%     if num_batimentos >= 2
%         histogram(rr_intervals, 10, 'FaceColor', 'green', 'FaceAlpha', 0.7);
%         title(sprintf('Histograma RR (Mean=%.1fms)', mean_rr));
%         xlabel('Intervalo RR (ms)'); ylabel('Frequência');
%         grid on;
%     else
%         text(0.5, 0.5, 'Batimentos\ninsuficientes\npara HRV', ...
%              'HorizontalAlignment', 'center', 'Units', 'normalized', 'FontSize', 12);
%         title('Histograma RR');
%     end
% 
%     % Subplot 4: Resumo numérico
%     subplot(2,2,4);
%     if num_batimentos >= 2
%         texto_resumo = sprintf(['RESUMO SINAL %d:\n' ...
%                                'Batimentos: %d\n' ...
%                                'Mean RR: %.1f ms\n' ...
%                                'STD RR: %.1f ms\n' ...
%                                'RMSSD: %.1f ms\n' ...
%                                'pNN50: %.1f%%\n' ...
%                                'LF/HF: %.2f'], ...
%                               i, num_batimentos, mean_rr, std_rr, rmssd, pnn50, lf_hf_ratio);
%     else
%         texto_resumo = sprintf(['RESUMO SINAL %d:\n' ...
%                                'Batimentos: %d\n' ...
%                                'Média: %.4f\n' ...
%                                'STD: %.4f\n' ...
%                                'RMS: %.4f\n' ...
%                                'Freq Dom: %.2f Hz'], ...
%                               i, num_batimentos, media, std_val, rms_val, freq_dominante);
%     end
%     text(0.1, 0.7, texto_resumo, 'Units', 'normalized', 'FontSize', 10);
%     axis off;
% 
%     sgtitle(sprintf('Análise do Sinal ECG %d', i));
% end
% 
% % =============================================
% % TABELA RESUMO DE TODAS AS CARACTERÍSTICAS
% % =============================================
% 
% fprintf('\n\n=== TABELA RESUMO - TODOS OS SINAIS ===\n');
% fprintf('Sinal\tBatimentos\tMean RR\t\tSTD RR\t\tRMSSD\t\tpNN50\t\tLF/HF\t\tFreq Dom\n');
% fprintf('-----\t----------\t-------\t\t------\t\t-----\t\t-----\t\t-----\t\t--------\n');
% 
% for i = 1:length(caracteristicas)
%     fprintf('%d\t%d\t\t%.1f\t\t%.1f\t\t%.1f\t\t%.1f\t\t%.2f\t\t%.2f\n', ...
%             i, caracteristicas(i).num_batimentos, ...
%             caracteristicas(i).mean_rr, caracteristicas(i).std_rr, ...
%             caracteristicas(i).rmssd, caracteristicas(i).pnn50, ...
%             caracteristicas(i).lf_hf_ratio, caracteristicas(i).freq_dominante);
% end
% 
% % Salvar características em arquivo
% save('caracteristicas_ecg_extraidas.mat', 'caracteristicas');
% 
% % Mostrar todas as características extraídas
% fprintf('\n=== CARACTERÍSTICAS EXTRAÍDAS POR SINAL ===\n');
% campos = fieldnames(caracteristicas);
% for i = 1:length(caracteristicas)
%     fprintf('\nSinal %d:\n', i);
%     for j = 1:length(campos)
%         if isnumeric(caracteristicas(i).(campos{j}))
%             fprintf('  %s: ', campos{j});
%             if caracteristicas(i).(campos{j}) < 1000
%                 fprintf('%.4f', caracteristicas(i).(campos{j}));
%             else
%                 fprintf('%.0f', caracteristicas(i).(campos{j}));
%             end
%             fprintf('\n');
%         end
%     end
% end
% 
% fprintf('\n=== EXTRAÇÃO CONCLUÍDA ===\n');
% fprintf('Características salvas em: caracteristicas_ecg_extraidas.mat\n');
% fprintf('Total de características extraídas por sinal: %d\n', length(fieldnames(caracteristicas)));
%%

% EXTRAÇÃO DE CARACTERÍSTICAS DE ECG COM ANÁLISE FRACTAL CORRIGIDA
clear all; close all; clc;

% Carregar dados
load('filtered_datasets/resultados_processamento_ecg.mat');

fprintf('=== EXTRAÇÃO COM CARACTERÍSTICAS FRACTAIS ===\n');
fprintf('Sinais disponíveis: %d\n', length(resultados));

% Inicializar estrutura
caracteristicas = [];

for i = 1:length(resultados)
    fprintf('\n--- Processando Sinal %d ---\n', i);
    
    sinal_filtrado = resultados(i).sinal_filtrado;
    fs = resultados(i).fs;
    N = length(sinal_filtrado);
    
    % Normalizar o sinal para melhor estabilidade numérica
    if std(sinal_filtrado) > 0
        sinal_normalizado = (sinal_filtrado - mean(sinal_filtrado)) / std(sinal_filtrado);
    else
        sinal_normalizado = sinal_filtrado - mean(sinal_filtrado);
    end
    
    % =============================================
    % CARACTERÍSTICAS FRACTAIS (CORRIGIDAS)
    % =============================================
    
    % 1. ENERGY (En)
    energy = sum(sinal_filtrado.^2);
    
    % 2. HIGUCHI FRACTAL DIMENSION (H)
    H = higuchi_fractal_dimension_corrigido(sinal_normalizado);
    
    % 3. HURST EXPONENT (EH)
    EH = hurst_exponent_corrigido(sinal_normalizado);
    
    % 4. KATZ FRACTAL DIMENSION (K) - CORRIGIDA
    K = katz_fractal_dimension_simples(sinal_normalizado);
    
    % =============================================
    % CARACTERÍSTICAS EXISTENTES
    % =============================================
    
    media = mean(sinal_filtrado);
    std_val = std(sinal_filtrado);
    rms_val = sqrt(mean(sinal_filtrado.^2));
    
    % Detecção de picos R
    limiar = media + 2 * std_val;
    min_distancia = round(fs * 0.4);
    
    picos_r = []; locs_r = [];
    for j = 2:length(sinal_filtrado)-1
        if sinal_filtrado(j) > sinal_filtrado(j-1) && ...
           sinal_filtrado(j) > sinal_filtrado(j+1) && ...
           sinal_filtrado(j) > limiar
           
            if isempty(locs_r) || (j - locs_r(end)) >= min_distancia
                picos_r = [picos_r, sinal_filtrado(j)];
                locs_r = [locs_r, j];
            end
        end
    end
    
    num_batimentos = length(picos_r);
    
    % =============================================
    % ARMAZENAR CARACTERÍSTICAS
    % =============================================
    
    caracteristicas(i).sinal_id = i;
    caracteristicas(i).fs = fs;
    caracteristicas(i).num_amostras = N;
    
    % Características fractais
    caracteristicas(i).energy = energy;
    caracteristicas(i).higuchi_fd = H;
    caracteristicas(i).hurst_exponent = EH;
    caracteristicas(i).katz_fd = K;
    
    % Características básicas
    caracteristicas(i).media = media;
    caracteristicas(i).desvio_padrao = std_val;
    caracteristicas(i).rms = rms_val;
    caracteristicas(i).num_batimentos = num_batimentos;
    
    % =============================================
    % EXIBIR RESULTADOS
    % =============================================
    
    fprintf('   Energy: %.4f\n', energy);
    fprintf('   Higuchi FD: %.4f\n', H);
    fprintf('   Hurst Exponent: %.4f\n', EH);
    fprintf('   Katz FD: %.4f\n', K);
    fprintf('   Batimentos detectados: %d\n', num_batimentos);
    
    % =============================================
    % PLOTAR ANÁLISE FRACTAL
    % =============================================
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Subplot 1: Sinal com picos
    subplot(2,3,1);
    t = (0:N-1)/fs;
    plot(t, sinal_filtrado, 'b', 'LineWidth', 1);
    if num_batimentos >= 1
        hold on;
        plot(locs_r/fs, picos_r, 'ro', 'MarkerSize', 6, 'LineWidth', 2);
        legend('Sinal', 'Picos R', 'Location', 'best');
    end
    title(sprintf('Sinal ECG %d', i));
    xlabel('Tempo (s)'); ylabel('Amplitude'); grid on;
    
    % Subplot 2: Análise de Hurst
    subplot(2,3,2);
    [H_visual, scales, fluctuations] = hurst_analysis_plot_corrigido(sinal_normalizado);
    title(sprintf('Análise de Hurst (H=%.3f)', H_visual));
    xlabel('Escala (log)'); ylabel('Flutuação (log)'); grid on;
    
    % Subplot 3: Análise de Higuchi
    subplot(2,3,3);
    [H_visual_hig, k_values, L_values] = higuchi_analysis_plot_corrigido(sinal_normalizado);
    title(sprintf('Análise de Higuchi (H=%.3f)', H_visual_hig));
    xlabel('k (log)'); ylabel('L(k) (log)'); grid on;
    
    % Subplot 4: Resumo fractais
    subplot(2,3,4);
    texto_fractal = sprintf(['ANÁLISE FRACTAL:\n' ...
                           'Energy: %.2f\n' ...
                           'Higuchi FD: %.3f\n' ...
                           'Hurst Exponent: %.3f\n' ...
                           'Katz FD: %.3f\n\n' ...
                           'INTERPRETAÇÃO:\n' ...
                           'Hurst > 0.5: persistente\n' ...
                           'Hurst < 0.5: anti-persistente\n' ...
                           'FD ≈ 1: sinal suave\n' ...
                           'FD ≈ 2: sinal rugoso'], ...
                          energy, H, EH, K);
    text(0.05, 0.7, texto_fractal, 'Units', 'normalized', 'FontSize', 10);
    axis off;
    
    % Subplot 5: Energy distribution
    subplot(2,3,5);
    histogram(sinal_filtrado.^2, 50, 'FaceColor', 'red', 'FaceAlpha', 0.7);
    title('Distribuição de Energy');
    xlabel('Energy'); ylabel('Frequência');
    grid on;
    
    % Subplot 6: Comparação de dimensões fractais
    subplot(2,3,6);
    fd_values = [H, K];
    fd_names = {'Higuchi', 'Katz'};
    bar(fd_values, 'FaceColor', 'green', 'FaceAlpha', 0.7);
    set(gca, 'XTickLabel', fd_names);
    title('Dimensões Fractais');
    ylabel('Valor'); grid on;
    ylim([1, 2]);
    
    sgtitle(sprintf('Análise Fractal do Sinal ECG %d', i));
end

% =============================================
% FUNÇÕES FRACTAIS CORRIGIDAS
% =============================================

function H = higuchi_fractal_dimension_corrigido(signal)
    % Higuchi Fractal Dimension Corrigida
    N = length(signal);
    if N < 100
        H = NaN;
        return;
    end
    
    kmax = min(40, floor(N/4));
    L = zeros(1, kmax);
    k_values = 1:kmax;
    
    for k = 1:kmax
        L_k = zeros(1, k);
        count = 0;
        
        for m = 1:k
            indices = m:k:N;
            if length(indices) > 1
                L_temp = sum(abs(diff(signal(indices))));
                L_norm = L_temp * (N - 1) / (length(indices) * k);
                
                if ~isnan(L_norm) && isfinite(L_norm)
                    L_k(m) = L_norm;
                    count = count + 1;
                end
            end
        end
        
        if count > 0
            L(k) = mean(L_k(1:count));
        else
            L(k) = 0;
        end
    end
    
    % Remover zeros e valores inválidos
    valid_idx = L > 0 & isfinite(L);
    
    if sum(valid_idx) >= 3
        p = polyfit(log(k_values(valid_idx)), log(L(valid_idx)), 1);
        H = -p(1);
    else
        H = NaN;
    end
end

function H = hurst_exponent_corrigido(signal)
    % Hurst Exponent Corrigido
    N = length(signal);
    if N < 100
        H = NaN;
        return;
    end
    
    min_scale = 10;
    max_scale = floor(N/5);
    num_scales = 15;
    
    scales = unique(round(logspace(log10(min_scale), log10(max_scale), num_scales)));
    R_S_ratio = zeros(1, length(scales));
    
    for i = 1:length(scales)
        scale = scales(i);
        num_segments = floor(N / scale);
        
        if num_segments < 2
            continue;
        end
        
        rs_values = zeros(1, num_segments);
        
        for seg = 1:num_segments
            start_idx = (seg-1)*scale + 1;
            end_idx = seg*scale;
            segment = signal(start_idx:end_idx);
            
            if length(segment) < 2
                continue;
            end
            
            mean_seg = mean(segment);
            cumulative_deviation = cumsum(segment - mean_seg);
            range_val = max(cumulative_deviation) - min(cumulative_deviation);
            std_val = std(segment);
            
            if std_val > 0
                rs_values(seg) = range_val / std_val;
            end
        end
        
        valid_rs = rs_values(rs_values > 0);
        if ~isempty(valid_rs)
            R_S_ratio(i) = mean(valid_rs);
        end
    end
    
    valid_idx = R_S_ratio > 0 & scales >= min_scale;
    
    if sum(valid_idx) >= 3
        p = polyfit(log(scales(valid_idx)), log(R_S_ratio(valid_idx)), 1);
        H = p(1);
    else
        H = NaN;
    end
end

function K = katz_fractal_dimension_simples(signal)
    % Katz Fractal Dimension - Versão Simplificada e Robusta
    N = length(signal);
    
    if N < 10
        K = NaN;
        return;
    end
    
    try
        % Calcular comprimento total da curva
        distances = sqrt(1 + diff(signal).^2);
        L = sum(distances);
        
        % Calcular distância máxima do primeiro ponto
        d_values = sqrt((1:N).^2 + (signal - signal(1)).^2);
        d = max(d_values);
        
        % Verificações de segurança
        if L <= 0 || d <= 0
            K = NaN;
            return;
        end
        
        if ~isfinite(L) || ~isfinite(d)
            K = NaN;
            return;
        end
        
        % Fórmula de Katz
        ratio = d / L;
        if ratio <= 0
            K = NaN;
            return;
        end
        
        numerator = log10(N);
        denominator = log10(ratio) + log10(N);
        
        if denominator <= 0 || ~isfinite(denominator)
            K = NaN;
            return;
        end
        
        K = numerator / denominator;
        
        % Garantir que está no range teórico
        if K < 1
            K = 1;
        elseif K > 2
            K = 2;
        end
        
    catch
        K = NaN;
    end
end

function [H, scales, fluctuations] = hurst_analysis_plot_corrigido(signal)
    % Plot da análise de Hurst corrigida
    N = length(signal);
    min_scale = 10;
    max_scale = floor(N/5);
    num_scales = 12;
    
    scales = unique(round(logspace(log10(min_scale), log10(max_scale), num_scales)));
    R_S_ratio = zeros(1, length(scales));
    
    for i = 1:length(scales)
        scale = scales(i);
        num_segments = floor(N / scale);
        
        if num_segments < 2
            continue;
        end
        
        rs_values = zeros(1, num_segments);
        
        for seg = 1:num_segments
            start_idx = (seg-1)*scale + 1;
            end_idx = seg*scale;
            segment = signal(start_idx:end_idx);
            
            if length(segment) < 2
                continue;
            end
            
            mean_seg = mean(segment);
            cumulative_deviation = cumsum(segment - mean_seg);
            range_val = max(cumulative_deviation) - min(cumulative_deviation);
            std_val = std(segment);
            
            if std_val > 0
                rs_values(seg) = range_val / std_val;
            end
        end
        
        valid_rs = rs_values(rs_values > 0);
        if ~isempty(valid_rs)
            R_S_ratio(i) = mean(valid_rs);
        end
    end
    
    valid_idx = R_S_ratio > 0 & scales >= min_scale;
    fluctuations = R_S_ratio;
    
    if sum(valid_idx) >= 3
        p = polyfit(log(scales(valid_idx)), log(R_S_ratio(valid_idx)), 1);
        H = p(1);
        
        % Plot
        plot(log(scales(valid_idx)), log(R_S_ratio(valid_idx)), 'bo-', ...
            'MarkerSize', 6, 'LineWidth', 1.5);
        hold on;
        
        x_fit = linspace(min(log(scales(valid_idx))), max(log(scales(valid_idx))), 100);
        y_fit = polyval(p, x_fit);
        plot(x_fit, y_fit, 'r--', 'LineWidth', 2);
        
        legend('Dados', sprintf('Ajuste (H=%.3f)', H), 'Location', 'best');
    else
        H = NaN;
        plot(0, 0);
        text(0.5, 0.5, 'Dados insuficientes', ...
            'HorizontalAlignment', 'center', 'Units', 'normalized');
    end
end

function [H, k_values, L_values] = higuchi_analysis_plot_corrigido(signal)
    % Plot da análise de Higuchi corrigida
    N = length(signal);
    kmax = min(30, floor(N/4));
    
    L = zeros(1, kmax);
    k_values = 1:kmax;
    
    for k = 1:kmax
        L_k = zeros(1, k);
        count = 0;
        
        for m = 1:k
            indices = m:k:N;
            if length(indices) > 1
                L_temp = sum(abs(diff(signal(indices))));
                L_norm = L_temp * (N - 1) / (length(indices) * k);
                
                if ~isnan(L_norm) && isfinite(L_norm)
                    L_k(m) = L_norm;
                    count = count + 1;
                end
            end
        end
        
        if count > 0
            L(k) = mean(L_k(1:count));
        else
            L(k) = 0;
        end
    end
    
    L_values = L;
    valid_idx = L > 0 & isfinite(L);
    
    if sum(valid_idx) >= 3
        p = polyfit(log(k_values(valid_idx)), log(L(valid_idx)), 1);
        H = -p(1);
        
        % Plot
        plot(log(k_values(valid_idx)), log(L(valid_idx)), 'bo-', ...
            'MarkerSize', 6, 'LineWidth', 1.5);
        hold on;
        
        x_fit = linspace(min(log(k_values(valid_idx))), max(log(k_values(valid_idx))), 100);
        y_fit = polyval(p, x_fit);
        plot(x_fit, y_fit, 'r--', 'LineWidth', 2);
        
        legend('Dados', sprintf('Ajuste (H=%.3f)', H), 'Location', 'best');
    else
        H = NaN;
        plot(0, 0);
        text(0.5, 0.5, 'Dados insuficientes', ...
            'HorizontalAlignment', 'center', 'Units', 'normalized');
    end
end

% =============================================
% TABELA RESUMO FRACTAL
% =============================================

fprintf('\n\n=== RESUMO DAS CARACTERÍSTICAS FRACTAIS ===\n');
fprintf('Sinal\tEnergy\t\tHiguchi FD\tHurst Exp\tKatz FD\t\tBatimentos\n');
fprintf('-----\t------\t\t----------\t---------\t-------\t\t----------\n');

for i = 1:length(caracteristicas)
    if isfield(caracteristicas, 'energy') && ~isempty(caracteristicas(i).energy)
        fprintf('%d\t%.2e\t%.3f\t\t%.3f\t\t%.3f\t\t%d\n', ...
                i, caracteristicas(i).energy, ...
                caracteristicas(i).higuchi_fd, ...
                caracteristicas(i).hurst_exponent, ...
                caracteristicas(i).katz_fd, ...
                caracteristicas(i).num_batimentos);
    end
end

% Salvar características
save('caracteristicas_fractais_ecg.mat', 'caracteristicas');

fprintf('\n=== ANÁLISE FRACTAL CONCLUÍDA ===\n');