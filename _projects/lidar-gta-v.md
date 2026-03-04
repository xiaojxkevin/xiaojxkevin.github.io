---
layout: project
title: "LiDAR-GTA-V: Synthetic LiDAR Point Cloud Generation in GTA V"
date: 2023-08-08
authors: Jinxi Xiao
code: https://github.com/xiaojxkevin/LiDAR-GTA-V
---

## Overview

**LiDAR-GTA-V** is a plugin for Grand Theft Auto V that automatically generates outdoor semantically labeled LiDAR point clouds from the game environment. It is forked from [UsmanJafri/LiDAR-GTA-V](https://github.com/UsmanJafri/LiDAR-GTA-V) and extended with the automation feature.

The plugin leverages GTA-V's rich, photorealistic simulation environment as a source of free, labeled synthetic data for autonomous driving and 3D perception research — a valuable complement to real-world datasets.

<img src="/assets/img/projects/lidar-gta-v/traffic.png" alt="Traffic scene in GTA-V" style="width: 60%; display: block; margin: 0 auto;">

## Output Format

Each captured frame is saved as a `.txt` file under `#game_directory#/data_set/{index}.txt`. Every line in the file represents one point in the point cloud with the following fields:

$$
(x,\ y,\ z,\ r,\ g,\ b,\ n_x,\ n_y,\ n_z)
$$

where $(x, y, z)$ is the 3D position, $(r, g, b)$ encodes the **semantic label** via vertex color, and $(n_x, n_y, n_z)$ is the surface normal.

## Semantic Color Coding

The RGB color channel is used to encode object categories, enabling automatic semantic segmentation of the point cloud:

| Color | Category |
|-------|----------|
| 🔴 Red | Vehicles |
| 🟢 Green | Humans & Animals |
| 🔵 Blue | Game Props |
| ⚪ White | Roads, Buildings & other hittable textures |
| ⚫ Black | No hit (empty rays) |

## Installation

1. Install [ScriptHookV](http://www.dev-c.com/gtav/scripthookv/) following its accompanying instructions.
2. Install the [Autonomous Driving mod](https://www.gta5-mods.com/scripts/seamless-autonomous-driving-mod-no-keys-menus-or-buttons) and its dependencies to enable automatic vehicle movement.
3. Copy `LiDAR GTA V.asi` and the `LiDAR GTA V` folder from the latest [release](https://github.com/UsmanJafri/LiDAR-GTA-V/releases) into your GTA V installation directory (the folder containing `GTAV.exe`).
4. Create a `data_set` folder in your GTA V directory.

## How to Use

1. Edit the configuration file at `#game_directory#/LiDAR GTA V/LIDAR GTA V.cfg` and update the absolute path to this file inside `lidar.cpp`.
2. Start GTA V in story mode.
3. Press `F6` to load the config and begin data collection when ready.
4. Follow the on-screen notification prompts.
5. Collected point clouds will appear under `#game_directory#/data_set/`.

## Developer Notes

- Requires **Visual Studio 2022** or higher with the *Desktop development with C++* workload.
- Targets Visual Studio Platform Toolset **v143**.
- After building, the compiled `.asi` plugin is automatically copied to `D:\Games\GTAV\`. Update the post-build event path in the project settings to match your GTA V installation.

## Acknowledgements

This project is based on [UsmanJafri/LiDAR-GTA-V](https://github.com/UsmanJafri/LiDAR-GTA-V). The GTA V native API reference used during development can be found at [docs.fivem.net](https://docs.fivem.net/natives/).
