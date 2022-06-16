% Written by: Angel Pineda
% Date: 6/15/22

% This script calls the SDOG3 function to evaluate the S-DOG Model Observer
% for a set of images with and without the signal.  The S-DOG observer with
% three channels comes from Abbey, et. al.
% https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2943344/

% Parameters for S-DOG channels
q = 2;
alpha = 2;
sig_0 = 0.015;
noiseConst = 0.005;

AUC = SDOG3('Sample2AFCImages', q, alpha, sig_0, noiseConst);
% AUC = 0.9424