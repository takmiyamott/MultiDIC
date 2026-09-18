function [ImSet1,ImSet2,ImPaths1,ImPaths2] = splitDICimageSetByCamera(ImSet,ImPaths,nImages)
%% Split a stereo image set into separate camera sequences.
%
% This is used when High-Strain Analysis is enabled so that the camera
% time series are analyzed independently before recombining them for
% the stereo 3D reconstruction step.
%
% Inputs:
%   ImSet   : 2*nImages x 1 cell array containing the stereo image set
%   ImPaths : paths corresponding to ImSet
%   nImages : number of time frames per camera
%
% Outputs:
%   ImSet1, ImSet2, ImPaths1, ImPaths2

if numel(ImSet) ~= 2*nImages
    error('splitDICimageSetByCamera:InvalidInput', ...
          'Expected 2*nImages images in ImSet.');
end

ImSet1 = ImSet(1:nImages);
ImSet2 = ImSet(nImages+1:end);

ImPaths1 = ImPaths(1:nImages);
ImPaths2 = ImPaths(nImages+1:end);

end
