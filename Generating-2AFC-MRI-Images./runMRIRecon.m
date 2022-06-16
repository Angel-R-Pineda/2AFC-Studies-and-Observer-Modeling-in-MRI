% Simple script to perform parallel imaging and CS via BART on the fast mri datasets
% SG Lingala, July 2020

% Modified by Angel Pineda
% 6/15/2022

% We clear the variables and plots

clear all;
close all;

%% MC following startup file instructions

% Note that BART is being run in a linux environment

% MC following startup file instructions
addpath(fullfile('/home/apineda/BART/bart-nn_ismrm2021', 'matlab'));
setenv('TOOLBOX_PATH', '/home/apineda/BART/bart-nn_ismrm2021');
% Iowa
% addpath(fullfile(getenv('TOOLBOX_PATH'), 'matlab')); % add BART tool bax path

%% Setting simulation variables
subImageSize = 128; % subImages are 128 by 128
nImages = 200; % number of images to generate
backgroundImages = zeros(subImageSize,subImageSize,nImages);
signalImages = zeros(subImageSize,subImageSize,nImages);

iSubImage = 1; % index for image arrays

radius = 0.25; % disk radius, 0.25 small, 3.5 large
contrast = 0.00005; % signal contrast 5e-5 for small and 2e-5 for large
Nt = 16; % signals are truncated to be zero outside of Nt by Nt square
blurWidth = 1.0; % Standard Deviation of the Gaussian Blur Kernel

gridD = 80; % distance between signals

NSL = 10; % Number of slices per volume to be used

R=4; % Collect every Rth line of readout direction + Calibration Region (16)

lambda_wav = 0.0; % Wavelet regularization parameter
lambda_tv = 0.0;  % TV regularization parameter

% BART command for Recon
bart_cmd = sprintf('pics -R W:6:0:%d -R T:6:0:%d', lambda_wav, lambda_tv);

%% Import File Names
fileNames = importdata('/media/ssd2/fastMRIData/brain_multicoil_validation/Testing_Files_ISMRM2022_All.txt');

% specify the directory path
baseDir = '/media/ssd2/fastMRIData/brain_multicoil_validation/';

for fIndex = 1:length(fileNames)
    % we use the first 25x10x4 to get 1000 2-AFC images,
    % We might end up with more...
    
    if iSubImage <= nImages
        
        %% read the .h5 file
        fileName = char(fileNames(fIndex));
        fname=strcat(baseDir,fileName);
        
        kspace=h5read(fname,'/kspace');
        kspace=kspace.r+1i*kspace.i;   % this is the raw data (row x column x channel x slice )
        rss=h5read(fname,'/reconstruction_rss'); % this is the cropped root sum-of-square of the raw kspace. We will not use this, but is included in the raw data
        s=h5info(fname);% this gives information of all the fields in the file.
        header=h5read(fname,'/ismrmrd_header'); % this is the header
        
        %%
        [nky,nkx,nc,nsl]=size(kspace);
        disp(nc)

        if nky==320 && nkx==640 && nc == 20  % We only volumes with 20 slices
            kspaceVolume = kspace;
            nkxVolume = nkx;
            nkyVolume = nky;
                      
            for sl =1:NSL % We only use NSL=10 to avoid the top of the head images
                
                kspace = kspaceVolume(:,:,:,sl);
                kspace = permute(kspace, [4 2 3 1]);
                kspace = permute(kspace, [1 4 2 3]); % permute such that
                % kspace is of size 1 x nkx x nky x nch
                % format which BART expects
               
                
                
                %% module to create low resoultion images for coil map estimation
                
                sigmaf=4;%sigma for a Gaussian mask to perform low pass filtering n k-space; adjust accordingly.
                %Roughly sigmaf=4 corresponds to using 5% of the center of k-space
                
                lowres_mask=createLPF(nky,nkx,sigmaf);
                
                % imagesc(lowres_mask)
                
                for i = 1:nc
                    kspace_lowres(1,:,:,i)= squeeze(kspace(1,:,:,i)).*lowres_mask;
                end
                
                % create low resolution images for csm estimation
                mc_lowresimgs =  bart('fft -u -i 6', kspace_lowres);
                
                % SOS estimation
                % This is important because we want the real valued 
                % synthetic lesions to reconstruct as real valued

                sens_sos = zeros(size(kspace));
                im_rss_lowres = bart('rss 8',mc_lowresimgs);
                
                for i = 1:nc
                    sens_sos(1,:,:,i) = (mc_lowresimgs(1,:,:,i))./(im_rss_lowres);
                end
                
                sens_maps = sens_sos;
               
                
                %% create a simple undersampling mask and create subsampled k-space data
                
                mask = zeros(1,nky,nkx,nc);
                
                calib_size = 16;
                % calibration region (number of phase encode lines to be fully sampled)
                mask(:,1:R:end,:,:)=1;
                mask(:,nky/2-calib_size/2:nky/2+calib_size/2-1,:,:)=1;
                
                
                %             figure(1)
                %             imagesc(abs(squeeze(mask(1,:,:,1)))); title('sampling mask'); colormap(gray);axis image;
                
                Acceleration=nky/length(find(squeeze(mask(1,:,end/2,1))));
                
                kspace = kspace.*mask; % We apply the undersampling mask
                
                %% l1-regularized reconstruction (Parallel imaging and CS)
                
                recon = bart(bart_cmd, kspace, sens_maps);
                % kspace - input under-sampled zero
                % filled k-space data
                
                % sens_maps - coil sensitivity maps
                
                % recon - output reconstructions
                
                % -R W:6:0:%d Wavelet
                % regularization along the (1,2)
                % dimensions with user defined regularization parameter
                % Note that (6=2^1+2^2) indicates
                % the bitmask to specify the
                % dimensions for regularization.
                
                % -R T:6:0:%d Total variation
                % regularization along the (1,2)
                % dimensions with user defined regularization parameter
                % Note that (6=2^1+2^2) indicates
                % the bitmask to specify the
                % dimensions for regularization.
                reconWithoutSignal = squeeze(recon);
                
                
                %% Results
                
                
                % We reshape (squeeze) the images to be 2D
                recon = squeeze(recon(1,:,:));
                
                
                %% We create the image signal data
                
                xLocArray = [nkx/2-gridD/2 nkx/2+gridD/2]; % 2 by 2 grid of signals per slice
                yLocArray = [nky/2-gridD/2 nky/2+gridD/2];
                
                for xI = 1:length(xLocArray)
                    
                    xLoc = xLocArray(xI); % row location
                    
                    for yI = 1:length(yLocArray)
                        
                        % We generate the signal
                        yLoc = yLocArray(yI); % column location
                        
                        signal = generateSignal(yLoc,xLoc,radius,blurWidth,nky,nkx,Nt);
                        % We re-scale the signals for the desired contrast since it is
                        % added to the background
                        
                        signal = contrast * signal/(max(max(signal)));
                        
                        %Create k-space coil data for signals and add to brain k-space
                        
               
                        signalImageSpace = zeros(size(kspace));
                        
                        for i = 1:nc
                            signalImageSpace(1,:,:,i)= reshape(sens_maps(1,:,:,i),nky,nkx).*signal;
                        end
                        
                        signalKspace = bart('fft -u 6', signalImageSpace); % note 6 indicates bit mask
                        
                        % We apply the sampling mask to the signal Kspace
                        signalKspace = mask .* signalKspace;
                        
                        kspaceWithSignal = kspace + signalKspace;
                        
                        %  Reconstruct background with signals
                        
                        reconWithSignal= bart(bart_cmd, kspaceWithSignal, sens_maps);
                        reconWithSignal = squeeze(reconWithSignal);
                        
                        sampleSignalImage = reconWithSignal(yLoc-subImageSize/2:yLoc+subImageSize/2-1,...
                            xLoc-subImageSize/2:xLoc+subImageSize/2-1);
                        signalImages(:,:,iSubImage) = squeeze(abs(sampleSignalImage));
                        
                        sampleBackgroundImage = reconWithoutSignal(yLoc-subImageSize/2:yLoc+subImageSize/2-1,...
                            xLoc-subImageSize/2:xLoc+subImageSize/2-1);
                        backgroundImages(:,:,iSubImage) = squeeze(abs(sampleBackgroundImage));
                        
                        iSubImage = iSubImage + 1;
                        disp(iSubImage)
                        
                    end
                end
                
            end
            
        end
    end
end

% Visualize Sample 2-AFC

sampleSignal = signal(yLoc-subImageSize/2:yLoc+subImageSize/2-1,...
             xLoc-subImageSize/2:xLoc+subImageSize/2-1);
figure(1)
subplot(1,3,1)
imagesc(squeeze(abs(sampleSignalImage))); colormap(gray); axis image; axis off;
subplot(1,3,2)
imagesc(sampleSignal); colormap(gray); axis image; axis off;
subplot(1,3,3)
imagesc(squeeze(abs(sampleBackgroundImage))); colormap(gray); axis image; axis off;

% reformat images for 2-AFC studies

signalImage = sampleSignal;
signalImageArray = zeros(nImages,subImageSize,subImageSize);
backgroundImageArray = zeros(nImages,subImageSize,subImageSize);

for i=1:nImages
    backgroundImageArray(i,:,:) = reshape(backgroundImages(:,:,i),subImageSize,subImageSize);
    signalImageArray(i,:,:) = reshape(signalImages(:,:,i),subImageSize,subImageSize);
end

% save Sample2AFCImages.mat signalImage signalImageArray backgroundImageArray Acceleration contrast lambda_tv lambda_wav radius fname