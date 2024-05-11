---
layout: post
title: Fisher Information Matrix
date: 2024-05-11
description: Some basic knowledge of Fisher Information Matrix
tags: machine-learning
related_posts: false
---

## Declarations

1. $$\mathbf{X} $$ is a random variable whose domain is $$\mathbb{R} $$. And $$x \in \mathbb{R} $$ is a sample.

2. $$\theta \in \mathbb{R}^k $$ to be parameter of the distribution. And we will adopt the understanding from the statistical school, which means that $$\theta$$ is an unknown instead of a random variable.

3. Suppose the true value of $$\theta $$ is $$\pi $$, that is, $$\mathbf{X} \sim \mathcal{M}(\pi) $$, and the corresponding PDF would be $$p(\mathbf{X};\theta)$$

4. $$\mathcal{L}(\theta \vert \mathbf{X})$$ is the likelihood function. Notice that the definition here is quite different from [wiki](https://en.wikipedia.org/wiki/Likelihood_function), it is the due to the fact that we may need this definition to calculate the expectation. From the other hand, we can interpret it as a function of both $$\theta$$ and the random variable $$\mathbf{X}$$. And you may have noticed that, the likelihood function is now a random variable, determined by $$\theta$$, and has the same distribution with $$\mathbf{X}$$. Since in normal case $$\mathcal{L}(\theta\vert x) \propto p(\mathbf{X}=x;\theta) $$, we can ignore the scale ambiguity(since the scale will be a constant after $$\ln$$ operation). Therefore, in this blog, $$\mathcal{L}(\theta \vert \mathbf{X})$$ is equivalent to $$p(\mathbf{X};\theta)$$

5. We define the score function(first derivative $$\in \mathbb{R}^k $$) to be 
   $$\begin{equation}
    \mathbf{s}(\theta) = \nabla_{\theta} \mathcal{L}(\theta \vert \mathbf{X}) = \nabla_{\theta} \ln p(\mathbf{X};\theta)
   \end{equation}$$
   
   Notice that $$\mathbf{s}(\theta) $$ has the same distribution as $$X$$ and we can further conclude
   $$\begin{equation}
    \mathbf{s}(\theta) = \frac{\nabla_{\theta} p(\mathbf{X};\theta)}{p(\mathbf{X};\theta)}
   \end{equation}$$
   as well as the second order derivative of the likelihood function:

   $$\begin{equation}
   \begin{aligned}
    \nabla_{\theta}^2 \ln p(\mathbf{X};\theta) &= \frac{p(\mathbf{X};\theta) \nabla_{\theta}^2 p(\mathbf{X};\theta) - \nabla_{\theta} p(\mathbf{X};\theta)\nabla_{\theta} p(\mathbf{X};\theta)^T}{p(\mathbf{X};\theta)^2} \\
     &= \frac{\nabla_{\theta}^2 p(\mathbf{X};\theta)}{p(\mathbf{X};\theta)} - \mathbf{s}(\theta)\mathbf{s}(\theta)^T
    \end{aligned}
   \end{equation}$$
   where $$\nabla_{\theta}^2 p(\mathbf{X};\theta) \in \mathbb{R}^{k\times k} $$.

## All the calculations

Claim: When $$\theta$$ is chosen as the the true value, which is $$\pi$$, the the expected value (the first moment) of the score, evaluated at the true parameter value is 0:

*Proof:*
$$\begin{equation}
    \begin{aligned}
   \mathbb{E}[\mathbf{s}(\pi)]
   &=\int_\mathbb{R}\nabla_{\theta=\pi}\ln p(\mathbf{X};\theta) p(\mathbf{X};\pi) dx \\
   &=\int_\mathbb{R}\frac{\nabla_{\theta=\pi} p(\mathbf{X};\theta)}{p(\mathbf{X};\pi)}p(\mathbf{X};\pi) dx \\
   &=\int_\mathbb{R}\nabla_{\theta=\pi} p(\mathbf{X}; \theta) dx \\
   &=\nabla_{\theta=\pi}\int_\mathbb{R} p(\mathbf{X};\theta) dx \\
   &=\nabla1 \\
   &=0
\end{aligned}
\end{equation}$$

Definition: We define the fisher information matrix as the variance of the score:

$$\begin{equation}
    \begin{aligned}
        F &= Var(\mathbf{s}(\pi)) \\
        &= \mathbb{E}[(\mathbf{s}(\pi)-\mathbb{E}(\mathbf{s}(\pi)))(\mathbf{s}(\pi)-\mathbb{E}(\mathbf{s}(\pi)))^T] \\
        &= \mathbb{E}[\mathbf{s}(\pi)\mathbf{s}(\pi)^T]
    \end{aligned}
\end{equation}$$

and notice that 

$$\begin{equation}
    \begin{aligned}
        \mathbb{E}[\frac{\nabla_{\theta=\pi}^2 p(\mathbf{X};\theta)}{p(\mathbf{X};\pi)}] &= \int_\mathbb{R} \frac{\nabla_{\theta=\pi}^2 p(\mathbf{X};\theta)}{p(\mathbf{X};\pi)} p(\mathbf{X};\pi) dx \\
        &= \int_\mathbb{R} \nabla_{\theta=\pi}^2 p(\mathbf{X};\theta) dx \\
        &= \nabla_{\theta=\pi}^2 \int_\mathbb{R} p(\mathbf{X};\theta) \\
        &= 0
    \end{aligned}
\end{equation}$$

As a result, with equation (3), (5) and (6), we can find that 

$$\begin{equation}
    F = -\mathbb{E}[\nabla_{\theta=\pi}^2 \ln p(\mathbf{X};\theta)]
\end{equation}$$

Conclusion: Fisher Information matrix is **a negative expected value of Hesian of the log-probability under the true value of the parameter**.

## About Gaussian Distribution

If you are interested in what's the relationship between hessian matrix as well as the covariance matrix, please see [Relationship between the Hessian and Covariance Matrix for Gaussian Random Variables](https://onlinelibrary.wiley.com/doi/pdf/10.1002/9780470824566.app1)


## Reference

1. [Relationship between Hessian Matrix and Covariance Matrix](https://stats.stackexchange.com/questions/261796/relationship-between-hessian-matrix-and-covariance-matrix)
2. [Introduction to Maximum Likelihood Estimation](https://faculty.washington.edu/cadolph/mle/topic2.p.pdf)
3. [Information Matrix](https://statlect.com/glossary/information-matrix)
4. [Fisher Information Matrix](https://agustinus.kristia.de/techblog/2018/03/11/fisher-information/)
5. [Fisher Information](https://en.wikipedia.org/wiki/Fisher_information#cite_note-SubaRao-6)
