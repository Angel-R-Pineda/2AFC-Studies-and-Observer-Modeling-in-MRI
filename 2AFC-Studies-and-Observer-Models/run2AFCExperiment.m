% Written by: Alexandra O'Neill and Emely Valdez
% Date: 7/28/20
% Modified by: Angel Pineda
% Date: 6/14/22

% This file is meant to run each 2-AFC trial and the variables
% will be saved in a new file named "yourNametrialType_trialNumber"

% This script prompts the user to enter their name, file name of the image 
% set (without the *.mat extension), and the number of images that 
% will be displayed in the trial.

% We clear the workspace before beginning
clear

% dialog box is shown to the user, prompting the user to enter their name
userName = inputdlg('Enter username (e.g. "Observer1")');

% the character array is converted to a stringarray
userName = convertCharsToStrings(userName);

% dialog box is shown to the user, prompting the user to enter the file name

trialType = inputdlg('Enter the file name (without extension) e.g. "Sample2AFCImages"');

% the character arrays in x are converted to stringarrays
trialType = convertCharsToStrings(trialType);

% dialog box is shown to the user, prompting the user to enter the number
% of images pairs (2-AFC trials)

nImages = inputdlg('Enter the number of images in this trial');

% the string scalar stored in y is converted to a double precision value
nImages = str2double(nImages);

% dialog box is shown to the user, prompting the user to enter the trial
% number of the particular image set they are working with
% This is used in training when there are repeated trials
trialNumber = inputdlg('Enter the number of times you have done this image set  (ex. 1st time using this image set, enter the word "one")');
trialNumber = convertCharsToStrings(trialNumber);


pixelFactor = 1;
% changes the size of individual pixels to magnify images based on the
% user's monitor pixel size.  This is used if multiple monitors are used in
% a study.

% The output will be the percentage of images that the user
% correctly identified as containing the signal. Additionally, we store 
% the trial as a new file with all of the variables from the trial including 
% the array of times in between selected images, the images that were 
% selected correctly or incorrectly as having or not having the signal, 
% and the array of the user's click coordinates for potential future use.

% We start by uploading the images

% horizontally concatenates the character vectors trialType(name of the file) 
% and .mat then returns the new character vector to dataFileName
dataFileName = strcat(trialType,'.mat');

% load variables from the .mat file that contains the image arrays 
% into the workspace
load(dataFileName);

% creates the name of the file that will be saved for the individual run of 2AFC 
trial_File_Name = strcat(userName, trialType,trialNumber);

% initializing variable, will represent the sum of correct answers 
% in the experiment
correctResponsesTotal = 0;

% totalNumImages = numberOfImages, dimR = dimension of rows of individual
% images, dimC = dimension of columns of individual images
[totalNumImages, dimR, dimC] = size(signalImageArray);

% assuming that the images are square
dimension = dimR;

% initializes array to be filled with the times of each trial
timeOfTrialsArray = zeros(1, nImages);

% creating a 1 x nimages array of all zeros for the variables truPositive,
% trueNegative, falsePositive, and falseNegative

% array of images that the user correctly selected as having signal
truePositive = zeros(1,nImages);

% array of images that the user correctly selected as not having signal
trueNegative = zeros(1,nImages);

% array of images that the user incorrectly selected as having signal
falsePositive= zeros(1,nImages);

% array of images that the user incorrectly selected as not having signal
falseNegative = zeros(1,nImages);

order = 1:totalNumImages;
% creating an array to randomize the order of the images

% randperm returns a row vector of a random permutation of the integers 1
% to totalNumImages so that the images appear in a random order and no
% image will be displayed more than once per trial
randomOrderForNoise =  order(randperm(totalNumImages));
randomOrderForSignal = order(randperm(totalNumImages));

% initializing an array of the x and y coordinates for the images
coordinateArray = zeros(nImages,2);
    
% We loop over the number of 2AFC trials (nImages)
for j = 1:nImages 
    
    % Below code selects the no signal image corresponding to the jth index 
    % from randomOrderForNoise, and squeezes it to be one 2D image
    sampleBackgroundImage = squeeze(backgroundImageArray(randomOrderForNoise(j),:,:)); 
 
    % Below code selects the no signal image corresponding to the jth index
    % and squeezes it to be one 2D image 
    sampleSignalImage = squeeze(signalImageArray(randomOrderForSignal(j),:,:));
    
    
    % calls the function run2AFC which prompts the user to select
    % an image and stores the coordinates of the user's click, if the user 
    % chooses the image with a signal, jthAnswer = 1. If the user chooses the
    % image without a signal, jthAnswer = 0
    % function returns the jthAnswer and jthCoordinates
    [jthAnswer, jthCoordinates] = twoAFC(dimension,sampleSignalImage,sampleBackgroundImage,signalImage,pixelFactor);
    
    % assigning jthCoordinates to the the jth row of the coordinateArray
    coordinateArray(j,:) = jthCoordinates;
    
    % assigning the time of the jth trial into the jth position in 
    % timeOfTrialsArray
    timeOfTrialsArray(j) =  toc;
   
    % Updates total number of correct responses variable by adding the 
    % jth answer (either 0 or 1) to the total number of correct responses    
    correctResponsesTotal = correctResponsesTotal + jthAnswer;
    
    % The below code records the image indices of true positive,
    % true negative, false positive, and false negative which results in
    % correspondingly named arrays
    
    %if user correctly selected image with signal
    if jthAnswer == 1
        
        % the jth entry of the  truePositive array is filled w/ the image # 
        % from array randomOrderForSignal that was displayed in the jth trial
        truePositive(j) = randomOrderForSignal(j);
        
        % the jth entry of the  trueNegative array is filled w/ the image # 
        % from array randomOrderForNoise that was displayed in the jth trial  
        trueNegative(j) = randomOrderForNoise(j);
        
    %if user incorrectly selected image with signal
    else
        
        % the jth entry of the  falsePositive array is filled w/ the image # 
        % from array noiseArrayRandOrder that was displayed in the jth trial 
        falsePositive(j) = randomOrderForSignal(j);
        
        % the jth entry of the  falseNegative array is filled w/ the image # 
        % from array randomOrderForNoise that was displayed in the jth trial  
        falseNegative(j) = randomOrderForNoise(j);
    end 
end

% calculates the number of correct responses out of the number possible 
% to get correctly
percentageCorrect = (sum(correctResponsesTotal)/nImages)*100; 

% displays the individual user's percentage correct
display(percentageCorrect) 

% saves entire workspace to a file
save(trial_File_Name)
