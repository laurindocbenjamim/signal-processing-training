%% Configuração inicial
clear; close all; clc;

%% Carregar sinais - abordagem mais robusta
try
    % Tente carregar os arquivos e verifique quais variáveis existem
    data_down = load("COVID-19 Database\ECG Signals\Patient_0001_Down.mat");
    data_up = load("COVID-19 Database\ECG Signals\Patient_0001_Up.mat");
    
    whos
    % Mostrar variáveis disponíveis nos arquivos
    disp('Variáveis em Patient_0001_Down.mat:');
    disp(fieldnames(data_down));
    
    disp('Variáveis em Patient_0001_Up.mat:');
    disp(fieldnames(data_up));
    
    % Usar as variáveis disponíveis (adaptar conforme necessário)
    % Supondo que os sinais estão nas variáveis 'ecg' ou 'signal'
    if isfield(data_down, 'ecg')
        Down = data_down.ecg;
    elseif isfield(data_down, 'signal')
        Down = data_down.signal;
    else
        % Pegar a primeira variável numérica
        fields = fieldnames(data_down);
        Down = data_down.(fields{1});
    end
    
    if isfield(data_up, 'ecg')
        Up = data_up.ecg;
    elseif isfield(data_up, 'signal')
        Up = data_up.signal;
    else
        % Pegar a primeira variável numérica
        fields = fieldnames(data_up);
        Up = data_up.(fields{1});
    end
    
catch ME
    fprintf('Erro ao carregar arquivos: %s\n', ME.message);
    % Criar dados de exemplo para demonstração
    fs = 500;
    t = 0:1/fs:10;
    Down = sin(2*pi*0.5*t) + 0.5*randn(size(t));
    Up = cos(2*pi*0.5*t) + 0.3*randn(size(t));
    fprintf('Usando dados de exemplo para demonstração\n');
end

%% Função para detecção de artefatos
function [sinal_limpo, artefato_detectado] = remover_artefatos_ecg(sinal, fs)
    artefato_detectado = false;
    sinal_limpo = sinal;
    
    % 1. Verificação de valores NaN ou Inf
    if any(isnan(sinal)) || any(isinf(sinal))
        artefato_detectado = true;
        return;
    end
    
    % 2. Detecção de saturação
    if length(sinal) > 1
        limiar_saturacao = 5 * std(sinal);
        if any(abs(sinal) > limiar_saturacao)
            artefato_detectado = true;
            return;
        end
    end
    
    % 3. Verificação de variância muito baixa (sinal "plano")
    if length(sinal) > 1 && std(sinal) < 0.001
        artefato_detectado = true;
        return;
    end
end

%% Simulação do processo completo com contabilização de classes
function [registros_validos, classes_validas] = simular_processamento_completo()
    % Dados da Tabela 3 (simulando uma base de dados completa)
    classes_diagnosticas = {
        'Bundle branch block', 'Cardiomyopathy', 'Healthy controls', ...
        'Myocarditis', 'Myocardial hypertrophy', 'Myocardial infarction', ...
        'Valvular heart disease', 'Dysrhythmia'
    };
    
    contagem_original = [9, 15, 75, 3, 4, 362, 4, 11];
    total_original = sum(contagem_original);
    
    % Simular remoção de artefatos (mantendo ~483 de 512)
    taxa_remocao = 1 - 483/512; % ~5.66% de remoção
    
    fprintf('=== SIMULAÇÃO DO PROCESSAMENTO ===\n');
    fprintf('Total inicial: %d registros\n', total_original);
    
    % Aplicar taxa de remoção uniformemente para cada classe
    contagem_final = zeros(size(contagem_original));
    for i = 1:length(contagem_original)
        removidos = round(contagem_original(i) * taxa_remocao);
        contagem_final(i) = contagem_original(i) - removidos;
        fprintf('%s: %d -> %d (removidos: %d)\n', ...
            classes_diagnosticas{i}, contagem_original(i), ...
            contagem_final(i), removidos);
    end
    
    fprintf('Total final: %d registros\n', sum(contagem_final));
    
    % Criar estrutura de saída
    registros_validos = sum(contagem_final);
    classes_validas = containers.Map(classes_diagnosticas, contagem_final);
end

%% Processar os sinais carregados
fs = 500; % Frequência de amostragem assumida

% Criar array de teste com os sinais carregados
sinais_teste = {Down, Up};
nomes_sinais = {'Patient_0001_Down', 'Patient_0001_Up'};

fprintf('\n=== PROCESSAMENTO DOS SINAIS CARREGADOS ===\n');
sinais_validos = {};
nomes_validos = {};

for i = 1:length(sinais_teste)
    sinal_atual = sinais_teste{i};
    
    [sinal_limpo, artefato] = remover_artefatos_ecg(sinal_atual, fs);
    
    if ~artefato
        sinais_validos{end+1} = sinal_limpo;
        nomes_validos{end+1} = nomes_sinais{i};
        fprintf('✓ %s: VÁLIDO\n', nomes_sinais{i});
    else
        fprintf('✗ %s: REMOVIDO (artefatos detectados)\n', nomes_sinais{i});
    end
end

fprintf('\nSinais válidos: %d/%d\n', length(sinais_validos), length(sinais_teste));

%% Executar simulação completa
[total_valido, classes_finais] = simular_processamento_completo();

%% Criar tabela similar à Tabela 3
classes_diagnosticas = {
    'Bundle branch block';
    'Cardiomyopathy'; 
    'Healthy controls';
    'Myocarditis';
    'Myocardial hypertrophy';
    'Myocardial infarction';
    'Valvular heart disease';
    'Dysrhythmia'
};

% Valores da Tabela 3 (após remoção de artefatos)
numero_ecgs = [9; 15; 75; 3; 4; 362; 4; 11];

% Criar tabela
tabela3 = table(classes_diagnosticas, numero_ecgs, ...
    'VariableNames', {'Diagnostic_Class', 'Number_of_ECGs'});

fprintf('\n=== TABELA 3 - DISTRIBUIÇÃO POR CLASSE (APÓS REMOÇÃO) ===\n');
disp(tabela3);

%% Visualização gráfica
figure('Position', [100, 100, 1200, 600]);

% Subplot 1: Distribuição por classe
subplot(1,2,1);
barh(numero_ecgs);
set(gca, 'YTickLabel', classes_diagnosticas);
xlabel('Número de ECGs');
title('Distribuição por Classe Diagnóstica (Tabela 3)');
grid on;

% Subplot 2: Comparação antes/depois (simulada)
subplot(1,2,2);
contagem_original_simulada = round(numero_ecgs / (1 - (512-483)/512));
comparacao = [contagem_original_simulada, numero_ecgs];
bar(comparacao);
set(gca, 'XTickLabel', extractAfter(classes_diagnosticas, ' '));
xlabel('Classes (abreviadas)');
ylabel('Número de ECGs');
legend('Antes da Remoção', 'Após Remoção', 'Location', 'northeast');
title('Comparação Antes/Após Remoção de Artefatos');
grid on;

%% Estatísticas finais
fprintf('\n=== ESTATÍSTICAS GERAIS ===\n');
fprintf('Total de registros na Tabela 3: %d\n', sum(numero_ecgs));
fprintf('Número de classes diagnósticas: %d\n', length(classes_diagnosticas));
fprintf('Classe com mais registros: %s (%d ECGs)\n', ...
    classes_diagnosticas{numero_ecgs == max(numero_ecgs)}, max(numero_ecgs));
fprintf('Classe com menos registros: %s (%d ECGs)\n', ...
    classes_diagnosticas{numero_ecgs == min(numero_ecgs)}, min(numero_ecgs));