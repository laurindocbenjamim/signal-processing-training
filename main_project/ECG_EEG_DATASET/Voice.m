clear;
close all;
clc;

%% Loading 1 Voice recording

[signalVoice, fsVoice] = audioread('1-a_n.wav');
%
r=audioplayer(signalVoice, fsVoice);
play(r)

%
figure
t=0:1/fsVoice: (length(signalVoice)-1)/fsVoice;
plot(t,signalVoice)

%%
WinTime = 0.1; % time in seconds for each window
windowSize = fsVoice * WinTime;



%% --- Removing DC and normalizing by RMS
a = 1;
for k= 1:windowSize:length(signalVoice)-windowSize-1
    
    rms = sqrt(sum(signalVoice(k:k+windowSize-1,1).^2)/length(signalVoice(k:k+windowSize-1,1)));
    signal{a} = signalVoice(k:k+windowSize-1,1)/rms;
    signal{a} = signal{a} - mean(signal{a});
a=a+1;
end

%%
for k= 1:length(signal)
energy(k,1) = sum(abs(signal{k}).^2); % Energy
entropy(k,1) = wentropy(signal{k}); % Entropy
end

feature = mean(energy);

