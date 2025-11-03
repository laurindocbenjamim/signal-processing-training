classdef ManipuladorSinais1
    %MANIPULADORSINAIS Classe para gerar, transformar e plotar sinais (CT e DT).
    % Inclui a descrição do tipo de sinal (Contínuo/Discreto) no título do gráfico.
    
    properties
        % Propriedades para Sinais de Tempo Contínuo (CT)
        t_start = -5;      % Tempo inicial
        t_end = 5;         % Tempo final
        dt = 0.01;         % Passo de tempo (para simular continuidade)
        t                 % Vetor de tempo CT
        
        % Propriedades para Sinais de Tempo Discreto (DT)
        n_start = -5;      % Índice inicial
        n_end = 5;         % Índice final
        n                 % Vetor de índices DT
    end
    
    methods
        function obj = ManipuladorSinais()
            % Construtor - Inicializa os vetores de tempo e índice
            obj.t = obj.t_start:obj.dt:obj.t_end;
            obj.n = obj.n_start:1:obj.n_end;
        end
        
        % ==============================================
        % MÉTODOS DE GERAÇÃO DE SINAIS BASE (ORIGINAIS)
        % ==============================================
        
        function [x_t, eq_t] = sinalSenoidalCT(obj)
            % Sinal Senoidal Contínuo: x(t) = cos(pi*t)
            eq_t = 'x(t) = cos(\pi t)';
            x_t = cos(pi * obj.t);
        end

        function [u_t, eq_u] = sinalDegrauCT(obj)
            % Sinal Degrau Contínuo: x(t) = u(t)
            eq_u = 'x(t) = u(t)';
            u_t = (obj.t >= 0); % u(t)
        end
        
        function [y_n, eq_n] = sinalDiscretoBase(obj)
            % Sinal Discreto Base: y[n] = (1/2)^n * u[n]
            eq_n = 'y[n] = (1/2)^n u[n]';
            % Gera u[n] para o vetor n
            u_n = (obj.n >= 0);
            y_n = (0.5).^obj.n .* u_n;
        end

        function [u_n, eq_u] = sinalDegrauDT(obj)
            % Sinal Degrau Discreto: u[n]
            eq_u = 'u[n]';
            u_n = (obj.n >= 0);
        end
        
        % ==============================================
        % MÉTODO DE PLOTAGEM GERAL
        % ==============================================
        
        function plotaSinal(obj, t_ou_n, sinal, equacao, tipo)
            % t_ou_n: Vetor de tempo (t) ou índice (n)
            % sinal: Vetor de amplitude do sinal
            % equacao: String com a equação do sinal
            % tipo: 'CT' (Contínuo) ou 'DT' (Discreto)
            
            figure;
            
            % Define o tipo de plotagem, a variável do eixo X e o rótulo do sinal
            if strcmp(tipo, 'CT')
                tipo_sinal = 'Contínuo';
                plot(t_ou_n, sinal, 'LineWidth', 2);
                xlabel('Tempo (t)');
                hold on;
            elseif strcmp(tipo, 'DT')
                tipo_sinal = 'Discreto';
                stem(t_ou_n, sinal, 'filled', 'LineWidth', 1.5);
                xlabel('Índice (n)');
                hold on;
                % Plota uma linha tracejada para melhor visualização do sinal discreto
                plot(t_ou_n, sinal, 'r:'); 
            else
                 tipo_sinal = 'Desconhecido';
            end
            
            grid on;
            ylabel('Amplitude');
            
            % Inclui o tipo de sinal no título
            titulo_completo = sprintf('Sinal %s: %s', tipo_sinal, equacao);
            title(titulo_completo, 'Interpreter', 'tex');
            
            yline(0, 'k--'); % Linha em y=0
            xline(0, 'k--'); % Linha em x=0
            hold off;
        end
        
        % ==============================================
        % MÉTODOS AUXILIARES PARA TRANSFORMAÇÕES DT COMPLEXAS
        % ==============================================
        
        function sinal_transformado = transformaDT(obj, sinal_original, n_transformado)
            % Mapeia as amostras do sinal_original (baseado em obj.n) para um novo
            % vetor, de acordo com a transformação de índice n_transformado.
            % Usado para compressão/expansão de tempo.
            
            sinal_transformado = zeros(size(obj.n));
            
            for k = 1:length(obj.n)
                idx = n_transformado(k);
                
                % Verifica se o índice transformado é um inteiro (válido para DT)
                % e se está dentro dos limites definidos (obj.n_start a obj.n_end)
                if abs(idx - round(idx)) < 1e-9 && idx >= obj.n_start && idx <= obj.n_end
                    % Calcula a posição (índice) no vetor do sinal_original
                    indice_original = round(idx) - obj.n_start + 1;
                    
                    % Atribui o valor do sinal original ao novo sinal
                    sinal_transformado(k) = sinal_original(indice_original);
                end
            end
        end

    end % Fim dos methods
end