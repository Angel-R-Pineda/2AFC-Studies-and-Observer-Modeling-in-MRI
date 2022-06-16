function [answerValue,coordinates] = twoAFC(dim, ...
    signalPresentImage,backgroundImage,signalItself,pixelFactor)

% Written by: Alexandra O'Neill & Emely Valdez
% Date: 7/28/20
% Modified by: Alexandra O'Neill
% Date: 9/24/20
% Modified by: Angel Pineda
% Date: 6/14/22

% This function performs a simple 2AFC experiment with the image in signalPresentImage,
% and backgroundImage. SignalPresentImage and backgroundImage are both
% (dim * dim). The variable 'signalItself'
% contains a picture of the signal one is trying to detect.

% This routine will bring three images: the center image contains the
% signal, and the user must choose which of the left or right images
% contains the signal by clicking either on the left or right image.

% The inputs to this function are the dimension of the images in the array,
% an array of images with a signal present, an array of images without a
% signal present, and an image of the isolated signal.

% The output of this function is whether the user correctly chose the image
% with the signal.

% Note: Ideally, 2AFC experiments are done under very controlled conditions
% such as lighting, distance to monitor, gray-levels, etc.

% initializing the value of answerValue as 0, it will remain 0 if incorrect
% or change to 1 if the user answers correctly
answerValue = 0;

% Dividing the images by their maximum pixel value normalizes them to the
% same scale. This allows the images to concatenated into one image array
% without affecting the display of the individual images.

% max(max(signalItself)) returns the max pixel value of the coordinates
% image signalItself to signalMax
signalMax = max(max(signalItself));


% dividing the coordinates image signalItself by the max pixel value signalMax
signalItself = signalItself/signalMax;

% creates an array that is nImages by 2 coordinates of zeros
coordinates = zeros(1,2);

% max(max(signalImage))returns the max pixel value of the array signal as
% signalMax
signalPresentMax = max(max(signalPresentImage));
% dividing the array signal by the max pixel value signalPresentMax
signalPresentImage = signalPresentImage/signalPresentMax;

% max(max(background)) returns the max pixel value of the array background to
% backgroundMax
backgroundMax = max(max(backgroundImage));
% dividing the array signal by the max pixel value backgroundMax
backgroundImage = backgroundImage/backgroundMax;

% In the psychophysical study sometimes the image with the signal is
% going to be to the right and sometimes it will be to the left

% concatenating 3 image arrays to be 1 image array

% signalImage is on the left
signalLeft = [signalPresentImage signalItself backgroundImage];

% signalImage is on the right
signalRight = [backgroundImage signalItself signalPresentImage];

% So, flip = rand; picks a random # between 0 and 1
flip = rand;

% if random # is greater than 0.5 then it flips the images so it displays
% image array signalLeft
if (flip >= 0.5)
    % signalImage is on left and backgroundImage is on right

    % minimum pixel value in signalLeft
    minSignalLeft = min(min(signalLeft));
    % maximum pixel value in signalLeft
    maxSignalLeft = max(max(signalLeft));
    % imshow displays image based on range of pixel values of the image signalLeft
    imshow(signalLeft,'DisplayRange',[minSignalLeft maxSignalLeft],'InitialMagnification','fit')
    % pixelFactor is the multiplicative value chosen to magnify the pixels
    % of the images displayed. This is done with the truesize command by
    % multiplying trueSize with the size(signalLeft) (which is the # of pixels in
    % the x and y direction)
    truesize(pixelFactor*size(signalLeft))



    % if random # is less than 0.5 then it doesn't flip the images so it
    % displays image array signalRight
else
    % minimum pixel value in signalRight
    minSignalRight = min(min(signalRight));
    % maximum pixel value in signalRight
    maxSignalRight = max(max(signalRight));
    % imshow displays image based on range of pixel values of the image
    % signalRight
    imshow(signalRight,'DisplayRange',[minSignalRight maxSignalRight]','InitialMagnification','fit')
    % pixelFactor is the multiplicative value chosen to magnify the pixels
    % of the images displayed. This is done with the truesize command by
    % multiplying trueSize with the size(signalRight) (which is the # of pixels in
    % the x and y direction)
    truesize(pixelFactor*size(signalRight))

end


% tic function records the current time
tic

% identifying the axes coordinates for the user's click
% coordinates(i, 1) = x coordinate for the ith image
% coordinates(i, 2) = y coordinate for the ith image
[coordinates(1,1), coordinates(1,2)] = ginput(1);


% first condition: the user clicks on the left image, the variable
% imageSelection = 0 if this occurs
if ((((0 <= coordinates(1,1)) && (coordinates(1,1) <= dim))) && ...
        (((0 <= coordinates(1,2)) && (coordinates(1,2) <= dim))))
    imageSelection = 0;

    % reads the elasped time since the stopwatch timer started by the
    % call to the tic function
    toc

    % second condition: the user clicks on the right image, the
    % variable imageSelection = 1 if this occurs
elseif ((((dim*2 <= coordinates(1,1)) && (coordinates(1,1) <= dim*3))) ...
        && (((0 <= coordinates(1,2)) && (coordinates(1,2) <= dim))) )
    imageSelection = 1;
    toc

    % if the user clicks outside of the right or left image, imageSelection = -1
else
    disp('Invalid selection');
    imageSelection = -1;

end

% if the selection is invalid, it will keep prompting the user to try
% again until a valid selection is made
while (imageSelection == -1)
    disp('Please try again. Select the right or left image')

    % repeats the above code for the selection made after the user chose
    % an invalid selection
    tic
    [coordinates(1,1), coordinates(1,2)] = ginput(1);

    if ((((0 <= coordinates(1,1)) && (coordinates(1,1) <= dim))) && ...
            (((0 <= coordinates(1,2)) && (coordinates(1,2) <= dim))))
        imageSelection = 0;
        toc
    elseif ((((dim*2 <= coordinates(1,1)) && (coordinates(1,1) <= dim*3))) ...
            && (((0 <= coordinates(1,2)) && (coordinates(1,2) <= dim))) )
        imageSelection = 1;
        toc
    else
        disp('Invalid selection');
        imageSelection = -1;
    end


end


% if left image is selected and flip >= 0.5, then the user is correct
% or
% if right image is selected and flip < 0.5, then the user is correct
if ( ( (imageSelection == 0) && (flip >= 0.5) ) || ...
        ((imageSelection == 1) && (flip < 0.5)) )

    % gives feedback of "correct" after correct selection of image with signal
    fprintf('Correct\n');

    % adding 1 to the fraction of the images that the user got correct
    answerValue = 1;

else
    % gives feedback of "incorrect" after incorrect selection of image without
    % signal
    fprintf('Incorrect\n');

end


%end

% deletes the current figure
close;
