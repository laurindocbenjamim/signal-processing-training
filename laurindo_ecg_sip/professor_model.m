%%% Processamento de sinal

w=1; A=[]; t=5; tWindows=t*Famostragem; sinaldelta=[]; %janelas de 5s

for j=1:2

  for i=1:tWindows:length(S{j})-tWindows

  [signal] = signal_normalization(S, signal, tWindows,  j, i);

  %Exemplo STFT (FFT por janelas periodicas)

 A{j,w}=fft(S{j}(i:i+tWindows-1), length(S{j}(i:i+tWindows-1)));

  % Extração de características espectrais - Exemplo PSD

 pxy3{j,w} = cpsd(signal,signal,hamming(length(signal)),[],2048,Famostragem); % Power Spectral Density

 vf = [0:Famostragem/(2*(length(pxy3{j,w})-1)):Famostragem/2];

 w=w+1;

 R{j}= w-1;

  end

 w=1;

end