function result = runSingleCameraNcorr(ImSetCam,ImRef,ROImask,useROI)
%% Run Ncorr on a single camera sequence for high-strain analysis.
%
% Inputs:
%   ImSetCam : cell array of images for one camera, in time order.
%   ImRef    : first image used as the reference image for that camera.
%   ROImask  : ROI to use for the camera sequence.
%   useROI   : logical, whether to apply ROImask.
%
% Output:
%   result : struct with Points, CorCoeffVec, Faces, FaceColors, ncorrInfo

handles_ncorr = ncorr;
handles_ncorr.set_ref(ImRef);
handles_ncorr.set_cur(ImSetCam);

if useROI
    handles_ncorr.set_roi_ref(ROImask);
end

disp('Run Ncorr analysis for one camera and press ENTER in the command window.');
pause;

[Points,CorCoeffVec,F,CF] = extractNcorrResults(handles_ncorr,ImRef);

result.Points = Points;
result.CorCoeffVec = CorCoeffVec;
result.Faces = F;
result.FaceColors = CF;
result.ncorrInfo = handles_ncorr.data_dic.dispinfo;

if useROI
    result.ROImask = handles_ncorr.reference.roi.mask;
end

end
