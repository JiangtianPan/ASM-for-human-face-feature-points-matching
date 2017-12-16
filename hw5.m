%% HW5 - Detect 2D keypoints and do procrustes alignment

clear all; clc; close all;
% Add functions path to matlab search path
functionname='hw5.m'; functiondir=which(functionname);
functiondir=functiondir(1:end-length(functionname));
addpath([functiondir 'Functions'])
addpath([functiondir 'ASM Functions'])
addpath([functiondir 'InterpFast_version1'])

%% 1. Read all images in the ./database/trainImages directory
files = dir(fullfile('./database/trainImages/','*.jpg'));
lengthFiles = length(files);
mats = dir(fullfile('./database/markings/','*.mat'));
% differentiate trained files from test files
lengthTrainedFiles = floor(lengthFiles /100);
lengthTestFiles = lengthFiles-lengthTrainedFiles;

%% 2. Set options
% Number of contour points interpolated between the major landmarks.
options.ni=10;
% Length of landmark intensity profile
options.k = 10; 
% Search length (in pixels) for optimal contourpoint position, 
% in both normal directions of the contourpoint.
options.ns=6;
% Number of image resolution scales
options.nscales=2;
% Set normal contour, limit to +- m*sqrt( eigenvalue )
options.m=3;
% Number of search itterations
options.nsearch=100;
% If verbose is true all debug images will be shown.
options.verbose=false;
% The original minimal Mahanobis distance using edge gradient (true)
% or new minimal PCA parameters using the intensities. (false)
options.originalsearch=false;  

%% 3. Use trained landmarks on the images and fill the training data
images=cell(1,lengthTrainedFiles);
landmarks=cell(1,lengthTrainedFiles);
TrainingData=struct;

for i = 1:1+lengthTrainedFiles
    Img = im2double(rgb2gray(imread(strcat('./database/trainImages/',files(i*3).name))));    %429*472
    marks = importdata(strcat('./database/markings/',mats(i*3).name));
    images{i}=Img;
    landmarks{i}=marks;
    p=struct;
    [row,col]=size(marks);
    p.x=marks(1:row,2)';
    p.y=marks(1:row,1)';
    p.I=Img;
    p.n=row;
    p.t=zeros(1,p.n);

    [Vertices,Lines]=MyLoadDataSetNiceContour(p,options.ni,options.verbose);
    
%     if(options.verbose)
%         t=mod(i-1,4); if(t==0), figure(i+1); end
%         subplot(2,2,t+1), imshow(Img); hold on;%close(figure(i));
%         P1=Vertices(Lines(:,1),:); P2=Vertices(Lines(:,2),:);
%         plot([P1(:,2) P2(:,2)]',[P1(:,1) P2(:,1)]','b');
%         drawnow;
%     end
    TrainingData(i).Vertices=Vertices;
    TrainingData(i).Lines=Lines;
	TrainingData(i).I=Img;
end
%% 4. Shape Model %%
% Make the Shape model, which finds the variations between contours
% in the training data sets. And makes a PCA model describing normal
% contours
[ShapeData,TrainingData,MeanVertices]= ASM_MakeShapeModel2D(TrainingData);
  
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

    
%% 5. Appearance model %%
% Make the Appearance model, which samples an intensity pixel profile/line 
% perpendicular to each contourpoint in each trainingdataset. Which is 
% used to build correlation matrices for each landmark. Which are used
% in the optimization step, to find the best fit.
AppearanceData = ASM_MakeAppearanceModel2D(TrainingData,options);

%% 6. Test the ASM model %%

% Itest=im2double(rgb2gray(imread(strcat('./database/trainImages/',files(230).name))));
Itest=im2double(rgb2gray(imread('./database/trainImages/01_110_2527.jpg')));

% Initial position offset and rotation, of the initial/mean contour
tform.offsetv=[0 0]; tform.offsetr=0; tform.offsets=0;
pos=[ShapeData.x_mean(1:end/2) ShapeData.x_mean(end/2+1:end)];
pos=ASM_align_data_inverse2D(pos,tform);

% Select the best starting position with the mouse
[x,y]=SelectPosition(Itest,pos(:,1),pos(:,2));
tform.offsetv=[-x -y];

% Apply the ASM model onm the test image
ASM_ApplyModel2D(Itest,tform,ShapeData,AppearanceData,options);
plot(MeanVertices(:,2),-MeanVertices(:,1));

% A. Appendix : Test Code
% figure(1);
% [matR,matC]=size(landmarks{1});
% imshow(images{1});
% hold on;
% for i=1:matR
%    X=landmarks{1}(i,1);
%    Y=landmarks{1}(i,2);
%    h=plot(X,Y,'.'); 
%    set(h,'Linewidth',3);
%    hold on;
% end