% This function read files from directory

classdef LoadFiles

    % Properties
    properties
        BASE_DIR
        OUTPUT_DIR
        PATIENT_PATH
        filePath; % Path to the directory containing files
        fileList; % List of files in the directory
    end

    %% Methods
    methods
        function obj = LoadFiles(baseDir, output_dir, Patient_Path, filePath, fileList)
 
            obj.BASE_DIR = baseDir;
            obj.OUTPUT_DIR = output_dir;
            obj.PATIENT_PATH = Patient_Path
            obj.filePath = filePath;
            obj.fileList = fileList; %dir(fullfile(filePath, '*'));
        end
       
        % function to save files
        function Output_Filename = save(obj, file_name, format)

            % check if is empty
            if(isempty(file_name))
                result = false;
                return; % Exit the function if file_name is empty
            end
            if(isempty(format))
                format = 'csv';
            end
            
            % Merge two strings
            file_name = strcat(file_name, ".", format)

            % Diretório para salvar as features
            if ~exist(obj.OUTPUT_DIR, 'dir')
                mkdir(obj.OUTPUT_DIR);
            end

            % Salva a tabela completa em um arquivo CSV
            Output_Filename = fullfile(obj.OUTPUT_DIR, file_name);
            writetable(Feature_Master_Table, Output_Filename);
            
            disp(['✅ Tabela Mestre salva com sucesso em: ', Output_Filename])
        end

        % Get the files extracting the base names
        function [Signal_Name,header_file, data_file_dat, data_file_xyz] = get_files(obj, File_Name_Full)
            % Extrai o nome base (remove a extensão '.hea')
            [~, Signal_Name, ~] = fileparts(File_Name_Full);
            
            disp(['  -> Processando Sinal: ', Signal_Name]);
    
            % --- CONSTRUÇÃO DINÂMICA DOS CAMINHOS ---
            Base_Path = fullfile(obj.PATIENT_PATH, Signal_Name); % Usa Patient_Path aqu 
            header_file = [Base_Path, '.hea']; 
            data_file_dat = [Base_Path, '.dat'];
            data_file_xyz = [Base_Path, '.xyz'];
        end

        %% Load file with WFBD (correct method)
        function [sig, fields] = read_files_wfbd(obj,Signal_Name)
            % CBase path
            Record_Path = fullfile(obj.PATIENT_PATH, Signal_Name);
    
            % =====================================================
            %    Load file with WFBD (correct method)
            % =====================================================
            try
                [sig, fields] = rdsamp(Record_Path);
            catch ME
                warning("Error to read %s: %s", Record_Path, ME.message);
            end
        end
    end

end