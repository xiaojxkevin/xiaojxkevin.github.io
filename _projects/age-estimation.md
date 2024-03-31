---
layout: page
title: Human Age Estimation on Facial Images
description: Project for Introduction to Machine Learning (CS182) Fall23 ShanghaiTech.
importance: 2
category: Course
related_publications: false
---

{% if site.data.repositories.age_estimation %}

<div class="repositories d-flex flex-wrap flex-md-row flex-column justify-content-between align-items-center">
  {% for repo in site.data.repositories.age_estimation %}
    {% include repository/repo.liquid repository=repo %}
  {% endfor %}
</div>
{% endif %}

<p></p>

## Description

This project is for course *Introduction to Machine Learning*, in which we try to solve the problem of estimating human age based on the facial image. In this project, we have implemented several traditional machine learning techniques, like KNN, SVM etc. as well as deep learning methods. In addition, we have come up with a *coarse-to-fine* procedure to further improve the accuracy.

More info can be found at the repo above, and here's our [report](https://github.com/xiaojxkevin/age_estimation/blob/master/iml_final_report.pdf).
