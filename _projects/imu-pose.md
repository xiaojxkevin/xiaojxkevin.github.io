---
layout: project
title: Tracking via Active Inertial Sensing
date: 2026-03-12
authors: Jinxi Xiao (also with Heng'an Zhou, Ran Ji and Boyang Xia)
---

## Introduction

Recent progress in tracking, scene representation (3DGS {% cite 3dGS %}, NeRF {% cite nerf %}), and reconstruction (e.g., NeuS/VolSDF {% cite wang2021neus volsdf %} and COLMAP {% cite colmap %}) has made geometry and appearance recovery of static scenes increasingly mature. A natural next step is dynamic-scene understanding, including physically consistent motion modeling and interaction prediction. Although modern video and motion generation methods are promising, they rarely preserve accurate physical quantities, largely due to limited high-quality training data.

Simulation can partially alleviate data scarcity, but it is still limited in realism and interaction complexity. Dense multi-view capture systems require many calibrated and time-synchronized cameras, resulting in high deployment cost and constrained operating conditions (e.g., controlled indoor environments and marker-heavy workflows). Monocular methods, such as FoundationPose-style {% cite foundationposewen2024 %} 6D tracking, are attractive but fragile under object interactions, where occlusion and visual ambiguity degrade reliability (see [Figure 1](#fig-sam3)). These limitations motivate robust and scalable approaches grounded in physical measurements.

<figure id="fig-sam3" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/sam3.gif" alt="IMU Pose Tracking Demo" style="max-width: 100%; height: auto;">
  <figcaption><strong>Figure 1.</strong> Segmentation and tracking of dynamic objects using SAM3. The system fails due to heavily texture-repeated bowling pins and inter-object occlusions. </figcaption>
</figure>

A straightforward extension is to introduce additional sensing modalities. IMU-based human motion-capture systems (e.g., Xsens and Noitom) demonstrate key advantages: no line-of-sight requirement, resilience to occlusion, high-frequency measurements, and relatively low-cost mobile hardware. Following this intuition, we investigate whether attaching one IMU to each object enables direct sensing of inter-object dynamics.

Inspired by prior IMU-based trajectory estimation on pedestrians {% cite chen2018ionet ronin ctin %} and robotic platforms {% cite tartanimu airio autoOdom %}, we formulate object tracking as a motion-recovery problem from raw inertial streams (accelerometer + gyroscope). Instead of directly estimating full 6D pose through naive double integration, we prioritize learning stable intermediate motion quantities (e.g., velocity direction) and use them as a foundation for later trajectory reconstruction. Accordingly, this report is a feasibility study on inertial motion recovery rather than a full 6D pose-estimation/tracking system or visual-inertial-coupled system.

## Basics About the WitMotion 9-axis IMUs

Throughout this project, we employ WitMotion 9-axis WT901WIFI IMUs. Several sensor characteristics should be clarified before introducing the downstream method.

The WT901WIFI provides stable inertial measurements at 100 Hz, which is adequate for our object-level motion-capture setting. However, in most real-world environments we do not rely on the device-provided fused orientation. Its onboard fusion depends on accelerometer, gyroscope, and particularly magnetometer observations; in scenes containing metallic structures and nearby electronic equipment, magnetic disturbances are common and can substantially degrade yaw and overall attitude estimates. Accordingly, unless the environment is magnetically clean (i.e., with minimal metal and electromagnetic interference), the fused orientation output is treated as unreliable for downstream 6D tracking.

The Allan-variance {% cite AllanVarianceRos %} analysis (shown in [Figure 2](#fig-imu-allan)) reveals clear axis-dependent behavior in the accelerometer: the **z-axis exhibits substantially higher noise** and **greater bias instability** than the x- and y-axes.

<figure id="fig-imu-allan" style="margin: 1.5em auto;">
  <div style="display: flex; gap: 1rem; justify-content: center; align-items: flex-start; flex-wrap: wrap;">
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/acceleration.png" alt="Allan variance of accelerometer" style="max-width: 100%; height: auto;">
    </div>
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/gyro.png" alt="Allan variance of gyroscope" style="max-width: 100%; height: auto;">
    </div>
  </div>
  <figcaption><strong>Figure 2.</strong> Allan-variance curves of the WT901WIFI accelerometer (left) and gyroscope (right).</figcaption>
</figure>

In summary, the WT901WIFI is a practical low-cost IMU (approximately 100 RMB) that provides convenient 100 Hz measurements for dynamic-scene data collection. While it does not match the precision of premium devices (e.g., Xsens Movella Dot or Noitom sensors), it offers a favorable cost-performance trade-off for large-scale experimentation.

## Problem Formulation and Data Collection Protocol

We developed two experimental branches. The first branch targets full dynamic-scene capture: approximately 30 WT901WIFI units are attached to real objects in one scene, and a synchronized acquisition system fuses inertial streams with visual observations from Azure Kinect DK cameras. We also designed realistic interaction scripts to generate diverse motion patterns. Although this full-system branch is important for deployment, it is outside the scope of the present report.

This report focuses on the second branch, which investigates whether velocity can be reliably recovered from IMU signals. To obtain scalable and reproducible training data, we adopt a robot-assisted pipeline. Specifically, an IMU is mounted on the end-effector of an xArm6 using custom 3D-printed fixtures. The robot executes predefined motion programs, enabling collection of high-quality inertial sequences with controlled kinematics for model training and evaluation.

At this stage, the central technical question is whether accurate velocity can be recovered from a single low-cost IMU in our setting. Prior studies, such as RoNIN {% cite ronin %} and TartanIMU {% cite tartanimu %}, have demonstrated promising results, but under specific assumptions:
- These methods learn a mapping from a window of inertial data to the average velocity of that window, i.e., $$[\boldsymbol{\omega}_{1:t},\mathbf{a}_{1:t}] \rightarrow \bar{\mathbf{v}}$$. From a physical perspective, however, integrating acceleration over a finite window yields a velocity increment $$\Delta \mathbf{v}$$ rather than an absolute velocity. Some argue that the model learns a data-driven mapping from IMU sequences to velocity that is valid within the **distribution of motions** seen during training, and this process can be viewed as "locally anchored velocity estimations".
- Existing benchmark platforms (e.g., pedestrians, legged robots, and mobile robots) often exhibit relatively structured motion statistics, such as quasi-periodic gait patterns. This structural regularity can implicitly support velocity regression, yet the effective motion-distribution assumptions are rarely quantified explicitly.
- In contrast, our target setting involves arbitrary object motions, because the IMU may be attached to diverse objects with distinct and non-periodic dynamics. This regime is less explored in prior work. Therefore, instead of directly regressing velocity magnitude and direction jointly, we first study **velocity direction classification** to improve robustness against sensor noise and bias.

## Method and Experiments

This section presents the model design and a staged experimental study. To improve readability, we replace internal numeric dataset IDs with semantic names and keep the original IDs in parentheses:

- **AXIS-7** <!--(original: 0121)-->: 7-class axis-aligned motion dataset.
- **DIR27-L** <!--(original: 0123)-->: 27-class directional dataset, larger split (200 sequences/class).
- **DIR27-S** <!--(original: 0126)-->: 27-class directional dataset, smaller split (100 sequences/class).
- **POLY-27** <!--(new polyline set)-->: 27-class zigzag/polyline motion dataset.

The xArm6 recording procedures for linear and polyline trajectories are shown in [Figure 3](#fig-recording).

<figure id="fig-recording" style="margin: 1.5em auto;">
  <div style="display: flex; gap: 1rem; justify-content: center; align-items: flex-start; flex-wrap: wrap;">
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/linear.gif" alt="xArm6 linear trajectory recording" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(a) Linear trajectory recording</em></div>
    </div>
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/polyline.gif" alt="xArm6 polyline trajectory recording" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(b) Polyline trajectory recording</em></div>
    </div>
  </div>
  <figcaption><strong>Figure 3.</strong> Robot-assisted IMU data recording with xArm6 under two motion programs: straight-line motion (left) and waypoint-driven polyline motion (right).</figcaption>
</figure>

### Backbone: iTransformer

IMU windows are multivariate time-series signals. To model temporal dependencies while maintaining Transformer scalability, we build our backbone on iTransformer {% cite iTransformer %}, where time points from each series are embedded as variate tokens. Following RoNIN {% cite ronin %}, we additionally use a 1D convolution-based embedding module for raw inertial features and add learnable position encoding on the temporal domain. The full architecture is shown in [Figure 4](#fig-arch).

<figure id="fig-arch" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/arch.svg" alt="Arch" style="max-width: 75%; height: auto;">
  <figcaption><strong>Figure 4.</strong> Overview of the proposed inertial-motion network based on iTransformer with 1D convolutional embedding and learnable position encoding.</figcaption>
</figure>

We first train and evaluate the model on the public RoNIN dataset {% cite ronin %}, which contains large-scale human inertial trajectories. This stage is intended to verify whether the proposed architecture can learn meaningful motion information from IMU streams before moving to our self-collected setting. We compare against representative baselines and report ATE/RTE (lower is better):

|                | RONIN-ResNet {% cite ronin %} | CTIN {% cite rao2022ctin %} | iMoT {% cite nguyen2025imot %} | DiffusionIMU {% cite diffusionimu %} | M2EIT {% cite M2EIT %} |   Ours    |
| :------------: | :---------------------------: | --------------------------- | :----------------------------: | :----------------------------------: | :--------------------: | :-------: |
|  Seen ATE/RTE  |           3.70/2.78           | 4.62/2.81                   |           3.78/2.68            |              3.64/2.72               |       3.58/2.76        | 3.80/2.75 |
| Unseen ATE/RTE |           5.48/4.56           | 5.61/4.48                   |           5.31/4.39            |              5.27/4.31               |       5.19/4.57        | 5.47/4.61 |

Although the proposed model does not yet achieve state-of-the-art performance, the results indicate competitive accuracy and, more importantly, validate the feasibility of our design. We emphasize that this benchmark is used as a proof-of-capability study; exhaustive hyper-parameter tuning was intentionally not performed at this stage.

### Velocity Direction Classification

Instead of directly regressing velocity vectors, we first investigate a proxy task: classifying motion direction from raw IMU streams. The corresponding regression formulation can be written as $$\mathcal{f}([\boldsymbol{\omega}_{k:k+100},\mathbf{a}_{k:k+100}]) \rightarrow \bar{\mathbf{v}}$$. We organize experiments progressively by motion complexity.

#### Phase 1: Axis-Aligned Motion

We start with a 7-class setting: straight-line motions along the positive and negative directions of the three body axes ($$\pm x, \pm y, \pm z$$), plus a *static* class.

Data collection: We collect the **AXIS-7** dataset using xArm6 Cartesian velocity control (`vc_set_cartesian_velocity`). The dataset contains approximately 500 sequences (about 5 hours). To reduce orientation bias, we apply diverse initial in-plane and out-of-plane rotations before each straight-line segment, while keeping orientation fixed during the segment.

Preprocessing: Continuous streams are segmented into fixed temporal windows. Inputs are body-frame accelerometer and gyroscope measurements. A key step is gravity compensation: because the 3D-printed fixture aligns the IMU frame with the robot gripper frame, and the base is assumed level (gravity is vertical in the base frame), we compute gravity in the IMU body frame from robot forward kinematics (FK) and subtract it from acceleration.

Results: The model achieves approximately 95% accuracy/F1-score, indicating that with explicit gravity compensation, fundamental linear motions can be robustly separated despite varying initial orientations.

#### Phase 2: 27-Class Multi-Directional Motion

We then expand the label space to 27 directions, defined by quantizing each direction-vector component as $$x, y, z \in \{-1, 0, 1\}$$.

Data collection: We collect two datasets under the same protocol: **DIR27-L** (200 sequences/class, ~7.5 hours) and **DIR27-S** (100 sequences/class). Both include the same orientation augmentations as Phase 1.

Results and the "jump case": Intra-dataset training/testing (or training on the merged DIR27-L + DIR27-S set) yields about 90% accuracy. However, cross-dataset transfer reveals a substantial generalization gap:
- Train on DIR27-L, test on DIR27-S: accuracy drops to ~58%.
- Train on DIR27-S, test on DIR27-L: accuracy drops to ~53%.

As detailed in [Figure 5](#fig-jump-detail), the error patterns in both transfer directions are qualitatively similar. This suggests the issue is not dominated by one "bad" split, but rather by shared distribution mismatch and limited statistical coverage. A plausible interpretation is that larger and more diverse training data, together with stronger domain-generalization strategies, are necessary to learn stable physical features rather than dataset-specific artifacts.

<figure id="fig-jump-detail" style="margin: 1.5em auto;">
  <div style="display: flex; gap: 1rem; justify-content: center; align-items: flex-start; flex-wrap: wrap;">
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/train0123_test0126.png" alt="Train on DIR27-L test on DIR27-S" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(a) Train DIR27-L, test DIR27-S</em></div>
    </div>
    <div style="flex: 1 1 420px; max-width: 48%; min-width: 320px; text-align: center;">
      <img src="/assets/img/projects/imu-pose/train0126_test0123.png" alt="Train on DIR27-S test on DIR27-L" style="max-width: 100%; height: auto;">
      <div style="margin-top: 0.5em;"><em>(b) Train DIR27-S, test DIR27-L</em></div>
    </div>
  </div>
  <figcaption><strong>Figure 5.</strong> Cross-dataset jump-case diagnostics. The two transfer directions exhibit similar error structures, supporting the hypothesis that data diversity and domain-robust training are both insufficient at the current stage.</figcaption>
</figure>

To probe this failure mode, we further evaluate a rotation-equivariant augmentation strategy inspired by RIO {% cite cao2022RIO %}. The principle is that rotated inertial inputs should correspond to rotated velocity labels, i.e., $$\left([\boldsymbol{\omega}_{k:k+100},\mathbf{a}_{k:k+100}],\bar{\mathbf{v}}\right)$$ and $$\left([\mathbf{R}\boldsymbol{\omega}_{k:k+100},\mathbf{R}\mathbf{a}_{k:k+100}],\mathbf{R}\bar{\mathbf{v}}\right)$$ should be equivalent training samples.

In our setting, this augmentation degrades performance rather than improving it. A likely explanation is that practical non-idealities (e.g., axis-dependent sensor **bias** and controller-induced dynamics in xArm6 velocity execution) violate strict rotational equivalence. As an additional diagnostic, we perform a label-flip test on AXIS-7 by swapping the $$+y/-y$$ labels at evaluation time; the F1 score on the y-axis classes drops by ~25%, supporting the claim that the measured data distribution cannot be modeled as a simple rigid rotation of idealized inertial signals.

#### Phase 3: Polyline (Zigzag) Motions

To better approximate real trajectories with direction changes, we introduce waypoint-driven polyline motions. The IMU orientation remains fixed during each sequence, while instantaneous velocity direction changes over time.

Supervision strategy: Because motion within one window is no longer strictly linear, we define the target as the net displacement vector from the first to the last frame in the window, then map it to the **nearest** class among the same 27 directional bins.

Data collection: We collect the **POLY-27** dataset with 200 sequences/class following zigzag trajectories.

Results: Accuracy decreases to 49%. This indicates that the single-label-per-window assumption becomes invalid when trajectories are locally non-linear, even if their net displacement is well defined.

## Conclusions

Axis-aligned experiments show that direction classification is feasible under constrained motions with controlled orientation and accurate gravity compensation. However, three observations indicate limited robustness for unconstrained object dynamics: (1) a large cross-dataset generalization gap in DIR27 transfer, (2) failure of rotation-equivariant augmentation under real sensor/control non-idealities, and (3) substantial performance degradation on polyline trajectories where a single window label is insufficient.

Overall, these findings suggest that discrete direction classification is a useful diagnostic tool but not a sufficiently stable endpoint for practical inertial object tracking. We therefore conclude this stage of the project and release the analysis to support follow-up works.

## References

{% bibliography --cited %}
