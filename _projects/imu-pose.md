---
layout: project
title: Active Inertial Sensing for Ego-Centric Motion Recovery
date: 2026-03-17
authors: Jinxi Xiao (also with Heng'an Zhou, Ran Ji and Boyang Xia)
---

## Overview

This project asks a deliberately narrow question: **when a single low-cost IMU is rigidly attached to a moving object, what can be recovered about its ego-centric motion from the raw inertial stream?** This is a sensor-centric first step toward object-centric sensing—not yet a complete 6D tracker or a visual-inertial fusion system.

The motivation comes from dynamic-scene understanding. Static geometry and appearance can now be reconstructed reliably with methods such as 3D Gaussian Splatting {% cite 3dGS %}, NeRF {% cite nerf %}, NeuS/VolSDF {% cite wang2021neus volsdf %}, and COLMAP {% cite colmap %}. Motion under contact and occlusion remains substantially harder. Dense multi-view systems provide accurate capture but require calibrated, synchronized cameras; monocular pose tracking is easier to deploy but becomes fragile when objects occlude one another or share repeated appearance. Figure 1 illustrates this failure mode: segmentation and tracking break down for visually similar bowling pins under strong inter-object occlusion.

<figure id="fig-sam3" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/sam3.gif" alt="Segmentation and tracking failure caused by repeated object appearance and occlusion" style="max-width: 100%; height: auto;">
  <figcaption><strong>Figure 1.</strong> A SAM3 {% cite carion2025sam3segmentconcepts %} segmentation-and-tracking failure under repeated appearance and inter-object occlusion.</figcaption>
</figure>

IMUs offer a complementary route: they require no line of sight, operate at high rate, and are inexpensive enough to attach to individual objects. Human motion-capture systems already exploit these properties, but our target regime is more difficult. A manipulated object may undergo non-periodic motion, abrupt changes of direction, and far weaker motion priors than pedestrian gait or robot locomotion. Rather than applying naive double integration to estimate pose, we use velocity direction as an interpretable intermediate target and map out the conditions under which it is—and is not—recoverable.

The main outcomes are clear. A single sensor recognizes coarse, homogeneous motion very well (95.82% on AXIS-7), but performance falls sharply across data-collection conditions and for windows containing direction changes. These are useful negative results: they identify condition invariance and temporally richer supervision as the central requirements for practical inertial object sensing.

## Why Single-IMU Ego-Motion Is Difficult

Most learning-based inertial odometry work targets pedestrians {% cite chen2018ionet ronin ctin %} or robotic platforms {% cite tartanimu airio autoOdom %}. Such platforms have structured dynamics—quasi-periodic gait or controller-regularized trajectories—so learning a mapping from an IMU window to average velocity can be effective within the observed motion distribution. Physically, however, integrating acceleration over a finite interval yields a velocity **increment** $$\Delta\mathbf{v}$$, not an absolute velocity. Window-to-velocity prediction therefore relies on a learned local motion prior.

That assumption is much weaker for arbitrary object-like motion. The sensor may be attached to diverse bodies with different couplings, accelerations, and contact events. We consequently use direction classification as a diagnostic formulation. It removes velocity magnitude as a confound, produces interpretable motion primitives, and lets us increase motion complexity in a controlled way. It does not claim that a discretized class label is the final form of object tracking.

## Hardware and Robot-Assisted Data Collection

To obtain repeatable kinematic supervision without the ambiguity of freehand motion, we mount a WitMotion WT901WIFI on the end-effector of a UFACTORY xArm6 using a custom 3D-printed fixture. The robot executes predefined programs while the sensor records raw 3-axis acceleration and 3-axis angular velocity at 100 Hz. Software synchronization aligns the robot and IMU streams; the sensor center and axes are registered to the configured gripper frame.

<figure id="fig-recording" style="margin: 1.5em auto;">
  <div style="display: flex; gap: 1rem; justify-content: center; align-items: flex-start; flex-wrap: wrap;">
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/linear.gif" alt="xArm6 recording a straight-line trajectory" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(a) Straight-line motion</em></div>
    </div>
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/polyline.gif" alt="xArm6 recording a waypoint-driven polyline trajectory" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(b) Waypoint-driven polyline motion</em></div>
    </div>
  </div>
  <figcaption><strong>Figure 2.</strong> Robot-assisted inertial data collection under homogeneous and non-homogeneous motion programs.</figcaption>
</figure>

Although the WT901WIFI is a 9-axis device, we do not rely on its fused orientation in typical environments. That estimate depends strongly on magnetometer observations and can be corrupted by nearby metal or electronic equipment. Instead, with the fixed IMU-to-gripper alignment and a level robot base, we compute gravity in the body frame from robot forward kinematics and compensate it from the acceleration signal. The learned model therefore uses the IMU as a practical low-cost 6-axis sensor. At roughly 100 RMB, it is attractive for large-scale experiments even though it cannot match premium motion-capture hardware.

The hardware also constrains the learning problem. We perform no explicit bias removal beyond gravity compensation. Preliminary Allan-variance analysis {% cite AllanVarianceRos %} reveals axis-dependent noise and bias instability, especially on the accelerometer's $$z$$ axis. This makes imperfect gravity removal and continuous regression particularly sensitive along the vertical direction, a pattern that reappears in the classification errors.

<figure id="fig-imu-allan" style="margin: 1.5em auto;">
  <div style="display: flex; gap: 1rem; justify-content: center; align-items: flex-start; flex-wrap: wrap;">
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/acceleration.png" alt="Allan variance of accelerometer measurements" style="max-width: 100%; height: auto;">
    </div>
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/gyro.png" alt="Allan variance of gyroscope measurements" style="max-width: 100%; height: auto;">
    </div>
  </div>
  <figcaption><strong>Figure 3.</strong> Allan-variance curves for the WT901WIFI accelerometer (left) and gyroscope (right). The accelerometer exhibits clear axis-dependent behavior.</figcaption>
</figure>

## Formulation and Baseline

Each example is a 100-frame window ($$W=100$$) of body-frame angular velocity $$\boldsymbol{\omega}_{k:k+W}$$ and gravity-compensated acceleration $$\mathbf{a}_{k:k+W}$$. We learn

$$
\mathcal{F}: [\boldsymbol{\omega}_{k:k+W}, \mathbf{a}_{k:k+W}] \rightarrow c, \qquad c \in \mathcal{C},
$$

where $$\mathcal{C}$$ is a set of discrete velocity-direction bins. Labels are derived from xArm6 motion in the end-effector body frame. Sequences are divided into train/validation/test partitions at a ratio of 0.8/0.1/0.1 **before** window extraction, preventing direct leakage between overlapping windows.

Our baseline is iTransformer {% cite iTransformer %} with a lightweight 1D-convolutional embedding of the raw six-channel signal, learnable temporal position encoding, and a classification head. This is intentionally a capable but conventional sequence model: the project evaluates inertial sensing limits rather than proposes a new network architecture.

<figure id="fig-arch" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/arch.svg" alt="iTransformer-based inertial-motion classification architecture" style="max-width: 75%; height: auto;">
  <figcaption><strong>Figure 4.</strong> iTransformer-based baseline. A convolutional embedding processes raw inertial signals before temporal encoding and velocity-direction classification.</figcaption>
</figure>

As a capacity sanity check, we also evaluate the backbone on the public RoNIN inertial-odometry benchmark {% cite ronin %}. This experiment is separate from the robot-collected classification study: it only checks that the chosen sequence model can extract useful information from IMU streams without extensive task-specific tuning. ATE and RTE are in meters; lower is better.

| Method | RONIN-ResNet {% cite ronin %} | CTIN {% cite rao2022ctin %} | iMoT {% cite nguyen2025imot %} | DiffusionIMU {% cite diffusionimu %} | M2EIT {% cite M2EIT %} | Ours |
| :-- | :--: | :--: | :--: | :--: | :--: | :--: |
| Seen ATE/RTE | 3.70/2.78 | 4.62/2.81 | 3.78/2.68 | 3.64/2.72 | 3.58/2.76 | 3.80/2.75 |
| Unseen ATE/RTE | 5.48/4.56 | 5.61/4.48 | 5.31/4.39 | 5.27/4.31 | 5.19/4.57 | 5.47/4.61 |

## Progressive Evaluation: What the Sensor Can Recover

We collected four robot datasets spanning approximately 25.5 hours and progressively increasing motion complexity.

| Dataset | Motion and labels | Scale |
| :-- | :-- | :-- |
| **AXIS-7** | $$\pm x, \pm y, \pm z$$ and static homogeneous motion | ~500 sequences/class; ~6 h |
| **DIR27-L** | 27 body-frame directions, $$v_i \in \{-1,0,1\}$$ | 200 sequences/class; ~7.5 h |
| **DIR27-S** | Same 27 directions under a separate condition | 100 sequences/class; ~4 h |
| **POLY-27** | Waypoint-driven, non-homogeneous polylines | 200 sequences/class; ~8 h |

Here a *condition* includes the motion program, initial pose, fixture coupling, sensor state, and recording context. For AXIS-7 and DIR27, the robot begins each segment from diverse orientations. These rotations preserve body-frame labels while varying gravity projection and orientation-dependent artifacts, testing whether the model learns motion rather than trivial pose cues. Unless noted otherwise, training uses raw six-channel windows, batch size 1024, 10 epochs, and one GeForce RTX 3090 GPU, with no per-channel normalization or extensive hyperparameter search.

### Phase 1 — Axis-Aligned Homogeneous Motion

On AXIS-7, the classifier reaches **95.82% accuracy** and **0.9581 weighted F1**. This demonstrates that one low-cost IMU contains sufficient information to recognize coarse translational primitives when motion is straight, homogeneous, and accurately gravity-compensated. The remaining errors are primarily between opposite directions on the same axis, particularly $$+z$$ and $$-z$$, consistent with the sensor asymmetry observed above.

<figure id="fig-confusion-phase1" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/confussion_matrix_5_1.png" alt="AXIS-7 confusion matrix" style="max-width: 50%; height: auto;">
  <figcaption><strong>Figure 5</strong> AXIS-7 confusion matrix. Residual errors cluster around opposite directions on the same axis, most visibly $\pm z$.</figcaption>
</figure>

### Phase 2 — Fine-Grained Directions and Cross-Condition Robustness

For DIR27, each velocity component is quantized to $$\{-1,0,1\}$$, yielding 27 direction classes. Matched-condition results remain strong: **92.23%** on DIR27-L, **88.84%** on DIR27-S, and **91.84%** when the two datasets are merged for matched-condition training and testing.

The central limitation appears when the condition changes. Training on DIR27-L and testing on DIR27-S falls to **58.16%**; the reverse transfer reaches only **53.38%**. Both confusion matrices show similar structures, indicating a systematic condition gap rather than one anomalous split. The model is likely using some condition-specific cues—controller response, mounting and fixture coupling, sensor state, or recording context—instead of fully invariant physical motion features. High matched-condition accuracy is therefore not sufficient evidence of robust physical understanding.

<figure id="fig-jump-detail" style="margin: 1.5em auto;">
  <div style="display: flex; gap: 1rem; justify-content: center; align-items: flex-start; flex-wrap: wrap;">
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/train0123_test0126.png" alt="DIR27-L to DIR27-S transfer confusion matrix" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(a) Train DIR27-L, test DIR27-S</em></div>
    </div>
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/train0126_test0123.png" alt="DIR27-S to DIR27-L transfer confusion matrix" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(b) Train DIR27-S, test DIR27-L</em></div>
    </div>
  </div>
  <figcaption><strong>Figure 6.</strong> Cross-condition diagnostics for 27-way classification. Similar error structures in both directions support condition sensitivity rather than a defective split.</figcaption>
</figure>

We also tested rotation-equivariant augmentation inspired by RIO {% cite cao2022RIO %}: rotating an inertial window by $$\mathbf{R}$$ should rotate its direction label by the same transformation. In the real pipeline, the assumption does not hold cleanly. On AXIS-7, this augmentation reduces accuracy from 95.82% to 85.57%. A label-flip diagnostic that swaps $$+y$$ and $$-y$$ at evaluation reduces the corresponding F1 score by 24.7%. Sensor-axis bias, controller dynamics, and fixture coupling are all axis dependent, so ideal rigid-rotation augmentation is mismatched to the measured distribution.

### Phase 3 — Non-Homogeneous Polyline Motion

POLY-27 contains waypoint-driven trajectories for which the instantaneous velocity can change within a 100-frame window. A constant direction label is no longer available, so we use net displacement as a proxy target,

$$
\mathbf{d}_{\text{net}} = \mathbf{p}_{k+W} - \mathbf{p}_k,
$$

and assign its nearest directional bin. Accuracy drops to **49.2%**—well above 27-way random chance (3.7%), but far below the straight-line settings. The result exposes a mismatch between the target and the signal: net displacement discards the local direction changes within a window. In this regime, the single-label-window formulation becomes much less informative than the raw inertial sequence it summarizes.

## Takeaways and Next Steps

The study establishes both the promise and the boundary of active inertial sensing with one low-cost IMU. Under controlled, homogeneous motion, the sensor can recover coarse ego-motion primitives reliably. Yet cross-condition transfer, idealized rotation augmentation, and non-homogeneous trajectories all reveal that the current formulation is not robust enough for practical object tracking.

The most useful next directions are:

- condition-invariant sensing and calibration that explicitly model bias, mounting, and controller effects;
- adaptive or multi-scale temporal windows rather than a fixed 100-frame horizon;
- dense per-frame direction prediction or sequence-to-sequence velocity modeling, replacing a single net-displacement label; and
- fusion with visual observations or physics-informed constraints when the application requires full object trajectories.

Velocity-direction classification remains valuable as a controlled diagnostic target. Its failures clarify what a future inertial object-sensing system must solve before it can support reliable dynamic-scene understanding.

## References

{% bibliography --cited %}
