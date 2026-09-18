function DIC2DpairResults = buildCompatibleDIC2DpairResults(DIC2DpairResults,resultCam1,resultCam2, ...
                                                            nCamRef,nCamDef,ImPaths,nImages, camera2Mapping)
%% Build a STEP-2 result structure that remains compatible with later stereo reconstruction.
% This function does not change the public interface of DIC2DpairResults.
% It simply keeps the common reference grid for camera 1 and, if needed,
% reindex camera 2 results into the same point ordering.
%
% If camera2Mapping is omitted or empty, we use the conservative fallback
% that assumes the reference grids have the same point count and ordering.
% This is safe only when the camera 2 subset grid has already been mapped to
% the camera 1 reference grid externally.
%
% The default behavior is intentionally strict and warns the user rather than
% silently producing wrong 3D reconstruction data.

if nargin < 8 || isempty(camera2Mapping)
    if numel(resultCam1.Points) == numel(resultCam2.Points)
        samePointCount = true;
        for ii = 1:numel(resultCam1.Points)
            samePointCount = samePointCount && size(resultCam1.Points{ii},1) == size(resultCam2.Points{ii},1);
        end
        if samePointCount
            warning('buildCompatibleDIC2DpairResults:UsingFallback', ...
                    ['No explicit camera-to-camera mapping was provided. Using a conservative fallback that assumes identical point ordering between camera 1 and camera 2. This is valid only if camera 2 has already been mapped to the camera 1 reference grid.']);
            resultCam2Mapped = resultCam2;
        else
            error('buildCompatibleDIC2DpairResults:MissingMapping', ...
                  ['High-strain camera separation requires an explicit camera-to-camera mapping before STEP 3 can be run. ' ...
                   'The camera 2 point set must be reindexed to the camera 1 reference grid.']);
        end
    else
        error('buildCompatibleDIC2DpairResults:MissingMapping', ...
              ['High-strain camera separation requires an explicit camera-to-camera mapping before STEP 3 can be run. ' ...
               'The camera 2 point set must be reindexed to the camera 1 reference grid.']);
    end
else
    resultCam2Mapped = camera2Mapping(resultCam2,resultCam1);
end

DIC2DpairResults.nCamRef = nCamRef;
DIC2DpairResults.nCamDef = nCamDef;
DIC2DpairResults.nImages = nImages;
DIC2DpairResults.ImPaths = ImPaths;

DIC2DpairResults.Points = [resultCam1.Points(:); resultCam2Mapped.Points(:)];
DIC2DpairResults.CorCoeffVec = [resultCam1.CorCoeffVec(:); resultCam2Mapped.CorCoeffVec(:)];
DIC2DpairResults.Faces = resultCam1.Faces;
DIC2DpairResults.FaceColors = resultCam1.FaceColors;
DIC2DpairResults.ncorrInfo.cam1 = resultCam1.ncorrInfo;
DIC2DpairResults.ncorrInfo.cam2 = resultCam2Mapped.ncorrInfo;

end
