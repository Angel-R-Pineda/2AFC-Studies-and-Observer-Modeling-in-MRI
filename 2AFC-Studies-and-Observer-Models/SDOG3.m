function AUC = SDOG3(trialType,q, alpha, sig_0, noiseConstant)

% Authors: Alexandra O'Neill and Emely Valdez
% Date: 7/28/2020
% Modified by Alexandra O'Neill on 10/28/2020

% Modified by Angel Pineda 6/14/2022

% This function takes the trialType,typeOfFilter, q, alpha, sig_0, and a noiseConstant
% as inputs. Where trialType is the name of the data set of the images
% used, q, alpha, and sig_0 are the actual parameters of the equation for
% SDOG values, and noiseConstant is the constant value of internal noise
% that will be used to match the SDOG to human performance.

% The function outputs the AUC.

% initialize random number generator for generation of the internal noise
rng(7)

% combines the character vectors trialType(name of the file)
% and .mat then returns the new character vector to data_file_name
data_file_name = strcat(trialType,'.mat');

% load variables from the .mat file that contains the image arrays
% into the workspace
load(data_file_name);

% current date is returned as a character vector to the variable Date
Date = date;
% creates the name of the file that will be saved
trial_file_name = strcat(trialType,'_SDOG_',Date);

% nImages is equal to the number of images in the signalImageArray
% dimX is equal to the number of pixels in the x direction of the images in
% the signalImageArray
[nImages, dimX, ~] = size(signalImageArray);
nPixels = dimX;

%%%% Generate channel profiles

% Creates a grid of the x values
% So copies of the array linspace(-nPixels/2,nPixels/2-1,nPixels) will be
% in a nPixels by 1 block arrangement
% linspace creates a row vector of nPixels evenly spaced points in the interval
% [-nPixels/2,nPixels/2-1]
x_grid=repmat(linspace(-nPixels/2,nPixels/2-1,nPixels),nPixels,1);

% Creates a grid of the y values
% So copies of the array linspace(nPixels/2,-nPixels/2+1,nPixels) will be
% in a nPixels by 1 block arrangement
% linspace creates a row vector of nPixels evenly spaced points in the interval
% [nPixels/2,-nPixels/2+1]
y_grid=repmat(linspace(nPixels/2,-nPixels/2+1,nPixels).',1,nPixels);

% calculates the distance away from the center to each pixel and rounds it
% to the nearest decimal or integer
distance=(sqrt(x_grid.^2+y_grid.^2))/nPixels;

% standard deviation of each channel
sig_1=sig_0*alpha;
sig_2=sig_0*alpha^2;

% This is an implentation of the difference of two Gaussians
% 3 channels were created because this is a sparse-DOG, a dense-DOG can
% easily be created by adding more channels of this form
Channel1=exp(-0.5*((distance./(q*sig_0)).^2))-exp(-0.5*(distance./sig_0).^2);
Channel2=exp(-0.5*((distance./(q*sig_1)).^2))-exp(-0.5*(distance./sig_1).^2);
Channel3=exp(-0.5*((distance./(q*sig_2)).^2))-exp(-0.5*(distance./sig_2).^2);


% Normalizes the bounds to be between 0 and 1 and makes the amplitude 1 for
% each channel
Channel1=Channel1/max(Channel1(:));
Channel2=Channel2/max(Channel2(:));
Channel3=Channel3/max(Channel3(:));


% changing the channels from the frequency domain into the spatial domain
% first: shifts 0-frequency component from center of the Channel array
% back to the first corner of the array
% second: the multidimensional discrete inverse FT of the Channel
% third: shifts 0-frequency component from first corner of the array to the
% center
Channel1_img=fftshift(ifftn(ifftshift(Channel1)));
Channel2_img=fftshift(ifftn(ifftshift(Channel2)));
Channel3_img=fftshift(ifftn(ifftshift(Channel3)));

%%

% initializing a data array to hold the 3 channel features for each
% image with the signal and without the signal
signalDataArray = zeros(nImages, 3);
backgroundDataArray = zeros(nImages, 3);


% for loop that computes the features for all of the images in the
% signalImageArray and the noSignalImageArray
for i = 1:nImages

    % selecting ith image in signalImageArray and squeezing it to be 1 image
    % that is dimxdim
    signalPresentImage = squeeze(signalImageArray(i,:,:));

    % applying three channel features to ith image by taking the inner
    % product of the signal images and the channel image
    features(1) = sum(sum(Channel1_img.*signalPresentImage));
    features(2) = sum(sum(Channel2_img.*signalPresentImage));
    features(3) = sum(sum(Channel3_img.*signalPresentImage));


    % storing the channel features of each image in ith position in
    % signalDataArray
    signalDataArray(i,:)=features;

    % selecting ith image in noSignalImageArray and squeezing it to be 1 image
    % that is dimxdim
    backgroundImage = squeeze(backgroundImageArray(i,:,:));

    % applying three channel features to ith image by taking the inner
    % product of the signal images and the channel image
    features(1) = sum(sum(Channel1_img.*backgroundImage));
    features(2) = sum(sum(Channel2_img.*backgroundImage));
    features(3) = sum(sum(Channel3_img.*backgroundImage));


    % storing the channel features of each image in ith position in
    % backgroundDataArray
    backgroundDataArray(i,:)=features;

end




% calculating covariance matrix of the signalDataArray
channelCovarianceS = cov(signalDataArray);
internalNoiseCovarianceS = zeros(3,3);
for j = 1:3
    internalNoiseCovarianceS(j,j) = noiseConstant*channelCovarianceS(j,j);
end
covarianceSignal = channelCovarianceS + internalNoiseCovarianceS;


% calculating covariance matrix of the backgroundDataArray
channelCovarianceB = cov(backgroundDataArray);
% disp(channelCovarianceB)
internalNoiseCovarianceB = zeros(3,3);
for j = 1:3
    internalNoiseCovarianceB(j,j) = noiseConstant*channelCovarianceB(j,j);
end
% disp(internalNoiseCovarianceB)
covarianceBackground = channelCovarianceB + internalNoiseCovarianceB;
% disp(covarianceBackground)

% difference of the mean of the signalDataArray and the mean of the
% backgroundDataArray
meanSignalImage = mean(signalDataArray)-mean(backgroundDataArray);

Kg = 0.5*covarianceSignal + 0.5*covarianceBackground;
% Multiplying the two covariance matrices by 1/2 then adding them together
% Then taking the inverse of that sum
inverseKg = inv(Kg);
% We check the condition number to see if we need a more numerically
% stable approach than the inverse of the covariance matrix

conditionNumberofKg = cond(Kg);

display(conditionNumberofKg);

% initializing an array of test statistics for each signal and background
% image
testStatsSig = zeros(nImages,1);
testStatsBack = zeros(nImages,1);

% taking the transpose of the signalDataArray
transSignalData = transpose(signalDataArray);

% taking the transpose of the backgroundDataArray
transBackgroundData = transpose(backgroundDataArray);

internalNoiseVarB = zeros(3,1);
internalNoiseVarS = zeros(3,1);
% disp(size(internalNoiseCovarianceB))

for i = 1:3
    internalNoiseVarB(i,1) = internalNoiseCovarianceB(i,i);
    internalNoiseVarS(i,1) = internalNoiseCovarianceS(i,i);
end

% calculating the test statistic for each image and adding internal
% noise
for t = 1:nImages

    % we use a uniform random variable for our internal noise model as is
    % used in previous studies
    testStatsSig(t) = meanSignalImage*inverseKg*(transSignalData(:,t)+sqrt(internalNoiseVarS).*randn(3,1));
    testStatsBack(t) = meanSignalImage*inverseKg*(transBackgroundData(:,t)+sqrt(internalNoiseVarB).*randn(3,1));

end

% initializing matrix A to 0's that will be a label to represent images
% without a signal
A = zeros(nImages,1);

% initializing matrix B to 1's that will be a label that represents images
% with a signal
B = ones(nImages,1);

% The true class labels for the ROC curve are matrix A which consists of 0's
% and matrix B consists of 1's (where zeros represent images with no
% signal and ones represent images with a signal present)
labelsForRoc = [A;B];

% Creating array of test statistics that are the scores for the perfcurve
% function
testStats = [testStatsBack; testStatsSig];

% The label 0 is assigned to the test statistics for the background images
% without the signal and the label 1 is assigned with the test statistics
% for the signal images
scoresForRoc = testStats;

% the function perfcurve returns the area under the curve for the computed
% values of X and Y
% labelsForRoc are arrays of 0's and 1's
% scoresForRoc are arrays testStatsBack and testStatsSig
% the positive class label is equal to 1
[X, Y, T, AUC] = perfcurve(labelsForRoc, scoresForRoc, 1);

% Displaying the AUC
display(AUC);

% saving the entire file the file's name will appear like
% this: typeOfFilter_Date
save(trial_file_name)

end
