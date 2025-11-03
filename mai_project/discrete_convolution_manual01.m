%%Passo 1: Definir os vetores de amostras e índices
% --- Sequência x1[n] ---
% Valores das amostras: x1[n] = {1, 2, -2} com n=0 na posição do 2
x1 = [1, 2, -2];
% Índices de tempo n: começa em -1 e termina em 1 (comprimento 3)
n1 = -1:1;

% --- Sequência x2[n] ---
% Valores das amostras: x2[n] = {2, 0, 1} com n=0 na posição do 0
x2 = [2, 0, 1];
% Índices de tempo n: começa em -1 e termina em 1 (comprimento 3)
n2 = -1:1;

%% Passo 2: Calcular a Convolução
% Cálculo da convolução
y = conv(x1, x2);
% Resultado y = [2, 4, -3, 2, -2]

%% Passo 3: Determinar o Range de Índices da Saída ($y[n]$)
% Determinação do range de índices para y[n]
n_y_inicio = n1(1) + n2(1);   % -1 + (-1) = -2
n_y_fim = n_y_inicio + length(y) - 1; % -2 + 5 - 1 = 2
ny = n_y_inicio:n_y_fim;
% Range de ny: [-2, -1, 0, 1, 2]
%% Passo 4: Plotar os Gráficos (Representação Gráfica no MATLAB)
figure;

% 1. Gráfico de x1[n]
subplot(3, 1, 1);
stem(n1, x1, 'filled', 'r'); % 'r' para vermelho
title('Sequência de Entrada x1[n]');
xlabel('Índice de Tempo (n)');
ylabel('x1[n]');
grid on;

% 2. Gráfico de x2[n]
subplot(3, 1, 2);
stem(n2, x2, 'filled', 'b'); % 'b' para azul
title('Sequência de Entrada x2[n]');
xlabel('Índice de Tempo (n)');
ylabel('x2[n]');
grid on;

% 3. Gráfico da Sequência de Saída y[n]
subplot(3, 1, 3);
stem(ny, y, 'filled', 'k'); % 'k' para preto
hold on;
plot(ny(ny==0), y(ny==0), 'ko', 'MarkerSize', 8); % Marca n=0 com um círculo (como na imagem)
hold off;
title('Sequência de Saída y[n] = x1[n] * x2[n]');
xlabel('Índice de Tempo (n)');
ylabel('y[n]');
grid on;