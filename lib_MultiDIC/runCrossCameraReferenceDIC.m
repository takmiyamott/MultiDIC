function result = runCrossCameraReferenceDIC(ImRef1,ImRef2,ROImask1,ROImask2)
%% Run a cross-camera reference DIC: Camera 1 reference image vs Camera 2 reference image.
%
% This establishes the mapping from the Camera 1 reference grid to Camera 2
% reference-image coordinates. It is required before mapping Camera 2 temporal
% results back into the Camera 1 point ordering.
%
% Inputs:
%   ImRef1  : Camera 1 reference image (single image)
%   ImRef2  : Camera 2 reference image (single image)
%   ROImask1: ROI in Camera 1 reference coordinates
%   ROImask2: ROI in Camera 2 reference coordinates (optional; if empty and
%             ROI is needed, it can be decided later inside Ncorr)
%
% Output:
%   result  : struct with Points, CorCoeffVec, Faces, FaceColors, ncorrInfo

handles_ncorr = ncorr;
handles_ncorr.set_ref(ImRef1);
handles_ncorr.set_cur({ImRef2});

if ~isempty(ROImask1)
    handles_ncorr.set_roi_ref(ROImask1);
end

if ~isempty(ROImask2)
    % Ncorr supports a current ROI as an optional selection. Keep it explicit.
    handles_ncorr.set_roi_cur(ROImask2);
end

disp('Run cross-camera reference DIC and press ENTER in the command window.');
pause;

[Points,CorCoeffVec,F,CF] = extractNcorrResults(handles_ncorr,ImRef1);

result.Points = Points;
result.CorCoeffVec = CorCoeffVec;
result.Faces = F;
result.FaceColors = CF;
result.ncorrInfo = handles_ncorr.data_dic.dispinfo;

end
