---
layout: page
title: LiDAR-GTA-V
description: A plugin for Grand Theft Auto V that generates LiDAR point cloud from the game environment automatically.
img: assets/img/projects/lidar-gtav/traffic.png
importance: 1
category: Research
related_publications: false
---

{% if site.data.repositories.lidar-gta-v %}

<div class="repositories d-flex flex-wrap flex-md-row flex-column justify-content-between align-items-center">
  {% for repo in site.data.repositories.lidar-gta-v %}
    {% include repository/repo.liquid repository=repo %}
  {% endfor %}
</div>
{% endif %}

<p></p>

## Motivations

As like any other sensors, there are errors within measurements from `LiDAR`. In order to obtain *clean* data, we can directly make use of the simulation environment, for example, the game [GTA-V](https://www.rockstargames.com/gta-v). And to improve the efficiency, I write a script to collect data automatically.

