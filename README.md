# 2AFC-Studies-and-Observer-Modeling-in-MRI

This repository contains code used in a paper published in the SPIE Journal of Medical Imaging:

AG O'Neill, EL Valdez, SG Lingala, and AR Pineda, "Modeling human observer detection in undersampled magnetic resonance imaging (MRI) with total variation and wavelet sparsity regularization", Journal of Medical Imaging, 10(1) 015502 (25 February 2023).

## 2AFC studies and Observer Models

The code in the 2-AFC-and-Observer-Models Folder runs a 2-AFC study. 

In a two alternative forced choice (2AFC) experiment, one attempts to detect a signal in one of two images presented to you. The 2AFC experiment estimates the percent correct in detecting the signal.  The sparse difference-of-Gaussians (SDOG) model observer uses channels inspired by the visual system to estimate human performance in the detection task.  There are four MATLAB function or script files in the folder and one sample set of 2AFC images.

run2AFCExperiment.m:
This script file is the only file you will actually run in MATLAB. Once running, you will enter your name, the image file name (WITHOUT ".mat"), the number of images you want to run in the trial (integer enter), and the trial number of the image set. Most of this information is used to store the data.  The output of this script is a file containing the percentage of images that the user correctly identified as containing the signal (percent correct), the array of images that the user identified correctly and incorrectly as having or not having the signal and they are labeled as such: truePositive, trueNegative, falsePositive, falseNegative.  This script calls the twoAFC.m function.

twoAFC.m:
The inputs to this function are the dimension of the images in the array, an array of images with the signal present, an array of images without the signal present, an image of the isolated signal itself and the scaling for the image (pixel factor). The output is whether the human observer chose correctly and the coordinates of where they clicked.

runSOG3.m:
This script sets the parameters of the SDOG model and calls the SDOG3.m function to compute the area under the ROC (AUC) for the SDOG.  The SDOG observer models human perfomance in a dectection task using three channels in the frequency domain inspired by the human visual system.  The SDOG model used in this work comes from Abbey, et. al.
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2943344/  

SDOG3.m:
This function has the image array and the parameters of the SDOG model as input and outputs the AUC.

Sample2AFCIImages.mat:
This data file contains a sample set of 40 images generated from the fastMRIdata raw data of FLAIR images:
https://github.com/facebookresearch/fastMRI
The data file has the parameters for the reconstruction along with the signal image, forty 128x128 images with the signal in the center and forty 128x128 images with just the background. 

Directions:

To run the 2-AFC observer study, simply run "run2AFCExperiment.m" in a folder with the supporting files.

Once you run the script and enter the necessary information as explained above, a figure window will appear with 3 images, one containing the signal, one not containing the signal, and one of the isolated signal itself. Your job is to click on the image (left or right) that you believe the signal is in. After each click, whether you got it correct or incorrect will appear in the command window. After you have completed all nImages trials, your percentage selected correctly will appear as the output.  The output will be saved as separate files called ‘userName_trialType_trialNumber’ for future reference and analysis.

To run the model observer code to estimate the AUC from the image file, simply run "runSDOG3.m" in a folder with the supporting files.

Once you run this code it will prodice an estimate of the AUC for the SDOG model observer for the 2-AFC images.

## Generating the Images for the 2AFC Study

The code in the Generating-2AFC-MRI-Images generates the 2-AFC images.

The code adds a signal to the raw k-space data and uses the BART reconstruction toolbox for constrained reconstruction:
https://github.com/mrirecon/bart

There are three MATLAB scripts and functions:

runMRIRecon.m:
This script file is the only file you will actually run in Matlab. The script has several parameters that need to be set (e.g. regularization parameters, level of undersampling, etc.) and returns the image file used in the observer modeling.  The current parameters generate the "Sample2AFCIImages.mat".

createLPF.m:
This function creates a Gaussian Low Pass Filter.

generateSignal.m:
This function creates the signal which is being detected in the study.
