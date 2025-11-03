% Discrete signal x[n] = A ∗ sin(2 ∗ pi ∗ f ∗ n/Fs);
% Parâmetros do sinal
f = 10;           % Frequência: 10 Hz
Fs = 100;         % Amostragem: 100 Hz
t = 0:1/Fs:1;     % Vetor tempo de 0 a 1 segundo

% Sinal senoidal contínuo para comparação
x_cont = sin(2*pi*f*t);

% Sua versão discreta
n = 1:2:10;
x_disc = sin(2*pi*f*n/Fs);

% Plot comparativo
figure;
subplot(2,1,1);
plot(t, x_cont);
title('Sinal Senoidal Contínuo');
xlabel('Tempo (s)');
ylabel('Amplitude');
grid on;

subplot(2,1,2);
stem(n/Fs, x_disc, 'r', 'filled');
title('Sinal Amostrado (seu código)');
xlabel('Tempo (s)');
ylabel('Amplitude');
grid on;