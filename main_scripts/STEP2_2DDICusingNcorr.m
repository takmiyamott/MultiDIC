%% STEP 2: Run Ncorr analysis on sets of images from a pair of 2 cameras using Ncorr
% The complete set of 2n images includes 2 sets of images taken simultaneously
% from 2 cameras (2 views). The first n images are from the "reference"
% camera and the last n are the "deformed" camera. It's not really
% important which one is defined as Ref and Def, as long as it's
% consistent. The 1st image from the 1st camera is always defined as the reference
% image.
%
% High-Strain / Step Analysis:
%   OFF: keep the original logic (single Ncorr call using the concatenated image set)
%   ON : use the original MultiDIC reference logic but split analyses by camera.
%        The key point is that BOTH camera sequences use the same reference image,
%        C1_1, so the point ordering remains compatible with STEP 3.

clearvars; close all; clc;

fs=get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 10);

%% CHOOSE PATHS OPTIONS
% initial image path
folderPathInitial=pwd;

% select the folder containing the analysis images (if imagePathInitial=[] then the initial path is the current path)
folderPathRef=uigetdir(folderPathInitial,'Select the folder containing speckle images from the reference camera');
folderPathInitial2 = fileparts(folderPathRef);
folderPathDef=uigetdir(folderPathInitial2,'Select the folder containing speckle images from the "deformed" camera');
folderPaths=cell(1,2);
folderPaths{1}=folderPathRef;
folderPaths{2}=folderPathDef;

% camera indices for current analysis
folderNameCell=strsplit(folderPaths{1},filesep);
folderNameStr=folderNameCell{end};
folderNameStrSplit=strsplit(folderNameStr,'_');
nCamRef=str2double(folderNameStrSplit{end});
folderNameCell=strsplit(folderPaths{2},filesep);
folderNameStr=folderNameCell{end};
folderNameStrSplit=strsplit(folderNameStr,'_');
nCamDef=str2double(folderNameStrSplit{end});

% save 2D-DIC results? choose save path
[save2DDIClogic,savePath]=Qsave2DDICresults(folderPaths);

%% create structure for saving the 2DDIC results
DIC2DpairResults = struct;
DIC2DpairResults.nCamRef=nCamRef;
DIC2DpairResults.nCamDef=nCamDef;
DIC2DpairResults.highStrainMode = false;
DIC2DpairResults.highStrainMap = struct();

%% load images from the paths, convert to gray and undistort, and create IMset cell for Ncorr
h=msgbox({'Please wait while loading images'});
[ImPaths,ImSet]=createDICimageSet(folderPaths,[]);
DIC2DpairResults.nImages=numel(ImPaths)/2;
DIC2DpairResults.ImPaths=ImPaths;
if isvalid(h)
    close(h);
end

%% ask whether to use the separated-camera high-strain workflow
highStrainPrompt = questdlg('Enable High-Strain / Step Analysis with camera-separated processing?', ...
    'High-Strain mode', 'No (legacy)', 'Yes (common reference)', 'No (legacy)');

highStrainMode = strcmp(highStrainPrompt,'Yes (common reference)');
DIC2DpairResults.highStrainMode = highStrainMode;

if highStrainMode
    DIC2DpairResults.highStrainMap.mode = 'camera_separated_common_reference';
else
    DIC2DpairResults.highStrainMap.mode = 'legacy_single_ncorr';
end

%% animate the 2 sets of images to be correlated with Ncorr
hf1=anim8_DIC_images(ImPaths,ImSet);
pause

%% choose ROI
% This is a GUI for choosing the ROI instead of choosing the ROI in the
% NCorr software (too small). It also allows the assistance of SIFT
% matches (it helps locating the overlapping region, but is time costly)
set(0, 'DefaultUIControlFontSize', 10);
chooseMaskButton = questdlg('Create new mask for correlation, use saved mask, or use Ncorr to draw mask?', 'mask options?', 'New', 'Saved','Ncorr', 'New'); % existing mask should be in savePath
switch chooseMaskButton
    case 'New'
        nROI=1;
        answer=inputdlg('Enter the number of ROIs','Enter the number of ROIs',1,{'1'});
        nROI=str2double(answer{1});

        ROImask = selectROI(ImSet{1},nROI);

        if save2DDIClogic
            save(fullfile(savePath, ['ROIMask' '_C_' num2str(nCamRef) '_C_' num2str(nCamDef)]),'ROImask');
        end
        DIC2DpairResults.ROImask=ROImask;
    case 'Saved'
        if save2DDIClogic
            PathInitial=fullfile(savePath, ['ROIMask' '_C_' num2str(nCamRef) '_C_' num2str(nCamDef)]);
        else
            PathInitial=folderPathInitial;
        end
        [FileName,PathName,~] = uigetfile('','Select ROI file',PathInitial);
        load([PathName FileName]);
        DIC2DpairResults.ROImask=ROImask;
    case 'Ncorr'
end

if highStrainMode
    % In the common-reference High-Strain mode, both camera analyses use the same
    % reference image C1_1 and the same ROI. This keeps the point ordering
    % consistent with the original MultiDIC design and with STEP 3.
    if ~strcmp(chooseMaskButton,'Ncorr')
        DIC2DpairResults.highStrainMap.commonROI = ROImask;
    else
        DIC2DpairResults.highStrainMap.commonROI = [];
    end
end

h=msgbox({'Please wait while initializing Ncorr'; ''; 'Press enter in the command window when'; 'Ncorr analysis is finished (without closing Ncorr)'});

%% Start Ncorr 2D analysis
if ~highStrainMode
    % legacy single-analysis path
    handles_ncorr = ncorr;
    handles_ncorr.set_ref(ImSet{1});
    handles_ncorr.set_cur(ImSet);
    if ~strcmp(chooseMaskButton,'Ncorr')
        handles_ncorr.set_roi_ref(ROImask);
    end

    disp('Press enter in the command window when Ncorr analysis is finished (without closing Ncorr)');
    pause

    [Points,CorCoeffVec,F,CF] = extractNcorrResults(handles_ncorr,ImSet{1});
    DIC2DpairResults.ncorrInfo=handles_ncorr.data_dic.dispinfo;
    DIC2DpairResults.Points=Points;
    DIC2DpairResults.CorCoeffVec=CorCoeffVec;
    DIC2DpairResults.Faces=F;
    DIC2DpairResults.FaceColors=CF;
    if ~strcmp(chooseMaskButton,'Ncorr')
        DIC2DpairResults.ROImask=handles_ncorr.reference.roi.mask;
    end

    set(0, 'DefaultUIControlFontSize', 10);
    plotButton = questdlg('Plot correlated points on images?', 'Plot?', 'Yes', 'No', 'Yes');
    switch plotButton
        case 'Yes'
            plotNcorrPairResults(DIC2DpairResults);
        case 'No'
    end
else
    % common-reference High-Strain path.
    % The key is that both camera sequences use the same reference image, C1_1.
    % This preserves the original MultiDIC point ordering and keeps STEP 3 valid.
    [ImSet1,ImSet2,ImPaths1,ImPaths2] = splitDICimageSetByCamera(ImSet,ImPaths,DIC2DpairResults.nImages);
    DIC2DpairResults.highStrainMap.ImPaths1 = ImPaths1;
    DIC2DpairResults.highStrainMap.ImPaths2 = ImPaths2;

    % camera 1 temporal analysis
    resultCam1 = runSingleCameraNcorr(ImSet1,ImSet{1},ROImask,~strcmp(chooseMaskButton,'Ncorr'));
    DIC2DpairResults.highStrainMap.cam1 = resultCam1;

    % camera 2 temporal analysis using the same C1_1 reference image
    resultCam2 = runSingleCameraNcorr(ImSet2,ImSet{1},ROImask,~strcmp(chooseMaskButton,'Ncorr'));
    DIC2DpairResults.highStrainMap.cam2 = resultCam2;

    % validate that the two analyses share a common reference grid and face topology
    if size(resultCam1.Points{1},1) ~= size(resultCam2.Points{1},1)
        error('STEP2 high-strain mode: Camera 1 and Camera 2 reference point counts differ. The common-reference workflow requires identical reference-grid size.');
    end
    if size(resultCam1.Faces,1) ~= size(resultCam2.Faces,1)
        error('STEP2 high-strain mode: Camera 1 and Camera 2 reference face topology differs.');
    end

    DIC2DpairResults = buildCompatibleDIC2DpairResults(DIC2DpairResults,resultCam1,resultCam2,nCamRef,nCamDef,ImPaths,DIC2DpairResults.nImages,[]);
    DIC2DpairResults.highStrainMap.referenceImage = ImSet{1};
    DIC2DpairResults.highStrainMap.referenceTimeIndex = 1;
    DIC2DpairResults.highStrainMap.imageIndex = struct('cam1',(1:DIC2DpairResults.nImages).','cam2',(1:DIC2DpairResults.nImages).');
end

%% save important variables for further analysis (write text files of correlated 2D points, their cirrelation coefficients, triangular faces, and face colors
if save2DDIClogic
    saveName=fullfile(savePath, ['DIC2DpairResults_C_' num2str(nCamRef) '_C_' num2str(nCamDef) '.mat']);

    % rename if exists
    icount=1;
    while exist(saveName,'file')
        saveName=fullfile(savePath, ['DIC2DpairResults_C_' num2str(nCamRef) '_C_' num2str(nCamDef) '(' num2str(icount) ').mat']);
        icount=icount+1;
    end
    save(saveName,'DIC2DpairResults','-v7.3');
end

%% close Ncorr figure
if exist('handles_ncorr','var') && ~isempty(handles_ncorr) && isvalid(handles_ncorr.handles_gui.figure)
    close(handles_ncorr.handles_gui.figure);
end
if isvalid(h)
    close(h);
end
% close first animation figure
if isvalid(hf1)
    close(hf1);
end

%% finish
hm=msgbox(['STEP2 for the camera pair  [' num2str([nCamRef nCamDef]) ']  is completed']);

set(0, 'DefaultUIControlFontSize', fs);

%% 
% MultiDIC: a MATLAB Toolbox for Multi-View 3D Digital Image Correlation
% 
% License: <https://github.com/MultiDIC/MultiDIC/blob/master/LICENSE.txt>
% 
% Copyright (C) 2018  Dana Solav
% 
% If you use the toolbox/function for your research, please cite our paper:
% <https://engrxiv.org/fv47e>
