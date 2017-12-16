% This Script shows an example of an working basic Active Shape Model,
% with a few hand pictures.
%
% Literature used: Ginneken B. et al. "Active Shape Model Segmentation 
% with Optimal Features", IEEE Transactions on Medical Imaging 2002.
%
% Functions are written by D.Kroon University of Twente (February 2010)
clear all; clc; close all;
% Add functions path to matlab search path
functionname='ASM_2D_example.m'; functiondir=which(functionname);
functiondir=functiondir(1:end-length(functionname));
addpath([functiondir 'Functions'])
addpath([functiondir 'ASM Functions'])
addpath([functiondir 'InterpFast_version1'])

% Try to compile c-files
cd([functiondir 'InterpFast_version1'])
try
    mex('interp2fast_double.c','image_interpolation.c');
catch ME
    disp('compile c-files failed: example will be slow');
end
cd(functiondir);


%% Set options
% Number of contour points interpolated between the major landmarks.
options.ni=20;
% Length of landmark intensity profile
options.k = 8; 
% Search length (in pixels) for optimal contourpoint position, 
% in both normal directions of the contourpoint.
options.ns=6;
% Number of image resolution scales
options.nscales=2;
% Set normal contour, limit to +- m*sqrt( eigenvalue )
options.m=3;
% Number of search itterations
options.nsearch=40;
% If verbose is true all debug images will be shown.
options.verbose=true;
% The original minimal Mahanobis distance using edge gradient (true)
% or new minimal PCA parameters using the intensities. (false)
options.originalsearch=false;  

%% Load training data
% First Load the Hand Training DataSets (Contour and Image)
% The LoadDataSetNiceContour, not only reads the contour points, but 
% also resamples them to get a nice uniform spacing, between the important
% landmark contour points.
TrainingData=struct;
for i=1:10
    is=num2str(i); number = '000'; number(end-length(is)+1:end)=is; 
  %  filename=['..\images2D\contour' number '.mat'];
    %load(filename);
    filename=['Fotos/train' number '.jpg'];
    I=im2double(imread(filename));  
    filename=['Fotos/train' number '.mat'];

    [Vertices,Lines]=LoadDataSetNiceContour(filename,options.ni,options.verbose);
    if(options.verbose)
        t=mod(i-1,4); if(t==0), figure; end
        subplot(2,2,t+1), imshow(I); hold on;
        P1=Vertices(Lines(:,1),:); P2=Vertices(Lines(:,2),:);
        plot([P1(:,2) P2(:,2)]',[P1(:,1) P2(:,1)]','b');
        drawnow;
    end
    TrainingData(i).Vertices=Vertices;
    TrainingData(i).Lines=Lines;
	TrainingData(i).I=I;
end

%% Shape Model %%
% Make the Shape model, which finds the variations between contours
% in the training data sets. And makes a PCA model describing normal
% contours
[ShapeData TrainingData]= ASM_MakeShapeModel2D(TrainingData);
  
% Show some eigenvector variations
if(options.verbose)
    figure,
    for i=1:min(6,length(ShapeData.Evalues))
        xtest = ShapeData.x_mean + ShapeData.Evectors(:,i)*sqrt(ShapeData.Evalues(i))*3;
        subplot(2,3,i), hold on;
        plot(xtest(end/2+1:end),xtest(1:end/2),'r.');
        plot(ShapeData.x_mean(end/2+1:end),ShapeData.x_mean(1:end/2),'b.');
    end
    drawnow;
end

    
%% Appearance model %%
% Make the Appearance model, which samples a intensity pixel profile/line 
% perpendicular to each contourpoint in each trainingdataset. Which is 
% used to build correlation matrices for each landmark. Which are used
% in the optimization step, to find the best fit.
AppearanceData = ASM_MakeAppearanceModel2D(TrainingData,options);

%% Test the ASM model %%
Itest=im2double(imread('Fotos/test001.jpg'));

% Initial position offset and rotation, of the initial/mean contour
tform.offsetv=[0 0]; tform.offsetr=-0.3; tform.offsets=117;
pos=[ShapeData.x_mean(1:end/2) ShapeData.x_mean(end/2+1:end)];
pos=ASM_align_data_inverse2D(pos,tform);

% Select the best starting position with the mouse
[x,y]=SelectPosition(Itest,pos(:,1),pos(:,2));
tform.offsetv=[-x -y];

% Apply the ASM model onm the test image
ASM_ApplyModel2D(Itest,tform,ShapeData,AppearanceData,options);


