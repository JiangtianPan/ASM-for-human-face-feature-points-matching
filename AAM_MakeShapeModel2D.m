function [ShapeData TrainingData]= AAM_MakeShapeModel2D(TrainingData,options)

% Number of datasets
s=length(TrainingData);

% Number of landmarks
nl = size(TrainingData(1).Vertices,1);

%% Shape model

% Remove rotation and translation and scale : Procrustes analysis 
MeanVertices=TrainingData(1).Vertices;
AllVertices=zeros([size(MeanVertices) s]);
Alloffsetv=zeros([2 s]);
Alloffsetsx=zeros([1 s]);
Alloffsetsy=zeros([1 s]);
for k=1:2
    for i=1:s
        [TrainingData(i).CVertices, TrainingData(i).tform]=AAM_align_data2D(TrainingData(i).Vertices,MeanVertices);
        AllVertices(:,:,i)=TrainingData(i).CVertices;
        Alloffsetv(:,i)=TrainingData(i).tform.offsetv;
        Alloffsetsx(:,i)=TrainingData(i).tform.offsetsx;
        Alloffsetsy(:,i)=TrainingData(i).tform.offsetsy;
    end
    tform=struct;
    tform.offsetv=mean(Alloffsetv,2)';
    tform.offsetsx=mean(Alloffsetsx,2);
    tform.offsetsy=mean(Alloffsetsy,2);
    CVertices=mean(AllVertices,3);
    MeanVertices=AAM_align_data_inverse2D(CVertices,tform);
end
for i=1:s
    [TrainingData(i).CVertices, TrainingData(i).tform]=AAM_align_data2D(TrainingData(i).Vertices,MeanVertices);
end


% Construct a matrix with all contour point data of the training data set
x=zeros(nl*2,s);
for i=1:length(TrainingData)
    x(:,i)=[TrainingData(i).CVertices(:,1)' TrainingData(i).CVertices(:,2)']';
end
[Evalues, Evectors, x_mean]=PCA(x);

% Keep only 98% of all eigen vectors, (remove contour noise)
i=find(cumsum(Evalues)>sum(Evalues)*0.99,1,'first'); 
Evectors=Evectors(:,1:i);
Evalues=Evalues(1:i);

% Calculate variances in rotation and scale
r=zeros(nl,1); s=zeros(nl,1);
for i=1:length(TrainingData)
    r(i)=TrainingData(i).tform.offsetr;
    s(i)=TrainingData(i).tform.offsets;
end
varr=var(r); 
vars=var(s);


% Store the Eigen Vectors and Eigen Values
ShapeData.Evectors=Evectors;
ShapeData.Evalues=Evalues;
ShapeData.x_mean=x_mean;
ShapeData.x = x;
ShapeData.SVariance = vars;
ShapeData.RVariance = varr;
ShapeData.MeanVertices = MeanVertices;
ShapeData.Lines = TrainingData(1).Lines;
ts=ceil(max(max(ShapeData.x_mean(:)),-min(ShapeData.x_mean(:)))*2*options.texturesize);
ShapeData.TextureSize=[ts ts];
ShapeData.Tri= delaunay(x_mean(1:end/2),x_mean(end/2+1:end));





