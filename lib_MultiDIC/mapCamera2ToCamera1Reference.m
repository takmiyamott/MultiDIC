function mapped = mapCamera2ToCamera1Reference(resultCam2, crossResult)
%% Map Camera 2 results from its own reference-grid ordering to the Camera 1 reference grid.
%
% The cross-camera result provides the coordinates in the Camera 2 reference image
% corresponding to the Camera 1 reference grid. We use these as the interpolation
% samples for the Camera 2 temporal deformation field.
%
% Inputs:
%   resultCam2  : output of runSingleCameraNcorr on camera 2 sequence
%   crossResult : output of runCrossCameraReferenceDIC with C1_1 -> C2_1
%
% Output:
%   mapped      : struct with mapped Points, CorCoeffVec, and diagnostics

if ~isfield(crossResult,'Points') || numel(crossResult.Points) < 1
    error('mapCamera2ToCamera1Reference:MissingCrossCameraData', ...
          'Cross-camera result is missing. Required to map Camera 2 to the Camera 1 reference grid.');
end

P2refMapped = crossResult.Points{1};

if isempty(P2refMapped) || any(isnan(P2refMapped(:)))
    error('mapCamera2ToCamera1Reference:InvalidCrossCameraMap', ...
          'Cross-camera map contains invalid points. Check the initial C1_1 -> C2_1 DIC and ROI settings.');
end

nFrames = numel(resultCam2.Points);
validCount = zeros(nFrames,1);
outsideCount = zeros(nFrames,1);

mapped.Points = cell(nFrames,1);
mapped.CorCoeffVec = cell(nFrames,1);
mapped.diagnostics = struct();

P2refGrid = resultCam2.Points{1};

for ii = 1:nFrames
    curGrid = resultCam2.Points{ii};
    curCorr = resultCam2.CorCoeffVec{ii};

    if isempty(curGrid) || isempty(curCorr)
        error('mapCamera2ToCamera1Reference:EmptyFrame', ...
              ['Camera 2 temporal result for frame ' num2str(ii) ' is empty.']);
    end

    if size(curGrid,1) ~= size(P2refGrid,1)
        error('mapCamera2ToCamera1Reference:MismatchedGridSize', ...
              ['Camera 2 temporal result for frame ' num2str(ii) ' does not share the same reference-grid size as the initial camera-2 reference frame.']);
    end

    valid = ~any(isnan(curGrid),2) & ~isnan(curCorr);
    if sum(valid) < 3
        error('mapCamera2ToCamera1Reference:InsufficientSamples', ...
              ['Frame ' num2str(ii) ' has too few valid samples to interpolate Camera 2 points onto the Camera 1 reference grid.']);
    end

    Fx = scatteredInterpolant(P2refGrid(valid,1), P2refGrid(valid,2), curGrid(valid,1), 'natural', 'none');
    Fy = scatteredInterpolant(P2refGrid(valid,1), P2refGrid(valid,2), curGrid(valid,2), 'natural', 'none');
    Fcc = scatteredInterpolant(P2refGrid(valid,1), P2refGrid(valid,2), curCorr(valid), 'nearest', 'none');

    xEval = P2refMapped(:,1);
    yEval = P2refMapped(:,2);

    mapped.Points{ii} = [Fx(xEval,yEval), Fy(xEval,yEval)];
    mapped.CorCoeffVec{ii} = Fcc(xEval,yEval);

    validCount(ii) = sum(~isnan(mapped.Points{ii}(:,1)) & ~isnan(mapped.Points{ii}(:,2)));
    outsideCount(ii) = sum(isnan(mapped.Points{ii}(:,1)) | isnan(mapped.Points{ii}(:,2)));
end

mapped.diagnostics.validCount = validCount;
mapped.diagnostics.outsideCount = outsideCount;
mapped.diagnostics.nFrames = nFrames;
mapped.diagnostics.referenceGridSize = size(P2refMapped,1);
mapped.ncorrInfo = resultCam2.ncorrInfo;

end
