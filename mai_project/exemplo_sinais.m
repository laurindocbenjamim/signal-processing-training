function exemplo_sinais()

    % Limpa o ambiente e fecha figuras
    clc;
    close all;
    
    % 1. Instanciar a classe
    sig = ManipuladorSinais();
    t = sig.t;
    n = sig.n;

    % 2. Gerar todos os sinais e transformações solicitadas
    
    % Sinais Base
    [x_t, eq_x_t] = sig.sinalSenoidalCT();
    [u_t, eq_u_t] = sig.sinalDegrauCT();
    [y_n, eq_y_n] = sig.sinalDiscretoBase();
    [u_n_dt, eq_u_n_dt] = sig.sinalDegrauDT();
    [cos_n_base, ~] = sig.sinalCosDiscretoBase();
    
    % GRUPO 1: Sinais Contínuos (CT)
    x_t_menos_t = cos(pi * (-t));
    dois_x_t = 2 * x_t;
    
    % NOVOS SINAIS CT
    x_t_menos_1 = cos(pi * (t - 1));
    x_t_mais_1 = cos(pi * (t + 1));
    
    
    % GRUILPO 2: Sinais Discretos (DT) (Baseados em y[n])
    y_n_mais_dois = sig.transformaDT(y_n, n + 2);
    dois_y_menos_n_mais_dois = 2 * sig.transformaDT(y_n, -n + 2);
    dois_y_2n_menos_dois = 2 * sig.transformaDT(y_n, 2*n - 2);
    menos_y_2n_mais_dois = -1 * sig.transformaDT(y_n, 2*n + 2);
    y_n_menos_dois = sig.transformaDT(y_n, n - 2);
    sinal_multiplicado = menos_y_2n_mais_dois .* (2*y_n) .* (2*y_n_menos_dois);
    sinal_somado = sig.transformaDT(y_n, 2*n + 2) + (2*y_n) + (2*y_n_menos_dois);
    
    % NOVOS SINAIS DT
    y_n_menos_um = sig.transformaDT(y_n, n - 1);
    sinal_combinado_dt = cos_n_base + 0.2 * y_n; % cos[(0.04pi)n] + 0.2y[n]

    % GRUPO 3: Degrau Contínuo (CT)
    u_menos_t = (-t >= 0);
    dois_u_t_menos_dois = 2 * (t-2 >= 0);
    sinal_soma_u = dois_u_t_menos_dois + u_t + dois_u_t_menos_dois;

    % GRUPO 4: Degrau Discreto (DT)
    u_menos_n = (-n >= 0);
    u_n_menos_dois_dt = (n-2 >= 0);
    u_n_menos_um_dt = (n-1 >= 0);
    sinal_soma_u_dt = 2*u_n_menos_dois_dt + (0.5)*u_n_menos_um_dt;

    % GRUPO 5: Simétricos (DT)
    y_menos_n_sim = sig.transformaDT(y_n, -n);
    y_menos_n_mais_dois_sim = sig.transformaDT(y_n, -n + 2);
    soma_simetrica = -2*y_menos_n_mais_dois_sim + 2*y_menos_n_mais_dois_sim;


    % 3. Criação da Lista Estruturada de Sinais para Seleção
    
    sinais = struct('vetor', {}, 'equacao', {}, 'tipo', {});
    
    % Adicionando os Sinais Contínuos (CT)
    sinais(end+1) = struct('vetor', x_t, 'equacao', eq_x_t, 'tipo', 'CT');                               % x(t)
    sinais(end+1) = struct('vetor', x_t_menos_t, 'equacao', 'x(-t)', 'tipo', 'CT');                     % x(-t)
    sinais(end+1) = struct('vetor', dois_x_t, 'equacao', '2x(t)', 'tipo', 'CT');                        % 2x(t)
    sinais(end+1) = struct('vetor', x_t_menos_1, 'equacao', 'x(t-1)', 'tipo', 'CT');                    % NOVO: x(t-1)
    sinais(end+1) = struct('vetor', x_t_mais_1, 'equacao', 'x(t+1)', 'tipo', 'CT');                     % NOVO: x(t+1)
    
    % Adicionando Sinais Discretos (DT)
    sinais(end+1) = struct('vetor', y_n, 'equacao', eq_y_n, 'tipo', 'DT');                              % y[n]
    sinais(end+1) = struct('vetor', y_n_mais_dois, 'equacao', 'y[n+2]', 'tipo', 'DT');                  % y[n+2]
    sinais(end+1) = struct('vetor', dois_y_menos_n_mais_dois, 'equacao', '2y[-n+2]', 'tipo', 'DT');     % 2y[-n+2]
    sinais(end+1) = struct('vetor', dois_y_2n_menos_dois, 'equacao', '2y[2n-2]', 'tipo', 'DT');         % 2y[2n-2]
    sinais(end+1) = struct('vetor', menos_y_2n_mais_dois, 'equacao', '-y[2n+2]', 'tipo', 'DT');         % -y[2n+2]
    sinais(end+1) = struct('vetor', y_n_menos_um, 'equacao', 'y[n-1]', 'tipo', 'DT');                   % NOVO: y[n-1]
    sinais(end+1) = struct('vetor', sinal_multiplicado, 'equacao', '-y[2n+2] \cdot 2y[n] \cdot 2y[n-2]', 'tipo', 'DT'); % Multiplicação
    sinais(end+1) = struct('vetor', sinal_somado, 'equacao', 'y[2n+2] + 2y[n] + 2y[n-2]', 'tipo', 'DT');% Soma
    sinais(end+1) = struct('vetor', sinal_combinado_dt, 'equacao', 'cos[(0.04\pi)n] + 0.2y[n]', 'tipo', 'DT'); % NOVO: Combinação
    
    % Adicionando Sinais de Degrau Contínuo (CT)
    sinais(end+1) = struct('vetor', u_t, 'equacao', eq_u_t, 'tipo', 'CT');                              % u(t)
    sinais(end+1) = struct('vetor', u_menos_t, 'equacao', 'u(-t)', 'tipo', 'CT');                      % u(-t)
    sinais(end+1) = struct('vetor', dois_u_t_menos_dois, 'equacao', '2u(t-2)', 'tipo', 'CT');           % 2u(t-2)
    sinais(end+1) = struct('vetor', sinal_soma_u, 'equacao', '2u(t-2) + u(t) + 2u(t-2)', 'tipo', 'CT'); % Soma Degrau CT

    % Adicionando Sinais de Degrau Discreto (DT)
    sinais(end+1) = struct('vetor', u_n_dt, 'equacao', eq_u_n_dt, 'tipo', 'DT');                        % u[n]
    sinais(end+1) = struct('vetor', u_menos_n, 'equacao', 'u[-n]', 'tipo', 'DT');                      % u[-n]
    sinais(end+1) = struct('vetor', sinal_soma_u_dt, 'equacao', '2u[n-2] + \frac{1}{2}u[n-1]', 'tipo', 'DT'); % Soma Degrau DT

    % Adicionando Sinais Simétricos (DT)
    sinais(end+1) = struct('vetor', y_menos_n_sim, 'equacao', 'y[-n]', 'tipo', 'DT');                   % y[-n]
    sinais(end+1) = struct('vetor', y_menos_n_mais_dois_sim, 'equacao', 'y[-n+2]', 'tipo', 'DT');       % y[-n+2]
    sinais(end+1) = struct('vetor', soma_simetrica, 'equacao', '-2y[-n+2] + 2y[-n+2]', 'tipo', 'DT');   % Soma Simétrica


    % 4. Lógica de Seleção
    
    fprintf('------------------------------------------------------------\n');
    fprintf('Escolha o(s) sinal(ais) para plotar:\n\n');
    
    % Exibir a lista para o usuário
    for i = 1:length(sinais)
        fprintf('%2d. [%s] %s\n', i, sinais(i).tipo, sinais(i).equacao);
    end
    fprintf('\nDigite o(s) número(s) do(s) sinal(ais) separados por vírgula (Ex: 1, 5, 20) ou "TUDO" para plotar todos.\n');
    fprintf('------------------------------------------------------------\n');
    
    selecao_input = input('Sinais a plotar: ', 's');
    
    if strcmpi(selecao_input, 'TUDO')
        indices_selecionados = 1:length(sinais);
    else
        % Converte a string de entrada para um array de números
        try
            indices_selecionados = str2num(selecao_input); %#ok<ST2NM>
            indices_selecionados = unique(indices_selecionados); % Remove duplicatas
        catch
            disp('Erro: Seleção inválida. Nenhuma plotagem realizada.');
            return;
        end
    end
    
    % 5. Plotagem dos Sinais Selecionados
    
    num_plotted = 0;
    for idx = indices_selecionados
        if idx >= 1 && idx <= length(sinais)
            s = sinais(idx);
            
            % Escolhe o vetor de tempo/índice apropriado
            if strcmp(s.tipo, 'CT')
                eixo_x = t;
            else
                eixo_x = n;
            end
            
            % Chama o método de plotagem da classe
            sig.plotaSinal(eixo_x, s.vetor, s.equacao, s.tipo);
            num_plotted = num_plotted + 1;
        else
            fprintf('Aviso: O número %d está fora do intervalo de sinais disponíveis.\n', idx);
        end
    end
    
    fprintf('\nPlotagem concluída. %d gráfico(s) gerado(s).\n', num_plotted);

end