function result = runSingleCameraNcorr(ImSetCam,ImRef,ROImask,useROI)
%% Run Ncorr on one camera's time sequence using a common reference image.
%
% In the separated High-Strain workflow used by MultiDIC, the common reference is
% always Camera 1 frame 1. Both camera analyses therefore share the same reference
% grid and point ordering, which preserves compatibility with the legacy STEP 3 code.
%
% Inputs:
%   ImSetCam : cell array of images for one camera, in time order.
%   ImRef    : common reference image (Camera 1 frame 1).
%   ROImask  : ROI to apply to the reference image. May be empty when useROI
%              is false, in which case the user must draw the ROI inside the
%              Ncorr GUI interactively.
%   useROI   : logical. true  -> apply ROImask programmatically via set_roi_ref.
%                       false -> let the user draw the ROI inside the Ncorr GUI.
%
% Output:
%   result : struct with Points, CorCoeffVec, Faces, FaceColors, ncorrInfo,
%            ROImask (always captured after the analysis, whether it was set
%            programmatically or drawn interactively), and handles_ncorr.

if isempty(ImSetCam) || isempty(ImRef)
    error('runSingleCameraNcorr:EmptyInput','Reference and current images are required.');
end

if ndims(ImRef) ~= 2
    error('runSingleCameraNcorr:InvalidReference','The common reference image must be grayscale.');
end

if useROI
    if isempty(ROImask) || ~isequal(size(ROImask),size(ImRef)) || ~islogical(ROImask)
        error('runSingleCameraNcorr:InvalidROI', ...
              'The ROI must be logical and have the same size as the common reference image.');
    end
end

handles_ncorr = ncorr;
handles_ncorr.set_ref(ImRef);
handles_ncorr.set_cur(ImSetCam);

if useROI
    handles_ncorr.set_roi_ref(ROImask);
end
% If useROI is false, the user is expected to draw the ROI interactively
% inside the Ncorr GUI before running the analysis.

disp('Run Ncorr analysis and press ENTER in the command window.');
pause;

[Points,CorCoeffVec,F,CF] = extractNcorrResults(handles_ncorr,ImRef);

result.Points = Points;
result.CorCoeffVec = CorCoeffVec;
result.Faces = F;
result.FaceColors = CF;
result.ncorrInfo = handles_ncorr.data_dic.dispinfo;
result.referenceImage = ImRef;
result.referenceCamera = 1;

% Always capture the reference ROI actually used by Ncorr, regardless of
% whether it was set programmatically or drawn interactively. This lets the
% caller reuse the exact same mask for a second camera analysis, which is
% required for the common-reference High-Strain workflow.
if ~isempty(handles_ncorr.reference) && ~isempty(handles_ncorr.reference.roi)
    result.ROImask = handles_ncorr.reference.roi.mask;
else
    result.ROImask = [];
end

result.handles_ncorr = handles_ncorr;

end
