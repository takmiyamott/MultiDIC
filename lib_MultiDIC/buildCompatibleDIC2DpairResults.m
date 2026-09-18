function DIC2DpairResults = buildCompatibleDIC2DpairResults(DIC2DpairResults,resultCam1,resultCam2, ...
                                                            nCamRef,nCamDef,ImPaths,nImages, camera2Mapping)
%% Assemble two common-reference analyses in the original MultiDIC layout.
%
% Both resultCam1 and resultCam2 are produced from the same reference image, C1_1,
% so they share the same point ordering and face topology. No extra camera-to-camera
% mapping or interpolation is required.

if nargin >= 9 && ~isempty(camera2Mapping)
    warning('buildCompatibleDIC2DpairResults:UnusedMapping', ...
            'In the common-reference workflow, camera2Mapping is ignored because both analyses use the same reference image.');
end

if numel(resultCam1.Points) ~= nImages || numel(resultCam2.Points) ~= nImages
    error('buildCompatibleDIC2DpairResults:InvalidFrameCount', ...
          'Both camera analyses must contain nImages frames.');
end

for ii = 1:nImages
    if size(resultCam1.Points{ii},1) ~= size(resultCam2.Points{ii},1)
        error('buildCompatibleDIC2DpairResults:IncompatiblePointCount', ...
              ['The two camera analyses do not share the same point count at frame ' num2str(ii) '.']);
    end
    if size(resultCam1.CorCoeffVec{ii},1) ~= size(resultCam1.Points{ii},1)
        error('buildCompatibleDIC2DpairResults:MalformedCamera1Correlations', ...
              ['Camera 1 correlation vector size does not match point count at frame ' num2str(ii) '.']);
    end
    if size(resultCam2.CorCoeffVec{ii},1) ~= size(resultCam2.Points{ii},1)
        error('buildCompatibleDIC2DpairResults:MalformedCamera2Correlations', ...
              ['Camera 2 correlation vector size does not match point count at frame ' num2str(ii) '.']);
    end
end

if size(resultCam1.Faces,1) ~= size(resultCam2.Faces,1)
    error('buildCompatibleDIC2DpairResults:IncompatibleFaceTopology', ...
          'The two camera analyses do not share the same reference face topology.');
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
DIC2DpairResults.highStrainMap.mappingMethod = 'common_reference_camera1';
DIC2DpairResults.highStrainMap.mappingRequired = false;

end
