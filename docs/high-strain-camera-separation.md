# High-Strain / Step Analysis in MultiDIC

This document explains the camera-separated High-Strain workflow added to MultiDIC STEP 2.

## Why the old workflow is invalid
The old code built a single image list:

```matlab
ImSet = [C1_1, C1_2, ..., C1_N, C2_1, C2_2, ..., C2_N]
```

When Ncorr Step Analysis is enabled, it can create image correspondences that cross the camera boundary, e.g.:

```text
C1_N -> C2_1
```

This is not a valid deformation path because the two cameras have different viewpoints and are not a continuous image sequence.

## Correct High-Strain design
The correct design is:

1. Camera 1 temporal DIC:
   `C1_1 -> ... -> C1_N`
2. Camera 2 temporal DIC:
   `C2_1 -> ... -> C2_N`
3. Cross-camera reference DIC:
   `C1_1 -> C2_1`

The cross-camera reference result defines how the Camera 2 reference image coordinates correspond to the Camera 1 reference grid.

## Why the cross-camera reference is required
STEP 3 expects a common point ordering between the two cameras. In `DIC2DpairResults`, the legacy code assumes:

```matlab
P1 = Points{ii};
P2 = Points{ii+nImages};
```

This means the second camera must be reindexed so that its points are in the same row order as the first camera.

The cross-camera reference DIC provides the mapping from Camera 1 reference nodes to Camera 2 reference coordinates. Camera 2 temporal deformation data is then interpolated onto those mapped points and the resulting `Points` cells are reassembled in the legacy order.

## How to enable it
The STEP 2 script asks the user whether to use the legacy behavior or the camera-separated High-Strain workflow. For the separated workflow, the script:

- runs Camera 1 temporal Ncorr,
- runs Camera 2 temporal Ncorr,
- runs a Camera 1 -> Camera 2 cross reference Ncorr,
- maps Camera 2 temporal results to the Camera 1 reference ordering,
- assembles legacy `DIC2DpairResults` for STEP 3.

## ROI assumptions
The camera 1 ROI is used for the Camera 1 temporal analysis and the cross-camera reference analysis. The camera 2 ROI is independent and must be selected or reused explicitly. Reusing a camera 1 mask for camera 2 without a mapping is not safe.

## Validation notes
Before STEP 3, validate that:

- `nImages` matches the number of frames per camera,
- `Points{ii}` and `Points{ii+nImages}` have the same row count,
- Camera 2 interpolation did not produce NaN for every point,
- `Faces` and `FaceColors` remain from the Camera 1 reference grid.

## Limitations
The camera-to-camera mapping depends on the initial reference DIC being successful and sufficiently valid. If the `C1_1 -> C2_1` result is poor or the ROI is invalid, the separated workflow should fail early instead of silently producing bad 3D reconstructions.
