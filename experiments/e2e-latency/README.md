# NVIDIA VRR / vblank correlation experiment

This branch contains measurement helpers only. It does not modify the driver.

## Goal

Correlate NVIDIA display state with:

- DRM vblank / atomic events;
- CRTC first-pixel timestamps from the Linux Wave 4 probe;
- Vulkan/compositor present timing;
- frameprobe photon timing.

## Capture

Install `trace-cmd` and `drm_info`, then run as a user with access to tracefs or with the required privileges:

```sh
bash experiments/e2e-latency/capture-vrr-run.sh inside-vrr-range 20
```

The helper records driver/module state, DRM topology, GPU clocks/power/utilization, and available DRM tracepoints.

## Matrix

Use stable, non-destructive display states:

- fixed refresh;
- VRR inside range;
- near minimum VRR;
- below minimum VRR;
- near maximum VRR.

Avoid DPMS/blank-wake stress during latency characterization.

## Related reliability reports

Current NVIDIA open-driver reports include VRR low-FPS signal-loss behavior and separate KMS/blank-wake lockups. Those reports are useful boundary evidence but should not be treated as normal latency behavior.

## Analysis

Explicitly model low-framerate compensation/frame repetition when below the panel's VRR range.

The target correlation is:

```text
present target
 -> present result
 -> DRM first-pixel
 -> physical photon
```

No upstream promotion from this branch.
