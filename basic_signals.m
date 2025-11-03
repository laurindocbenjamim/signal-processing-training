%% Create the Kronecker Delt Signal δ[n]
% Theorem: δ[n]=1 if n=0, and δ[n]=0 if n != 0

% Set the sample of vector
% n=-5:5;  % Sample from -5 to 5
% 
% % Create the DelTa Signal
% delta = zeros(size(n)); % Create a vector of zeros
% delta(n==0) = 1; % Set 1 only in n=0
% 
% % plot
% 
% figure,stem(n, delta, 'filled', 'LineWidth', 2);
% title('Sinal Delta \delta[n]');
% xlabel('Amostras (n)');
% ylabel('Amplitude');
% grid on;
%% Basic Step signal degree u[n]
% Theorem: u[n]=1 if n>=0, and u[n]=0 if n<0

%% DEFINIR SINAL BASE ALTERNATIVO
n = -10:10;
% Sinal triangular como alternativa ao sinc
x = zeros(size(n));
for i = 1:length(n)
    if abs(n(i)) <= 5
        x(i) = 1 - abs(n(i))/5;  % Triângulo de base ±5
    end
end

% Ou usar uma senoidal modificada
% x = sin(pi*n/5) ./ (pi*n/5); 
% x(isnan(x)) = 1;  % Corrigir divisão por zero em n=0

% figure;
% stem(n, x, 'b', 'filled', 'LineWidth', 2);
% title('Sinal Original: x[n] (triangular)');
% xlabel('n'); ylabel('Amplitude');
% grid on;

%% 1. y1[n] = 2x[-n+2] * x[-n-2] * x[n]
[x1, n1] = transform_signal(x, n, 'reverse_shift', 2);   % x[-n+2]
[x2, n2] = transform_signal(x, n, 'reverse_shift', -2);  % x[-n-2]

% Multiplicação no domínio comum n
y1 = zeros(size(n));
for i = 1:length(n)
    % Encontrar índices correspondentes
    idx1 = find(n1 == n(i), 1);
    idx2 = find(n2 == n(i), 1);
    
    if ~isempty(idx1) && ~isempty(idx2)
        y1(i) = 2 * x1(idx1) * x2(idx2) * x(i);
    end
end

figure('Position', [100, 100, 800, 600]);
subplot(2,2,1); stem(n, x, 'filled'); title('x[n]'); grid on;
subplot(2,2,2); stem(n1, x1, 'filled'); title('x[-n+2]'); grid on;
subplot(2,2,3); stem(n2, x2, 'filled'); title('x[-n-2]'); grid on;
subplot(2,2,4); stem(n, y1, 'r', 'filled', 'LineWidth', 2);
title('y1[n] = 2x[-n+2] \cdot x[-n-2] \cdot x[n]'); grid on;
