
%==========================================================================
%   Script MATLAB para Processamento de Sinal ECG em LOTE:
%   Leitura, Remoção de Artefatos e Extração de Características
%==========================================================================

%% 1. Configurações Iniciais e Definição de Variáveis
clc; clear; close all;

% --- DEFINIÇÕES PARA PROCESSAMENTO EM LOTE ---
BASE_DIR = '../main_db/';
%load('../main_db/ecg_db_patient_01/')
% Lista dos diretórios dos pacientes
Patient_Dirs = {'ecg_db_patient_01', 'ecg_db_patient_01-1', 'ecg_db_patient_02', 'ecg_db_patient_03', 'ecg_db_patient_04', 'ecg_db_patient_04-1'}; 

% Lista dos nomes base dos sinais (sem extensão)
%Signal_Names = {'s0010_re', 's0014lre', 's0016lre', 's0015lre', 's0017lre', 's0020are', 's0020bre'}; % Exemplo dos três sinais

% Inicializa a tabela mestre de resultados (FORA DO LOOP!)
Feature_Master_Table = table(); 

% Diretório para salvar as features
OUTPUT_DIR = 'Extracted_Features_Batch';
if ~exist(OUTPUT_DIR, 'dir')
    mkdir(OUTPUT_DIR);
end

%%
% Parâmetros do Sinal (Assumindo que são FIXOS para todos os arquivos)
Fs = 1000; % Frequência de amostragem em Hz
T = 1/Fs;  % Período de amostragem
num_samples = 38400; % Número de amostras (VERIFICAR SE É FIXO!)
lead_index = 2; % Lead 'II' (fixo, índice 2)

% Ganho e Baseline (FIXOS, mas IDEALMENTE LIDOS DO .HEA)
Gain = 2000; 
Baseline = -458; 

%% 2. LOOP PRINCIPAL DE PROCESSAMENTO

disp('=== INICIANDO PROCESSAMENTO EM LOTE ===');

for p = 1:length(Patient_Dirs)
    Patient_Dir = Patient_Dirs{p};
    Patient_ID = Patient_Dir; 
    
    % --- NOVO BLOCO: LER SINAIS DO DIRETÓRIO ---
    
    % 1. Constrói o caminho completo da pasta do paciente
    Patient_Path = fullfile(BASE_DIR, Patient_Dir);
    
    % 2. Lista todos os arquivos .hea neste diretório
    files_found = dir(fullfile(Patient_Path, '*.hea'));
    
    % 3. Loop sobre os arquivos ENCONTRADOS
    for s = 1:length(files_found)
        
        File_Name_Full = files_found(s).name;
        
        % Extrai o nome base (remove a extensão '.hea')
        [~, Signal_Name, ~] = fileparts(File_Name_Full);
        
        disp(['  -> Processando Sinal: ', Signal_Name]);

        % --- CONSTRUÇÃO DINÂMICA DOS CAMINHOS ---
        Base_Path = fullfile(Patient_Path, Signal_Name); % Usa Patient_Path aqu 
        header_file = [Base_Path, '.hea']; 
        data_file_dat = [Base_Path, '.dat'];
        data_file_xyz = [Base_Path, '.xyz'];
        
        % ----------------------------------------------------
        % 2.1 Leitura dos Dados (Bloco try/catch do código original)
        % ----------------------------------------------------
        try
            % Tentativa de leitura do arquivo .dat
            fid = fopen(data_file_dat, 'r');
            % NOTE: A dimensão [12, num_samples] é arriscada. O certo é usar fseek ou WFDB.
            data_int = fread(fid, [12, num_samples], 'int16'); 
            fclose(fid);
            
            % Leitura do arquivo .xyz (opcional, mas mantida)
            fid_xyz = fopen(data_file_xyz, 'r');
            data_xyz_int = fread(fid_xyz, [3, num_samples], 'int16'); 
            fclose(fid_xyz);

            ECG_raw = data_int(lead_index, :);
            ECG_mV = (ECG_raw - Baseline) / Gain; 
            
            % Gera o vetor de tempo
            num_samples_current = length(ECG_mV);
            t = (0:num_samples_current-1)*T;
            
        catch ME
            warning(['ERRO ao ler ', Signal_Name, ' para o paciente ', Patient_ID, ': ', ME.message]);
            continue; % Pula para o próximo arquivo se a leitura falhar
        end

        % ----------------------------------------------------
        % 2.2 Filtragem
        % ----------------------------------------------------
        % Chame sua função de filtragem aqui:
        % [ECG_filtered_final] = bandpass_filtering_recomended(ECG_mV, Fs, 2); 
        % Usando a função remove_artefacts_2 (se estiver no seu path)
        [ECG_filtered_final] = remove_artefacts_2(ECG_mV, Fs);
        
        % ----------------------------------------------------
        % 2.3 Extração de Features (Tempo)
        % ----------------------------------------------------
        % ... (Seu código de findpeaks, BPM, SDNN aqui) ...
        [pks, locs] = findpeaks(ECG_filtered_final, Fs, ...
            'MinPeakHeight', 0.2*max(ECG_filtered_final), ... 
            'MinPeakDistance', 0.2); 
        duration_s = t(end);
        BPM_avg = (length(locs) / duration_s) * 60;
        RR_intervals_s = diff(locs);
        SDNN = std(RR_intervals_s * 1000); % em ms

        % ----------------------------------------------------
        % 2.4 Extração de Features (Wavelet e Fractais)
        % ----------------------------------------------------
        sinal_ecg = ECG_filtered_final;
        N_levels = 5;
        Wavelet_Type = 'db4';
        [C,L]=wavedec(sinal_ecg, N_levels, Wavelet_Type);
        
        % Energy (En) - TOTAL
        cA = appcoef(C, L, Wavelet_Type, N_levels);
        Energy_cA = sum(cA.^2);
        Energy_cD_Total = 0;
        for k = 1:N_levels
            cD = detcoef(C, L, k);
            Energy_cD_Total = Energy_cD_Total + sum(cD.^2);
        end
        En_Total = Energy_cA + Energy_cD_Total;

        % Energy (En) - Sub-banda D5 (QRS)
        cD5 = detcoef(C, L, N_levels);
        En_D5 = sum(cD5.^2);
        
        % Fractais e Hurst (Assumindo que as funções estão no seu path)
        Hurst_Exp = Hurst_Exponent_RS_Analysis(sinal_ecg);
        Kmax_param = 16;
        Higuchi_FD = Higuchi_Fractal_Dimension(sinal_ecg, Kmax_param);
        Katz_FD = Katz_Fractal_Dimension(sinal_ecg);
        
        % ----------------------------------------------------
        % 2.5 Criação da Tabela de Resultados e Acumulação
        % ----------------------------------------------------
        
        % Cria a linha de features para o sinal atual
        % Esta funcao foi corrigida porcausa do erro abaixo:
        % Incorrect number of arguments.

% Error in ecg_scalled_features_processing (line 141)
%         Feature_Table_Current = table(Patient_ID, Signal_Name, BPM_avg, SDNN, ...
%                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
% Caused by:
%     You might have intended to create a one-row table with the character vector
%     'ecg_db_patient_01' as one of its variables. To store text data in a table,
%     use a string array or a cell array of character vectors rather than character
%     arrays. Alternatively, create a cell array with one row, and convert that to
%     a table using CELL2TABLE.
        % Feature_Table_Current = table(Patient_ID, Signal_Name, BPM_avg, SDNN, ...
        %     En_Total, En_D5, Hurst_Exp, Higuchi_FD, Katz_FD, ...
        %     'VariableNames', {'Patient_ID', 'Signal_Name', 'BPM_avg', 'SDNN', ...
        %     'En_Total', 'En_D5', 'Hurst_Exp', 'Higuchi_FD', 'Katz_FD'});
        % 
        % --- CORREÇÃO APLICADA AQUI: {Patient_ID} e {Signal_Name} ---
Feature_Table_Current = table({Patient_ID}, {Signal_Name}, BPM_avg, SDNN, ...
    En_Total, En_D5, Hurst_Exp, Higuchi_FD, Katz_FD, ...
    'VariableNames', {'Patient_ID', 'Signal_Name', 'BPM_avg', 'SDNN', ...
    'En_Total', 'En_D5', 'Hurst_Exp', 'Higuchi_FD', 'Katz_FD'});

        % Concatena a linha na tabela mestre
        Feature_Master_Table = [Feature_Master_Table; Feature_Table_Current]; 
        
    end % Fim do loop de sinais
end % Fim do loop de pacientes

%% 3. SALVAMENTO FINAL

disp(' ');
disp('=== PROCESSAMENTO EM LOTE CONCLUÍDO ===');
disp('Tabela Mestra de Características (Primeiras 5 linhas):');
disp(Feature_Master_Table(1:min(5, height(Feature_Master_Table)), :));

visualization_and_analysis(BASE_DIR, Feature_Master_Table);

% Salva a tabela completa em um arquivo CSV
Output_Filename = fullfile(OUTPUT_DIR, 'ECG_Features_Master_Summary.csv');
writetable(Feature_Master_Table, Output_Filename);

disp(['✅ Tabela Mestre salva com sucesso em: ', Output_Filename])
