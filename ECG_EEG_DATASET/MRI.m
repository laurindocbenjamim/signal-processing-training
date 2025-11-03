close all;
clear all;
clc;

%% Load Image
I = imread('P1_CN_axial_slice_1.png');
load('map.mat')
%% Preprocessing

In = mat2gray(I, [1 256]);

I = medfilt2(In, [3 3]); % Filtering image with median filter, 3x3 kernel by default

figure
imagesc(I)
colormap(map)
%% Wavelet 2D

%
[ILL1,ILH1,IHL1,IHH1] = dwt2(I,'bior1.1');
[ILL2,ILH2,IHL2,IHH2] = dwt2(ILL1,'bior1.1');

% --- Applying wavelet to image
figure
subplot(2,2,1)
imagesc(ILL1)
colormap(map)
title('Approximation at Level 1')
subplot(2,2,2)
imagesc(ILH1)
colormap(map)
title('Horizontal at Level 1')
subplot(2,2,3)
imagesc(IHL1)
colormap(map)
title('Vertical at Level 1')
subplot(2,2,4)
imagesc(IHH1)
colormap(map)
title('Diagonal at Level 1')

% --- Applying wavelet to image LL1
figure
subplot(2,2,1)
imagesc(ILL2)
colormap(map)
title('Approximation at Level 2')
subplot(2,2,2)
imagesc(ILH2)
colormap(map)
title('Horizontal at Level 2')
subplot(2,2,3)
imagesc(IHL2)
colormap(map)
title('Vertical at Level 2')
subplot(2,2,4)
imagesc(IHH2)
colormap(map)
title('Diagonal at Level 2')

% --- Computing GLCMs
GLL1 = graycomatrix(ILL1);
GLH1 = graycomatrix(ILH1); 
GHL1 = graycomatrix(IHL1); 
GHH1 = graycomatrix(IHH1); 
GLL2 = graycomatrix(ILL2); 
GLH2 = graycomatrix(ILH2); 
GHL2 = graycomatrix(IHL2); 
GHH2 = graycomatrix(IHH2); 


featureWavelet{1,1} = GLCM_Features(GLL1,0);
featureWavelet{1,2} = GLCM_Features(GLH1,0);
featureWavelet{1,3} = GLCM_Features(GHL1,0);
featureWavelet{1,4} = GLCM_Features(GHH1,0);

featureWavelet{2,1} = GLCM_Features(GLL2,0);
featureWavelet{2,2} = GLCM_Features(GLH2,0);
featureWavelet{2,3} = GLCM_Features(GHL2,0);
featureWavelet{2,4} = GLCM_Features(GHH2,0);