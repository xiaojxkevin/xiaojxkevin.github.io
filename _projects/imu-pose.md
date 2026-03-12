---
layout: project
title: "6D Pose Tracking via Active Inertial Sensing"
date: 2026-03-12
authors: Jinxi Xiao
---

## Motivation

With recent advances in tracking, representations (3DGS {% cite 3dGS %}, NeRF {% cite nerf %}), reconstruction (neural surface methods such as NeuS/VolSDF {% cite wang2021neus volsdf %} and robust photogrammetry via COLMAP {% cite colmap %}), recovering the shape and appearance of static scenes can be viewed as largely solved. The next step, could be understanding real, dynamic scenes: to represent physics, predict motions etc. Contemporary video and motion generation gesture would help, but they rarely capture accurate physical properties, largely because the lack of training data.  

Simulation could help, but it is confined to simple synthetic setups compared to the real dynamics. Dense multi-view systems demand tens or more calibrated, time-synchronized cameras to faithfully recover motion, making them expensive and restricted to certain conditions (such as indoor and optical marker-demanding). Single-camera approaches (e.g., FoundationPose-style~\cite{foundationposewen2024} 6D tracking) are appealing, but struggle when objects interact-occlusions, ambiguities and collisions degrade sight reliability (an example is shown in [Figure 1](#fig-sam3)). The field needs approaches that are robust, scalable, and grounded in physical signals.

<figure id="fig-sam3" style="text-align: center; margin: 1.5em auto;">
  <img src="/assets/img/projects/imu-pose/sam3.gif" alt="IMU Pose Tracking Demo" style="max-width: 100%; height: auto;">
  <figcaption><strong>Figure 1.</strong> Segmentation and tracking of dynamic objects using SAM3. The system fails due to heavily texture-repeated bowling pins and inter-object occlusions. </figcaption>
</figure>

A straight-forward idea would to include extra multi-modality sensors: IMU-based human motion capture (e.g., Xsens and Noitom) shown clear advantages: no line-of-sight requirement, resilience to occlusion, high-frequency inertial measurements, and mobile, low-cost hardware. Extending this idea, we explore the question: what if we mount an IMU on every object in the scene, letting inter-object interactions be read directly from inertial signals?

Inspired by previous works that attach IMUs on pedestrians {% cite chen2018ionet ronin ctin %} for planar dead-reckoning and on robot platforms {% cite tartanimu airio autoOdom %} for locomotion, we try to track the 6D poses of objects mounted with IMUs by recovering velocity vectors from raw inertial readings including accelerations and angular velocities.

## References

{% bibliography --cited %}
