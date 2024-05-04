---
layout: post
title: Matrix Basis
date: 2024-05-04
description: As a reminder to some bases of the matrix.
tags: linear-algebra
related_posts: false
toc:
    beginning:  true
---

<style>
r { color: Red }
b { color: Blue }
g { color: Green }
</style>

***This blog is only used as a reminder.***

***Look for [https://si231.sist.shanghaitech.edu.cn/](https://si231.sist.shanghaitech.edu.cn/) and [https://github.com/xiaojxkevin/Linear-Algebra-1-fall23](https://github.com/xiaojxkevin/Linear-Algebra-1-fall23) for more details***

## Notations and Conventions

### Trace

1. $$tr(A^T) = tr(A) $$
2. $$tr(A+B) = tr(A) + tr(B) $$
3. $$tr(AB) = tr(BA) $$
   - $$tr(xy^T) = x^Ty $$
   - $$tr(ABC) = tr(BCA) = tr(CAB) $$
  
### Band matrices
$$:=$$ A matrix $$A \in \mathbb{R}^{n\times n} $$ is said to be a band matrix if all matrix elements are zero outside a diagonal ordered band, i.e.

$$a_{ij} = 0 \quad \text{if} \quad i > j + p \ \text{or} \ j > i + q $$

where $$p, q \geq 0$$

### Toeplitz matrices

$$:=$$ matrices with constant diagonals (may not be square)

$$A=\begin{bmatrix}
a_{0} & a_{-1} & a_{-2} & \cdots  & \cdots  & a_{-( n-1)}\\
a_{1} & a_{0} & \ddots  & \ddots  &  & \vdots \\
a_{2} & a_{1} & \ddots  & \ddots  & \ddots  & \vdots \\
\vdots  & \ddots  & a_{1} & \ddots  & a_{-1} & a_{-2}\\
\vdots  &  & \ddots  & a_{1} & a_{0} & a_{-1}\\
a_{n-1} & \cdots  & \cdots  & a_{2} & a_{1} & a_{0}
\end{bmatrix}$$

### Involutory matrices

$$:=$$ matrix $$A$$ is involutory if and only if $$A^2=I$$

### Idempotent  matrices

$$:=$$ matrix $$A$$ is idempotent if and only if $$A^2=A$$

## Rank

1. $$rank(A) = rank(A^T) = rank(A^TA)$$
2. $$rank(AB) \leq \min\{rank(A), rank(B)\}$$.  And the equality holds when $$A$$ has full row rank or $$B$$ has full column rank.
3. For $$A \in \mathbb{R}^{m\times p}$$ and $$B \in \mathbb{R}^{p\times n}$$,   $$rank(AB) \geq rank(A) + rank(B) - n$$
4. $$A$$ is said to have <b>low rank</b> when its rank is significantly less than the maximum rank possible for the matrix.

## Orthogonal

A matrix is said to be orthogonal(<b>unitary</b>) if it is real(complex), square and columns are orthonormal.

### Permutation matrix

$$:=$$ $$Q$$ has exactly one element equal to 1 in each row and each column. 

As a result, $$Q^TQ=I$$ since

$$[Q^TQ]_{ij} = \sum_{k=1}^n [Q^T]_{ik}[Q]_{kj} = \sum_{k=1}^n [Q^T]_{ki}[Q]_{kj} = \begin{cases}
    1, & i = j\\
    0, & \text{otherwise}
\end{cases} $$



## Multiplication

Define $$A \in \mathbb{R}^{m\times p}$$ and $$B \in \mathbb{R}^{p\times n}$$, $$AB$$ is equivalent to 
1. Performing column combinations based on columns of $$A$$ with elements in the column of $$B$$ as coefficients.
2. Performing row combinations based on rows of $$B$$ with elements in the row of $$A$$ as coefficients.

$$  \begin{array}{l}
AB=A\begin{bmatrix}
B_{1} & \dotsc  & B_{n}
\end{bmatrix} =\begin{bmatrix}
\sum _{j=1}^{p} B_{j1} A_{j} & \cdots  & \sum _{j=1}^{p} B_{jn} A_{j}
\end{bmatrix}\\
AB=\begin{bmatrix}
a_{1}^{T} B\\
\vdots \\
a_{m}^{T} B
\end{bmatrix} =\begin{bmatrix}
\sum _{i=1}^{p} a_{1i} b_{i}^{T}\\
\vdots \\
\sum _{i=1}^{p} a_{mi} b_{i}^{T}
\end{bmatrix}\\
AB\ =\ \begin{bmatrix}
a_{1}^{T}\\
\vdots \\
a_{m}^{T}
\end{bmatrix}\begin{bmatrix}
B_{1} & \dotsc  & B_{n}
\end{bmatrix}\\
AB\ =\ \sum _{i=1}^{p} Ae_{i} e_{i}^{T} B=\sum _{i=1}^{p} A_{i} b_{i}^{T}
\end{array}$$

### Schur complement

Let 

$$M\ =\ \begin{bmatrix}
A & B\\
C & D
\end{bmatrix}$$

where $$A\in \mathbb{R}^{m\times m}, B\in \mathbb{R}^{m\times n}, C\in\mathbb{R}^{n\times m} $$ and $$D\in \mathbb{R}^{n\times n} $$.

1. If $$A$$ is invertible, then the Schur complement of $$A$$ in $$M$$ is defined by

    $$S_A = D - CA^{-1}B $$
    
    then

    $$M=\ \begin{bmatrix}
   I & 0\\
   CA^{-1} & I
   \end{bmatrix} \ \begin{bmatrix}
   A & 0\\
   0 & S_A
   \end{bmatrix} \ \begin{bmatrix}
   I & A^{-1} B\\
   0 & I
   \end{bmatrix} $$

2. If $$D$$ is invertible, then the Schur complement of $$D$$ in $$M$$ is defined by

    $$S_D = A - BD^{-1}C $$
    
    then

    $$M=\ \begin{bmatrix}
   I & BD^{-1} \\
   0 & I
   \end{bmatrix} \ \begin{bmatrix}
   S_D & 0\\
   0 & D
   \end{bmatrix} \ \begin{bmatrix}
   I & 0\\
   D^{-1}C & I
   \end{bmatrix} $$
