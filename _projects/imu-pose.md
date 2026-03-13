---
layout: project
title: Tracking via Active Inertial Sensing
date: 2026-03-12
authors: Jinxi Xiao
---

## Introduction

Recent progress in tracking, scene representation (3DGS {% cite 3dGS %}, NeRF {% cite nerf %}), and reconstruction (e.g., NeuS/VolSDF {% cite wang2021neus volsdf %} and COLMAP {% cite colmap %}) has made geometry and appearance recovery of static scenes increasingly mature. A natural next step is dynamic-scene understanding, including physically consistent motion modeling and interaction prediction. Although modern video and motion generation methods are promising, they rarely preserve accurate physical quantities, largely due to limited high-quality training data.

Simulation can partially alleviate data scarcity, but it is still limited in realism and interaction complexity. Dense multi-view capture systems require many calibrated and time-synchronized cameras, resulting in high deployment cost and constrained operating conditions (e.g., controlled indoor environments and marker-heavy workflows). Monocular methods, such as FoundationPose-style {% cite foundationposewen2024 %} 6D tracking, are attractive but fragile under object interactions, where occlusion and visual ambiguity degrade reliability (see [Figure 1](#fig-sam3)). These limitations motivate robust and scalable approaches grounded in physical measurements.

<figure id="fig-sam3" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/sam3.gif" alt="IMU Pose Tracking Demo" style="max-width: 100%; height: auto;">
  <figcaption><strong>Figure 1.</strong> Segmentation and tracking of dynamic objects using SAM3. The system fails due to heavily texture-repeated bowling pins and inter-object occlusions. </figcaption>
</figure>

A straightforward extension is to introduce additional sensing modalities. IMU-based human motion-capture systems (e.g., Xsens and Noitom) demonstrate key advantages: no line-of-sight requirement, resilience to occlusion, high-frequency measurements, and relatively low-cost mobile hardware. Following this intuition, we investigate whether attaching one IMU to each object enables direct sensing of inter-object dynamics.

Inspired by prior IMU-based trajectory estimation on pedestrians {% cite chen2018ionet ronin ctin %} and robotic platforms {% cite tartanimu airio autoOdom %}, we formulate object tracking as a motion-recovery problem from raw inertial streams (accelerometer + gyroscope). Instead of directly estimating full 6D pose through naive double integration, we prioritize learning stable intermediate motion quantities (e.g., velocity) and use them as a foundation for subsequent trajectory reconstruction. This project therefore emphasizes feasibility analysis of inertial motion recovery; while the final objective is full 6D pose tracking, the current stage does not yet achieve complete and reliable 6D recovery.

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

In this section, we first discuss the design of the neural network we are using and then the dataset collected and its results.

### Backbone: iTransformer

IMU windows are multivariate time-series signals. To model temporal dependencies while maintaining Transformer scalability, we build our backbone on iTransformer {% cite iTransformer %}, where time points from each series are embedded as variate tokens. Following RoNIN {% cite ronin %}, we additionally use a 1D convolution-based embedding module for raw inertial features and add learnable position encoding on the temporal domain. The full architecture is shown in [Figure 3](#fig-arch).

<figure id="fig-arch" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/arch.svg" alt="Arch" style="max-width: 75%; height: auto;">
  <figcaption><strong>Figure 3.</strong> Overview of the proposed inertial-motion network based on iTransformer with 1D convolutional embedding and learnable position encoding.</figcaption>
</figure>

We first train and evaluate the model on the public RoNIN dataset {% cite ronin %}, which contains large-scale human inertial trajectories. This stage is intended to verify whether the proposed architecture can learn meaningful motion information from IMU streams before moving to our self-collected setting. We compare against representative baselines and report ATE/RTE (lower is better):

|                | RONIN-ResNet {% cite ronin %} | CTIN {% cite rao2022ctin %} | iMoT {% cite nguyen2025imot %} | DiffusionIMU {% cite diffusionimu %} | M2EIT {% cite M2EIT %} |   Ours    |
| :------------: | :---------------------------: | --------------------------- | :----------------------------: | :----------------------------------: | :--------------------: | :-------: |
|  Seen ATE/RTE  |           3.70/2.78           | 4.62/2.81                   |           3.78/2.68            |              3.64/2.72               |       3.58/2.76        | 3.80/2.75 |
| Unseen ATE/RTE |           5.48/4.56           | 5.61/4.48                   |           5.31/4.39            |              5.27/4.31               |       5.19/4.57        | 5.47/4.61 |

Although the proposed model does not yet achieve state-of-the-art performance, the results indicate competitive accuracy and, more importantly, validate the feasibility of our design. We emphasize that this benchmark is used as a proof-of-capability study; exhaustive hyper-parameter tuning was intentionally not performed at this stage.

### Self-Collected 



## References

{% bibliography --cited %}
