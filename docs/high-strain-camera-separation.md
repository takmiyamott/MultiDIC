# High-Strain / Step Analysis in MultiDIC

The original MultiDIC design keeps the first camera image C1_1 as the reference image and builds a single `ImSet` in the order:

```text
C1_1, C1_2, ..., C1_N, C2_1, C2_2, ..., C2_N
```

The logic in STEP 3 assumes that both cameras share the same reference-grid point ordering. Therefore, for High-Strain / Step Analysis the correct modification is not to create a separate camera 2 reference grid, but to perform two analyses that both use the same reference image C1_1:

```text
Analysis 1: reference = C1_1, current = {C1_1, ..., C1_N}
Analysis 2: reference = C1_1, current = {C2_1, ..., C2_N}
```

This preserves:

- the original ROI definition,
- the original reference-grid ordering,
- the original `Faces` and `FaceColors` topology,
- compatibility with the existing STEP 3 code.

The invalid transition that must be avoided is:

```text
C1_N -> C2_1
```

which is created when both camera images are concatenated into a single Ncorr sequence.

## Why this is compatible with the original toolbox
The original `extractNcorrResults` and STEP 3 code both use the same reference-grid ordering assumption. If both camera analyses use the same reference image, then `Points{ii}` and `Points{ii+nImages}` remain aligned by row index and STEP 3 still works without a custom camera-to-camera reindexing stage.

## Important caveat
This common-reference approach assumes that the two camera images can be interpreted in the same reference coordinate system (for example after the preprocessing/rectification already expected by the stereo setup). It is not a substitute for valid stereo calibration or a valid common-image setup.
