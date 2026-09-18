%% Test helper for high-strain camera mapping logic.
% This script does not open Ncorr; it checks the expected index logic and
% synthetic mapping behavior.

clear; clc;

%% 1) test splitDICimageSetByCamera
nImages = 5;
ImSet = cell(2*nImages,1);
ImPaths = cell(2*nImages,1);
for ii = 1:2*nImages
    ImSet{ii} = rand(16,16);
    ImPaths{ii} = ['img_' num2str(ii) '.png'];
end

[ImSet1,ImSet2,ImPaths1,ImPaths2] = splitDICimageSetByCamera(ImSet,ImPaths,nImages);
assert(numel(ImSet1)==nImages);
assert(numel(ImSet2)==nImages);
assert(isequal(ImPaths1, ImPaths(1:nImages)));
assert(isequal(ImPaths2, ImPaths(nImages+1:end)));

disp('splitDICimageSetByCamera: OK');

%% 2) synthetic camera-2 mapping test
% Construct a camera-2 reference grid that matches the camera-1 reference grid.
P1 = [10 10; 20 10; 10 20; 20 20];
P2 = P1 + [0.5 0.5; -0.5 0.5; 0.5 -0.5; -0.5 -0.5];

resultCam2 = struct();
resultCam2.Points = cell(3,1);
resultCam2.CorCoeffVec = cell(3,1);
resultCam2.ncorrInfo = struct();

% frame 1 is the reference frame, already on the camera-2 reference grid
resultCam2.Points{1} = P2;
resultCam2.CorCoeffVec{1} = [0.99; 0.98; 0.97; 0.96];

% frame 2 and 3: synthetic deformed coordinates on the same camera-2 reference grid
resultCam2.Points{2} = P2 + [1 1; 1 0; 0 1; 0 0];
resultCam2.CorCoeffVec{2} = [0.95; 0.94; 0.92; 0.91];

resultCam2.Points{3} = P2 + [2 2; 2 1; 1 2; 1 1];
resultCam2.CorCoeffVec{3} = [0.90; 0.88; 0.87; 0.86];

crossResult = struct();
crossResult.Points = cell(1,1);
crossResult.Points{1} = P2;
crossResult.CorCoeffVec = cell(1,1);
crossResult.CorCoeffVec{1} = [0.99; 0.98; 0.97; 0.96];

mapped = mapCamera2ToCamera1Reference(resultCam2,crossResult);
assert(numel(mapped.Points)==3);
assert(size(mapped.Points{1},1)==size(P1,1));
assert(size(mapped.Points{2},1)==size(P1,1));
assert(size(mapped.Points{3},1)==size(P1,1));

disp('mapCamera2ToCamera1Reference: OK');

%% 3) legacy assembly order check
resultCam1 = struct();
resultCam1.Points = cell(3,1);
resultCam1.CorCoeffVec = cell(3,1);
resultCam1.Faces = [1 2 3; 1 3 4];
resultCam1.FaceColors = [1; 2];
resultCam1.ncorrInfo = struct('test',1);

for ii = 1:3
    resultCam1.Points{ii} = P1;
    resultCam1.CorCoeffVec{ii} = [0.99; 0.98; 0.97; 0.96];
end

DIC2DpairResults = struct();
DIC2DpairResults = buildCompatibleDIC2DpairResults(DIC2DpairResults,resultCam1,mapped,1,2,cell(6,1),3,[]);
assert(numel(DIC2DpairResults.Points) == 2*3);
assert(numel(DIC2DpairResults.CorCoeffVec) == 2*3);
assert(isequal(size(DIC2DpairResults.Faces), size(resultCam1.Faces)));

disp('buildCompatibleDIC2DpairResults: OK');

%% 4) synthetic invalid mapping should fail
crossBad = struct();
crossBad.Points = cell(1,1);
crossBad.Points{1} = [NaN NaN; 10 10; 20 20];
try
    mapCamera2ToCamera1Reference(resultCam2,crossBad);
    error('Expected invalid reference mapping to fail.');
catch ME
    disp('Invalid mapping rejection: OK');
end

disp('All high-strain test checks passed.');
