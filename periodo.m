function [freq, pert] = periodo(x,Fs)
% Period of a signal  
% freq - frequency;
% pert - periodo;
xdft = fft(x);
[maxval,idx] = max(abs(xdft))
freq = (Fs*(idx-1))/length(x);
pert = 1/freq;