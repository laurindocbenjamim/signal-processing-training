% GERE AUTOMATICAMENTE OS SINAIS x1[n] e x2[n] (Item 1. (a))

% 1. Definição do vetor de tempo comum
% Vamos considerar um intervalo de tempo n que abrange ambos os sinais
n = -4:1:5;

% 2. Definição do Sinal x1[n]
% x1[n] tem valores não nulos no intervalo [-3, 4]
n1_start = -3;
n1_end = 4;
x1_valores = [6, 4, 2, 0, -2, -4, -6, -8];

% Inicializa x1 com zeros
x1 = zeros(size(n));

% Encontra os índices (posições) do vetor n que correspondem a n1_start e n1_end
% A função ismember encontra os elementos de [n1_start:n1_end] dentro de n e retorna
% as posições (loc) onde eles ocorrem.
[~, loc_start] = ismember(n1_start, n);
[~, loc_end] = ismember(n1_end, n);

% Atribui os valores ao vetor x1 nas posições corretas
x1(loc_start:loc_end) = x1_valores;

% 3. Definição do Sinal x2[n]
% x2[n] tem valores não nulos no intervalo [-3, 5]
n2_start = -3;
n2_end = 5;
x2_valores = [-1, -1, -1, 1, 1, 1, 1, 1, 1];

% Inicializa x2 com zeros
x2 = zeros(size(n));

% Encontra os índices (posições) do vetor n que correspondem a n2_start e n2_end
[~, loc2_start] = ismember(n2_start, n);
[~, loc2_end] = ismember(n2_end, n);

% Atribui os valores ao vetor x2 nas posições corretas
x2(loc2_start:loc2_end) = x2_valores;

% 4. Plotagem dos sinais originais (Para verificar a correção)
figure;
subplot(2, 1, 1);
stem(n, x1, 'filled');
title('Sinal x_1[n]');
xlabel('n');
ylabel('x_1[n]');
grid on;

subplot(2, 1, 2);
stem(n, x2, 'filled');
title('Sinal x_2[n]');
xlabel('n');
ylabel('x_2[n]');
grid on;