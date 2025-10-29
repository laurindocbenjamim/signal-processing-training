clc;
close all;
clear all;
n=input('Enter length of input sequence:');
l=input('Enter down-sampling/decimation factor:');

m=0:n-1; %making a vector m from the lenght of input sequence
a=input('Enter Slope of Ramp Signal:');
x = (0:n-1)*a; % for generating ramp signal x with a slope of a
%replace your own signal/sequence with the variable x

figure,stem(m,x);
xlabel('Time N');
ylabel('Amplitude');
title('Input Signal');

y=downsample(x,l);

nm=0:length(y)-1;
figure,stem(nm,y); %Upsampled version of signal
xlabel('Time N');
ylabel('Amplitude');
title('Down-Sampled Output of Signal');


xi=x;
yi = decimate(xi,l);
nn=0:length(yi)-1;
figure,stem(nn,yi); %interpolation output 
xlabel('Time N');
ylabel('Amplitude');
title('Decimator Output');

