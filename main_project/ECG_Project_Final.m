%Para ler da Phisionet precisamos da toolbox WFDB e usar a função rdsamp

%%%%%% PLEASE ONLY USE ONE SIGNAL AND ONE LEAD, IT WILL RUN MUCH SLOWER
%%%%%% ONCE WE GET MORE LEADS AND SIGNALS... ONCE WE HAVE EVERYTHING RUNING
%%%%%% SMOOTHLY WE CAN UPSCALE LATER.
%%
clear;
close all;
clc;

patient_cell={}; %creating table for patients
final_cell={};

heafiles=dir(fullfile("main_db","**","*.hea"));


for cur_pat=1:length(heafiles)

recordName=[heafiles(cur_pat).folder,'\',heafiles(cur_pat).name];

  [signal, Fs, tm] = rdsamp(recordName(strfind(recordName,'main_db'):end),[],[],0);

 

[patient_diagnose_label, fid] = load_patient_diagnose(recordName, 'Reason for admission','IgnoreCase');

disp(heafiles(cur_pat).name)
fprintf('Processing ECG\n')

%%



        

leads=size(signal,2); %Recording number of leads for later plot 

tic 
 for cur_lead=1:leads


 % figure, plot(tm,signal(:,1))

fprintf('Lead %d \n', cur_lead)


%% Z-score normalization 

fprintf('Normalizing...\n')

FNyquist = Fs/2; % Frequência de Nyquist
WinTime = 1; % time in seconds for each window
windowSize = Fs * WinTime; % Define window size
n=length(signal(:,cur_lead)); % number of samples 



a=1;
for k = 1:windowSize:n-windowSize-1
    z = (signal(k:k+windowSize-1,cur_lead))-mean(signal(k:k+windowSize-1,cur_lead))./std(signal(k:k+windowSize-1,cur_lead)); % normallize the signal with this x-μ/σ
    ECGSignalNormalized{a,cur_lead} = z - mean(z); % subtract by it's average
    a=a+1;
end



%% Signal Filtering

fprintf('Filtering...\n')

number_of_windows= length(ECGSignalNormalized(:,cur_lead)); % for later for loops making it easier to run through the windows

for k = 1:number_of_windows
    [~, b]=bandpass(ECGSignalNormalized{k,cur_lead},[1 40],Fs); % Band pass between 1 to 40;
    ECGFilteredNormalized{k,cur_lead} = filter(b,ECGSignalNormalized{k,cur_lead});

end

% Debugging and making sure the filters are being aplied correctly 

% figure
% tiledlayout(2,1)
% nexttile
% plot(ECGFilteredNormalizedBand{1,1})
% title("Bandpass filter")
% nexttile
% plot(ECGFilteredNormalized{1,1})
% title("lowpass filter")

%% Descrete Wavelet Transform YEY

fprintf('Creating DWT...\n')

for k = 1:number_of_windows
    [c,l] = wavedec(ECGFilteredNormalized{k,cur_lead}, 3, 'db4'); %Signal decomposition into the its DWT coeficient

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
    
% figure
% tiledlayout(4,1)
% nexttile
% plot(DWT{1,1})
% title("Detail 1")
% nexttile
% plot(DWT{1,2})
% title("Detail 2")
% nexttile
% plot(DWT{1,3})
% title("Detail 3")
% nexttile
% plot(DWT{1,4})
% title("Aporximation 3")

%Plotting full Aproximation Lvl 3 

% figure
% A3mat= cell2mat(A3cell);
% plot(A3mat)
% title('Aproxiation 3')



   %% Feature extration 
    
fprintf('Extracting features... \n')

 for k= 1:number_of_windows

     
     %Aproximate entropy Detail 1
   ApEn(k,1) = approximateEntropy(DWT{k,1});
   
     %Aproximate entropy Detail 2
   ApEn(k,2) = approximateEntropy(DWT{k,2});
 
     %Aproximate entropy Detail 3
   ApEn(k,3) = approximateEntropy(DWT{k,3});
   
   %Aproximate entropy Aproximation 3
   ApEn(k,4) = approximateEntropy(DWT{k,4}); 

   %Aproximate entropy Raw signal
   ApEn(k,5) = approximateEntropy(ECGFilteredNormalized{k,cur_lead});

    %Lyapunov exponent Detail 1
   Elay(k,1)= lyapunovExponent(DWT{k,1});

    %Lyapunov exponent Detail 2 
   Elay(k,2)= lyapunovExponent(DWT{k,2});

    %Lyapunov exponent Detail 3
   Elay(k,3)= lyapunovExponent(DWT{k,3});
  
    %Lyapunov exponent Aproximation 3
   Elay(k,4)= lyapunovExponent(DWT{k,4});

     %Lyapunov exponent Raw signal
   Elay(k,5)= lyapunovExponent(ECGFilteredNormalized{k,cur_lead});

   %Logarithmic entropy Detail 1 
   LogEn(k,1)= logEn(DWT{k,1});

   %Logarithmic entropy Detail 2 
   LogEn(k,2)= logEn(DWT{k,2});
   
   %Logarithmic entropy Detail 3
   LogEn(k,3)= logEn(DWT{k,3});

   %Logarithmic entropy Aproximation 3 
   LogEn(k,4)= logEn(DWT{k,4});

   %Logarithmic entropy Raw signal 
   LogEn(k,5)= logEn(ECGFilteredNormalized{k,cur_lead});

   %Shanon Entropy Detail 1
   ShanEn(k,1)=shannonEntropy(DWT{k,1});

   %Shanon Entropy Detail 2
   ShanEn(k,2)=shannonEntropy(DWT{k,2});
   
   %Shanon Entropy Detail 3
   ShanEn(k,3)=shannonEntropy(DWT{k,3});
   
   %Shanon Entropy Aproximation 3
   ShanEn(k,4)=shannonEntropy(DWT{k,4});

   %Shanon Entropy Raw signal
   ShanEn(k,5)=shannonEntropy(ECGFilteredNormalized{k,cur_lead});

   %Higuchi Fractal Dimension Detail 1
    Higuch(k,1) = higuchi_fd(DWT{k,1}, 10);

    %Higuchi Fractal Dimension Detail 2
    Higuch(k,2) = higuchi_fd(DWT{k,2}, 10);

    %Higuchi Fractal Dimension Detail 3
    Higuch(k,3) = higuchi_fd(DWT{k,3}, 10);

    %Higuchi Fractal Dimension Aproximation 3
    Higuch(k,4) = higuchi_fd(DWT{k,4}, 10);

    %Higuchi Fractal Dimension Raw signal
    Higuch(k,5) = higuchi_fd(ECGFilteredNormalized{k,cur_lead}, 10);
    
    %Hurst Exponent Detail 1 
    HurstExp(k,1) = Hurst_Exponent_RS_Analysis(DWT{k,1});

    %Hurst Exponent Detail 2
    HurstExp(k,2) = Hurst_Exponent_RS_Analysis(DWT{k,2});

    %Hurst Exponent Detail 3 
    HurstExp(k,3) = Hurst_Exponent_RS_Analysis(DWT{k,3});

    %Hurst Exponent Aporximation 3 
    HurstExp(k,4) = Hurst_Exponent_RS_Analysis(DWT{k,4});

    %Hurst Exponent Raw signal 
    HurstExp(k,5) = Hurst_Exponent_RS_Analysis(ECGFilteredNormalized{k,cur_lead});

    %Katz Fractal Dimension Detail 1
    KatzFractal(k,1) = Katz_Fractal_Dimension(DWT{k,1});

     %Katz Fractal Dimension Detail 2
    KatzFractal(k,2) = Katz_Fractal_Dimension(DWT{k,2});

     %Katz Fractal Dimension Detail 3
    KatzFractal(k,3) = Katz_Fractal_Dimension(DWT{k,3});

     %Katz Fractal Dimension Aproximation 3
    KatzFractal(k,4) = Katz_Fractal_Dimension(DWT{k,4});

     %Katz Fractal Dimension Raw signal 
    KatzFractal(k,5) = Katz_Fractal_Dimension(ECGFilteredNormalized{k,cur_lead});

    %Correlation Dimension Detail 1
    CorrDim(k,1) = correlationDimension(DWT{k,1});

    %Correlation Dimension Detail 2
    CorrDim(k,2) = correlationDimension(DWT{k,2});

    %Correlation Dimension Detail 3
    CorrDim(k,3) = correlationDimension(DWT{k,3});

    %Correlation Dimension Aproximation 4
    CorrDim(k,4) = correlationDimension(DWT{k,4});

    %Correlation Dimension Raw Signal
    CorrDim(k,5) = correlationDimension(ECGFilteredNormalized{k,cur_lead});

    %Energy Detail 1
    Energy(k,1) = sum(DWT{k,1}.^2);

    %Energy Detail 2
    Energy(k,2) = sum(DWT{k,2}.^2);
    
    %Energy Detail 3
    Energy(k,3) = sum(DWT{k,3}.^2);

    %Energy Aproximation 3
    Energy(k,4) = sum(DWT{k,4}.^2);

    %Energy Raw Signal
    Energy(k,5) = sum(ECGFilteredNormalized{k,cur_lead}.^2);
    



 end

 %% Data Compression and addition to table 
   
fprintf('Compressing Data and creating tables... \n')

    for k=1:5
    ApEnMEAN(k)= mean(ApEn(:,k));
    ApEnSTD(k)= std(ApEn(:,k));
    ApEn95P(k)= prctile(ApEn(:,k),95);
    ApEnVAr(k)= var(ApEn(:,k));
    ApEnMEDIAN(k)= median(ApEn(:,k));
    ApEnKURT(k)= kurtosis(ApEn(:,k));
    
    CorrDimMEAN(k)= mean(CorrDim(:,k));
    CorrDimSTD(k)= std(CorrDim(:,k));
    CorrDim95P(k)= prctile(CorrDim(:,k),95);
    CorrDimVAr(k)= var(CorrDim(:,k));
    CorrDimMEDIAN(k)= median(CorrDim(:,k));
    CorrDimKURT(k)= kurtosis(CorrDim(:,k));

    EnergyMEAN(k)= mean(Energy(:,k));
    EnergySTD(k)= std(Energy(:,k));
    Energy95P(k)= prctile(Energy(:,k),95);
    EnergyVAr(k)= var(Energy(:,k));
    EnergyMEDIAN(k)= median(Energy(:,k));
    EnergyKURT(k)= kurtosis(Energy(:,k)); 

    ElayMEAN(k)=mean(Elay(:,k));
    ElaySTD(k)= std(Elay(:,k));
    Elay95P(k)= prctile(Elay(:,k),95);
    ElayVAr(k)= var(Elay(:,k));
    ElayMEDIAN(k)= median(Elay(:,k));
    ElayKURT(k)= kurtosis(Elay(:,k));


    LogEnMEAN(k)=mean(LogEn(:,k));
    LogEnSTD(k)= std(LogEn(:,k));
    LogEn95P(k)= prctile(LogEn(:,k),95);
    LogEnVAr(k)= var(LogEn(:,k));
    LogEnMEDIAN(k)= median(LogEn(:,k));
    LogEnKURT(k)= kurtosis(LogEn(:,k));

    ShanEnMEAN(k)=mean(ShanEn(:,k));
    ShanEnSTD(k)= std(ShanEn(:,k));
    ShanEn95P(k)= prctile(ShanEn(:,k),95);
    ShanEnVAr(k)= var(ShanEn(:,k));
    ShanEnMEDIAN(k)= median(ShanEn(:,k));
    ShanEnKURT(k)= kurtosis(ShanEn(:,k));


    HiguchMEAN(k)=mean(Higuch(:,k));
    HiguchSTD(k)= std(Higuch(:,k));
    Higuch95P(k)= prctile(Higuch(:,k),95);
    HiguchVAr(k)= var(Higuch(:,k));
    HiguchMEDIAN(k)= median(Higuch(:,k));
    HiguchKURT(k)= kurtosis(Higuch(:,k));

    HurstExpMEAN(k)=mean(HurstExp(:,k));
    HurstExpSTD(k)= std(Higuch(:,k));
    HurstExp95P(k)= prctile(Higuch(:,k),95);
    HurstExpVAr(k)= var(Higuch(:,k));
    HurstExpMEDIAN(k)= median(Higuch(:,k));
    HurstExpKURT(k)= kurtosis(Higuch(:,k));

    KatzFractalMEAN(k)=mean(KatzFractal(:,k));
    KatzFractalSTD(k)= std(KatzFractal(:,k));
    KatzFractal95P(k)= prctile(KatzFractal(:,k),95);
    KatzFractalVAr(k)= var(KatzFractal(:,k));
    KatzFractalMEDIAN(k)= median(KatzFractal(:,k));
    KatzFractalKURT(k)= kurtosis(KatzFractal(:,k));

    end

   
    

    temp_table = table(ApEnMEAN,ApEnSTD,ApEn95P,ApEnVAr,ApEnMEDIAN,ApEnKURT, CorrDimMEAN, CorrDimSTD,CorrDim95P, CorrDimVAr, CorrDimMEDIAN, CorrDimKURT, EnergyMEAN, EnergySTD, Energy95P, EnergyVAr, EnergyMEDIAN, EnergyKURT, ...
        ElayMEAN,ElaySTD,Elay95P,ElayVAr,ElayMEDIAN,ElayKURT,LogEnMEAN,LogEnSTD,LogEn95P,LogEnVAr,LogEnMEDIAN,LogEnKURT, ...
        ShanEnMEAN, ShanEnSTD,ShanEn95P, ShanEnVAr,ShanEnMEDIAN,ShanEnKURT,HiguchMEAN,HiguchSTD,Higuch95P,HiguchVAr,HiguchMEDIAN,HiguchKURT,HurstExpMEAN,HurstExpSTD,HurstExp95P,HurstExpVAr, ...
        HurstExpMEDIAN,HurstExpKURT,KatzFractalMEAN,KatzFractalSTD,KatzFractal95P,KatzFractalVAr,KatzFractalMEDIAN,KatzFractalKURT);
    
   temp_table = renamevars(temp_table,temp_table.Properties.VariableNames,temp_table.Properties.VariableNames + "_lead" + cur_lead);
    
   lead_cell{cur_lead}= temp_table;
    
   fprintf('lead %d %s \n', cur_lead, 'is done')
   
   

 end
fprintf('The ECG of the  patinent nº %d %s \n', cur_pat, 'is done!')
toc

t=table(convertCharsToStrings(patient_diagnose_label));
t= renamevars(t,"Var1",'Patient diagnosis');
lead_cell{cur_lead+1}=t;

patient_cell= cat(2,lead_cell{:});


final_cell{cur_pat}=patient_cell ;

fprintf('%d%s \n',int8((cur_pat/length(heafiles))*100),'% done!')
 end


 
   %% 
   final_Tabel= cat(1,final_cell{:});
