%Para ler da Phisionet precisamos da toolbox WFDB e usar a função rdsamp

%%%%%% PLEASE ONLY USE ONE SIGNAL AND ONE LEAD, IT WILL RUN MUCH SLOWER
%%%%%% ONCE WE GET MORE LEADS AND SIGNALS... ONCE WE HAVE EVERYTHING RUNING
%%%%%% SMOOTHLY WE CAN UPSCALE LATER.

cd("main_db\ecg_db_patient_01\")

[signal, Fs, tm] =rdsamp('s0010_re.dat',[],[],0);

leads=size(signal,2); %Recording number of leads for later plot 



 figure, plot(tm,signal(:,1))




%% Z-score normalization 

FNyquist = Fs/2; % Frequência de Nyquist
WinTime = 1; % time in seconds for each window
windowSize = Fs * WinTime; % Define window size
n=length(signal(:,1)); % number of samples 



a=1;
for k = 1:windowSize:n-windowSize-1
    z = (signal(k:k+windowSize-1,1))-mean(signal(k:k+windowSize-1,1))./std(signal(k:k+windowSize-1,1)); % normallize the signal with this x-μ/σ
    ECGSignalNormalized{a,1} = z - mean(z); % subtract by it's average
    a=a+1;
end



%% Signal Filtering

number_of_windows= length(ECGSignalNormalized(:,1)); % for later for loops making it easier to run through the windows

for k = 1:number_of_windows
    [~, b]=bandpass(ECGSignalNormalized{k,1},[0.5 40],Fs); % band pass between 1 to 40;
    ECGFilteredNormalizedBand{k,1} = filter(b,ECGSignalNormalized{k,1});
    
    [y,f] = butter(5, 40/FNyquist, 'low'); %Low pass butter filter for 40 hz 
    ECGFilteredNormalized{k,1} = filtfilt(y,f,ECGFilteredNormalizedBand{k,1});

end

% Debugging and making sure the filters are being aplied correctly 

figure
tiledlayout(2,1)
nexttile
plot(ECGFilteredNormalizedBand{1,1})
title("Bandpass filter")
nexttile
plot(ECGFilteredNormalized{1,1})
title("lowpass filter")

%% Descrete Wavelet Transform YEY

for k = 1:number_of_windows
    [c,l] = wavedec(ECGSignalNormalized{k,1}, 3, 'db4'); %Signal decomposition into the its DWT coeficient

    A3 = appcoef(c,l,'db4', 3); %Coeficient of aproximation Level 3
    D1 = detcoef(c,l,1); %Coeficient of detail level 1
    D2 = detcoef(c,l,2); %Coeficient of detail level 2
    D3 = detcoef(c,l,3); %Coeficient of detail level 3

    %Creating a cell to save every coeficient for later feature extration 
    DWT{k,1}= D1;
    DWT{k,2}= D2;
    DWT{k,3}= D3;
    DWT{k,4}= A3;
    
    %This is just to later plot the aproximation lvl 3
    A3cell{k,1}= DWT{k,4};
end

%Debuging and making sure everything the DWT is correct
    
figure
tiledlayout(4,1)
nexttile
plot(DWT{1,1})
title("Detail 1")
nexttile
plot(DWT{1,2})
title("Detail 2")
nexttile
plot(DWT{1,3})
title("Detail 3")
nexttile
plot(DWT{1,4})
title("Aporximation 3")

%Plotting full Aproximation Lvl 3 

figure
A3mat= cell2mat(A3cell);
plot(A3mat)
title('Aproxiation 3')

