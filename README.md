# ASM-for-human-face-feature-points-matching

Introduction
Task: By using Active Shape Model (ASM) algorithm combine with PCA approach to train a regressor that can be used to detect key-points of a test human face picture. Then, Procrustes Analysis is done for matching the reconstructed key-points of those images;	
Environment: Matlab 2016a version, ASM package;

Main Procedure
1, Image Processing and Parameter setting
  Load all the images into Matlab and set them as training images and testing images. Then transfer the RGB images into Gray degree, by using function rgb2gray( ), imread( ).
  Set parameters for the later code by constructing a structure “options”. For examples, we set the counter points between two key-points as 10, number of search iteration as 100.
2, Use trained key-points on the images and fill the training data
[Vertices,Lines]=LoadDataSetNiceContour( ); 
  By using these Matlab functions, we can obtain the vertices and lines of all the training images. This function is from the supported package. 
3, Make the Shape model
[ShapeData,TrainingData,MeanVertices]= ASM_MakeShapeModel2D( );
[TrainingData(i).CVertices, TrainingData(i).tform]=AAM_align_data2D ( );
  By using the two functions above, we can make the Shape model, which finds the variations between contours in the training data sets. In these functions, we can calculate the mean vertice of each counter points, and then calculate the distance between each vertice in the training data and the mean vertice. By using formulation “M(s,θ)[X]−t”, we can calculate the rotation matrix and the translation matrix for each key-point to shape. Then, use “LS” approach, we can obtain the parameters in the “M(s,θ)[X]−t”, that can guarantee the perfect alignment.
  Also, we can use the PCA function as mentioned in the earlier homework to make a PCA model describing normal contours
4, Make the Appearance model
AppearanceData = ASM_MakeAppearanceModel2D( );
[TrainingData(i).Normals]=ASM_GetContourNormals2D( );
  Make the Appearance model, which samples an intensity pixel line perpendicular to each contour point in each training dataset, which is used to build correlation matrices for each landmark and which are used in the optimization step, to find the best fit.
  In this step, we firstly calculate the norms of the contours of all training data, obtain the landmark profiles, the pixel profiles. Then, we calculate a covariance matrix for all landmarks by searching distance with edge gradient and by using PCA approach on intensities, which is for minimizing the distance to the mean during the search.
4, Test the ASM model
  Load the test images and find out whether the ASM model can function well on those test images.
