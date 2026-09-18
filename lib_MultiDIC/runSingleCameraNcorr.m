function result = runSingleCameraNcorr(ImSetCam,ImRef,ROImask,useROI)
%% Run Ncorr on one camera's time sequence using a common reference image.
%
% In the separated High-Strain workflow used by MultiDIC, the common reference is
% always Camera 1 frame 1. Both camera analyses therefore share the same reference
% grid and point ordering, which preserves compatibility with the legacy STEP 3 code.

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

if useROI
    result.ROImask = handles_ncorr.reference.roi.mask;
end

result.handles_ncorr = handles_ncorr;

end
