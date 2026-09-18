function DIC2DpairResults = buildCompatibleDIC2DpairResults(DIC2DpairResults,resultCam1,resultCam2, ...
                                                            nCamRef,nCamDef,ImPaths,nImages, camera2Mapping)
%% Build a STEP-2 result structure compatible with later stereo reconstruction.
% This function preserves the public interface of DIC2DpairResults while reindexing
% camera 2 results onto the Camera 1 reference-grid ordering.
%
% Inputs:
%   DIC2DpairResults : current struct
%   resultCam1       : output of runSingleCameraNcorr on camera 1
%   resultCam2       : output of mapCamera2ToCamera1Reference on camera 2
%   nCamRef          : reference camera index
%   nCamDef          : deformed camera index
%   ImPaths          : original image paths in the legacy order
%   nImages          : number of time frames per camera
%   camera2Mapping   : optional mapping function (currently ignored if provided;
%                      the mapping must already have been applied to resultCam2)
%
% Output:
%   DIC2DpairResults : updated struct

if nargin < 8 || isempty(camera2Mapping)
    % The mapping is assumed to have been performed already in resultCam2.
    % We intentionally do not silently accept a same-order fallback.
end

if numel(resultCam1.Points) ~= nImages || numel(resultCam2.Points) ~= nImages
    error('buildCompatibleDIC2DpairResults:InvalidFrameCount', ...
          'Camera 1 and Camera 2 temporal results must contain the same number of time frames.');
end

for ii = 1:nImages
    if size(resultCam1.Points{ii},1) ~= size(resultCam2.Points{ii},1)
        error('buildCompatibleDIC2DpairResults:IncompatiblePointCount', ...
              ['Camera 1 and Camera 2 results do not share the same point ordering for frame ' num2str(ii) '.']);
    end
end

DIC2DpairResults.nCamRef = nCamRef;
DIC2DpairResults.nCamDef = nCamDef;
DIC2DpairResults.nImages = nImages;
DIC2DpairResults.ImPaths = ImPaths;

DIC2DpairResults.Points = [resultCam1.Points(:); resultCam2.Points(:)];
DIC2DpairResults.CorCoeffVec = [resultCam1.CorCoeffVec(:); resultCam2.CorCoeffVec(:)];
DIC2DpairResults.Faces = resultCam1.Faces;
DIC2DpairResults.FaceColors = resultCam1.FaceColors;

if ~isfield(DIC2DpairResults,'ncorrInfo') || isempty(DIC2DpairResults.ncorrInfo)
    DIC2DpairResults.ncorrInfo = struct();
end
DIC2DpairResults.ncorrInfo.cam1 = resultCam1.ncorrInfo;
DIC2DpairResults.ncorrInfo.cam2 = resultCam2.ncorrInfo;

end
