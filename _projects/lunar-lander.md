---
layout: page
title: Lunar Lander
description: Project for Artificial Intelligence (CS181) Fall23 ShanghaiTech
img: assets/img/projects/lunar-lander/process.gif
importance: 1
category: Course
related_publications: false
---

{% if site.data.repositories.lunarlander %}

<div class="repositories d-flex flex-wrap flex-md-row flex-column justify-content-between align-items-center">
  {% for repo in site.data.repositories.lunarlander %}
    {% include repository/repo.liquid repository=repo %}
  {% endfor %}
</div>
{% endif %}

<p></p>

## Description

This project is for course *Artificial Intelligence*, where we try to use Reinforcement Learning and many other methods to solve the problem of *lunar lander*. 

More info can be found at the repo above, and here's our [report](https://github.com/xiaojxkevin/lunarlander/blob/main/ai_final_report.pdf).
