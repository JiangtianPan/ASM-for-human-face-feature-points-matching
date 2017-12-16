function [Vertices,tform]=AAM_align_data2D(Vertices,VerticesB)
% Remove rotation and translation and scale : Procrustes analysis 

% Center data to remove translation 
offsetv = -mean(Vertices,1);
Vertices(:,1) = Vertices(:,1) + offsetv(1);
Vertices(:,2) = Vertices(:,2) + offsetv(2);

offsetvB = -mean(VerticesB,1);
VerticesB(:,1) = VerticesB(:,1) + offsetvB(1);
VerticesB(:,2) = VerticesB(:,2) + offsetvB(2);

%  Set scaling to base example
d = mean(sqrt(Vertices(:,1).^2 + Vertices(:,2).^2));
db = mean(sqrt(VerticesB(:,1).^2 + VerticesB(:,2).^2));
offsets=(db/d);
Vertices = Vertices *offsets;

% Correct for rotation
% Calculate angle to center of all points
rot = atan2(Vertices(:,2),Vertices(:,1));
rotb = atan2(VerticesB(:,2),VerticesB(:,1));

% Subtract the mean angle
offsetr=-mean(rot-rotb);
rot = rot+offsetr;

% Make the new points, which all have the same rotation
dist = sqrt(Vertices(:,1).^2+Vertices(:,2).^2);
Vertices(:,1) =dist.*cos(rot);
Vertices(:,2) =dist.*sin(rot);

% Store transformation object
tform.offsetv=offsetv;
tform.offsetr=offsetr;
tform.offsets=offsets;
tform.offsetsx=offsets*cos(offsetr);
tform.offsetsy=offsets*sin(offsetr);
