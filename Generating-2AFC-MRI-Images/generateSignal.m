function signalBlurredTruncated = generateSignal(r0,c0,radius,blurWidth,Nx,Ny,Nt)
% This function generates a blurred disk with radius (radius)
% (r0,c0) where the center is the signal in the row r0 and column
% location and blurrred with a Gaussian with standard deviation blurWidth in units
% of pixels.  The resulting image is NxN.  The resulting blurred signal is
% truncated to be zero outside of a square Nt x Nt pixels. Nt needs to be
% divisible by 2.

% Written by Angel Pineda
% Last Modification Date: 6/15/2022

% We initialize the matrix
signal = zeros(Nx,Ny);

% We initialize the blur
blur = zeros(Nx,Ny);

% We cread the blurring function
for i=1:Nx
    for j=1:Ny
        d = sqrt((i-Nx/2)^2 + (j-Ny/2)^2);
        blur(i,j) = (1/(blurWidth*sqrt(2*pi))) * exp(-d^2/(2*blurWidth^2));
    end    
end

blur = blur / sum(sum(blur));

% We add the signal
for i=1:Nx
    for j=1:Ny
        d = sqrt((i-r0)^2 + (j-c0)^2);
        if d <= radius
            signal(i,j) = 1;
        end
    end    
end

% We blur the signal
blurredSignal = conv2(signal,blur);
% We extract the convolved signal so that it is centered at r0,c0
% for N divisible by 2
blurredSignal = blurredSignal(Nx/2:(3*Nx/2-1),Ny/2:(3*Ny/2-1));
% The signal is truncated to be 16 vy 16 pixels.
signalBlurredTruncated = zeros(Nx,Ny);
signalBlurredTruncated(r0-Nt/2-1:r0+Nt/2,c0-Nt/2-1:c0+Nt/2)=blurredSignal(r0-Nt/2-1:r0+Nt/2,c0-Nt/2-1:c0+Nt/2);