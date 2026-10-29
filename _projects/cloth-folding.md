---
layout: project
title: 'Cloth Folding with $\pi_{0.5}$: DAgger and End-Effector Auxiliary Learning'
description: 'A real-robot study of $\pi_{0.5}$ cloth folding on dual PiPER arms, examining corrective data and end-effector pose supervision.'
authors: Ran Ji, Yikai Liu, Mingxi Li, Jinxi Xiao
date: 2026-07-01
---

## Overview

We reproduce and extend $\pi_{0.5}$-based {% cite pi05 %} **cloth folding** on a dual-arm PiPER robot, covering the sequence of retrieving a garment from a basket, flattening it, folding it, and stacking it. The central challenge is maintaining progress when execution departs from a clean demonstration: a grasp misses, the garment slips, or a fold leaves the cloth in an unexpected configuration.

This project examines two ways to improve execution. **DAgger-style corrective data** {% cite hg-dagger RaC %} supplies recovery behavior at states encountered by the policy itself. **End-effector (EE) auxiliary learning** supplements joint-action prediction with geometrically meaningful pose targets. Our small-scale evaluations favor corrective data over additional ordinary demonstrations, and show a further promising improvement with EE supervision in a separate comparison.

<figure style="margin: 1.5em auto;">
  <video controls playsinline preload="metadata" poster="{{ '/assets/img/projects/cloth-folding/teaser.jpg' | relative_url }}" style="display: block; width: 100%; border-radius: 8px;">
    <source src="{{ '/assets/videos/cloth-folding/demo.mp4' | relative_url }}" type="video/mp4">
    Your browser does not support embedded video. <a href="{{ '/assets/videos/cloth-folding/demo.mp4' | relative_url }}">Download the demonstration video.</a>
  </video>
  <figcaption><strong>System demonstration.</strong> Cloth manipulation on the dual-arm platform. The robot retrieves, flattens, folds, and stacks garments.</figcaption>
</figure>

## Platform and Training

We use dual AgileX PiPER arms with two wrist-mounted D435 cameras and a head-mounted ZED camera. Starting from the $\pi_{0.5}$ pretrained checkpoint, we fine-tune for 20,000 steps with batch size 64 using the `openpi` pipeline. The dataset contains approximately 560,000 frames; DAgger variants mix corrective data with demonstrations.

Each evaluation covers **ten garments in groups of 4 + 4 + 2**, with varying initial conditions. We report garment-level success counts; the small sample size limits the strength of the comparisons.

## Learning to Recover with DAgger

Ordinary demonstrations teach the intended task sequence, but provide limited coverage of states caused by the policy's own errors. For example, a demonstration-only policy may repeatedly attempt a grasp at essentially the same unsuccessful location. Human intervention during rollout can instead show how to reposition the gripper and resume the task.

We collect corrective trajectories by intervening during policy execution and mix the resulting data with demonstrations. We compare additional ordinary demonstrations, intervention segments alone, and trajectories containing both autonomous execution and intervention.

### Data Composition and Advantage Conditioning

We compare 52 demonstration episodes against adding either 15 demonstrations or 15 DAgger episodes, with four garments per episode. All DAgger variants retain the original demonstrations and differ in whether they include autonomous rollout segments and advantage conditioning.

Following $\pi^{*}_{0.6}$ {% cite pi*06 %}, advantage labels condition supervised training: demonstrations are positive, autonomous segments are manually labeled negative or neutral, and intervention segments are positive except for static frames identified by action differences.

| Training group | Added data | Autonomous rollout segments | Advantage conditioning | Evaluation A | Evaluation B |
| :-- | :-- | :--: | :-- | :--: | :--: |
| Original demonstrations | None | — | — | 3/10 | — |
| Demo + demo | 15 demonstrations | — | — | 3/10 | 2/10 |
| Demo + DAgger | Intervention segments from 15 episodes | No | Not separately documented | 7/10 | 4/10 |
| Demo + DAgger | Intervention + autonomous segments from 15 episodes | Yes | Without labels | — | 7/10 |
| Demo + DAgger | Intervention + autonomous segments from 15 episodes | Yes | With advantage labels | 8/10 | 7/10 |

Results count successes out of ten garments; “—” denotes unavailable or inapplicable entries. Evaluation B uses harder initial configurations, so compare methods within each column. The last two rows isolate advantage conditioning.

### What the Comparison Shows

**Corrective data is more useful here than another 15 ordinary demonstrations.** Both evaluations favor demo + DAgger over demo + demo. Equal numbers of added episodes do not establish equal recording time or human effort, so this comparison concerns the usefulness of the collected data rather than a measured improvement in annotation efficiency.

**Retaining autonomous rollout segments is also useful in these evaluations.** Intervention-only training reaches 7/10 and 4/10, while the mixture with autonomous segments and advantage labels reaches 8/10 and 7/10. In Evaluation B, the mixture without advantage labels also reaches 7/10. Advantage conditioning therefore does not improve the aggregate success count in that comparison.

The behavior is consistent with learning recovery actions. A demonstration-only policy often retries an unsuccessful grasp at nearly the same location; with corrective data, it adjusts the grasp position. Including annotated autonomous segments also produces examples of more direct recovery, avoiding an unnecessary retreat before trying again. These are qualitative observations rather than separately measured recovery rates.

Data quality remains important: pauses around human handovers can teach hesitant or stalled motion. The distinction between useful corrections, idle actions, and unsuccessful autonomous behavior matters alongside the choice of which trajectories to retain.

## End-Effector Pose as an Auxiliary Task

The policy executes joint actions. During training, we additionally ask it to predict future end-effector poses. These targets are computed through forward kinematics from the recorded joint states and action sequences, providing geometric supervision without an additional manual labeling process.

The model appends three EE token sequences alongside the joint-action sequence. Each sequence spans the action horizon and has its own input projection and output decoder, while learning through the shared action-expert network.

**The EE targets use different representations for relative motion and absolute pose.** The implementation was explicitly changed from a 9-value relative pose (6D rotation plus translation) to a 6-value relative pose (rotation vector plus translation), while retaining the 18-value dual-arm absolute target.

| Target | Reference frame | Rotation representation | Values per horizon step |
| :-- | :-- | :-- | :--: |
| Left / right relative EE | That arm's current EE frame | 3-value axis-angle rotation vector | 6 per arm |
| Dual-arm absolute EE | Each arm's own base frame | First two rotation-matrix columns, concatenated | 9 per arm, 18 together |

For each arm, let the current measured joints give pose $(R_0,p_0)$ and the recorded action at horizon step $j$ give pose $(R_j,p_j)$ through forward kinematics. The relative target uses

$$
\begin{aligned}
\Delta R_j &= R_0^{\top}R_j, \\
\Delta p_j &= R_0^{\top}(p_j-p_0).
\end{aligned}
$$

The encoded target places the three components of the rotation vector of $\Delta R_j$ before the three components of $\Delta p_j$, with angles in radians and translation in meters. Every step in the chunk is relative to the same current pose, rather than to the preceding action. This is a rigid-transform difference, not subtraction of Euler angles. Its reference frame is the current EE frame; assigning wrist-camera observations to the branch does not make it a camera-frame target.

A useful interpretation of this choice is to pair local motion supervision with wrist observations: a small relative rotation has a small rotation vector, and no motion maps to the zero 6-vector. The previous 6D rotation encoding instead represents identity as $(1,0,0,0,1,0)$ before adding translation. Absolute orientations retain the [continuous 6D rotation representation](https://openaccess.thecvf.com/content_CVPR_2019/html/Zhou_On_the_Continuity_of_Rotation_Representations_in_Neural_Networks_CVPR_2019_paper.html), which avoids the global discontinuity of a 3-value rotation vector. These are design considerations rather than an experimentally isolated explanation of the success-rate difference; relative rotations near 180 degrees still encounter the rotation-vector ambiguity.

The absolute target concatenates both arms' rotation encodings and translations in their respective base frames. The implementation does not apply camera extrinsics or transform the two arms into a calibrated common world frame. Its head-view conditioning therefore supplies an additional absolute-pose task without making the labels head-camera coordinates.

<figure style="margin: 1.5em auto;">
  <img src="{{ '/assets/img/projects/cloth-folding/ee-architecture.svg' | relative_url }}" alt="Shared action expert with a joint-action branch and three view-conditioned end-effector auxiliary branches. Only joint actions are used for execution. An attention matrix shows which token groups can attend to each other." style="width: 100%;">
  <figcaption><strong>EE auxiliary learning.</strong> Separate token groups learn joint actions and end-effector trajectories through a shared network. The attention matrix shows direct visibility: rows are queries and columns are keys/values. Filled cells permit attention; empty cells block it.</figcaption>
</figure>

The attention mask makes the auxiliary role explicit. Joint-action tokens do not attend to EE tokens. Each EE sequence attends to its own suffix tokens, the text prefix, and its assigned camera's prefix tokens; it does not read the joint-action sequence or the other EE sequences. Since prefix representations are processed by the shared network, this restriction should not be interpreted as complete isolation of visual information across cameras.

**Positional encoding also accounts for the parallel prediction branches.** Although the joint-action and three EE sequences are concatenated, each reuses the same base horizon positions rather than continuing the position count across all four sequences. For a sample with $N$ valid prefix tokens and horizon index $j$, the rotary positional encoding (RoPE) coordinates are

$$
\begin{aligned}
p_{\mathrm{joint},j} &= N + j, \\
p_{b,j} &= N + j + \delta_{b,j},
\quad j = 0,\ldots,H-1.
\end{aligned}
$$

Here $b$ denotes the left-relative, right-relative, or dual-absolute EE branch. Each EE branch has its own learnable vector of $H$ scalar offsets, initialized to zero and shared across samples. Thus all branches initially align corresponding horizon steps, while training can adjust the EE branches' positional relationships to the prefix and within each trajectory. The offsets change the RoPE rotations of attention queries and keys; they are not feature vectors added to the projected token embeddings, nor encodings of physical XYZ coordinates. They are also distinct from the flow-matching noise-time conditioning.

The joint-action branch has no learned position offset in this configuration. The EE offsets are optimized through the auxiliary flow-matching losses, without an additional positional loss. Inference retains the ordinary joint-action horizon positions and does not require the EE branches or their offsets.

All branches use flow-matching objectives. The weighted training objective is

$$
\mathcal{L} = \mathcal{L}_{\mathrm{joint}}
+ 0.5\,\mathcal{L}_{\mathrm{left\ EE}}
+ 0.5\,\mathcal{L}_{\mathrm{right\ EE}}
+ 0.01\,\mathcal{L}_{\mathrm{absolute\ EE}}.
$$

The EE targets explicitly bypass dataset normalization, preserving translation in meters and the chosen rotation coordinates. Each flow loss is an MSE averaged over its output dimensions, rather than a geodesic rotation loss or a consistency loss between predicted joint actions and their forward-kinematic poses. Representation and units therefore affect the training metric alongside the branch weights. These coefficients are implementation settings, not independently validated optimal values. At inference, the policy generates joint actions without requiring the auxiliary EE predictions. The intended benefit is to shape shared representations through additional supervision during training.

### Observed Effect

We compare models trained on 52 demonstration episodes and 15 DAgger episodes, with advantage annotations and no observation history:

| Model | Successful garments |
| :-- | :--: |
| $\pi_{0.5}$ without EE auxiliary supervision | 7/10 |
| $\pi_{0.5}$ with EE auxiliary supervision | 9/10 |

We also observe fewer grasp retries and flatter folded garments with EE supervision. Retry counts and folding quality have not yet been evaluated quantitatively. With ten garments per model and varying initial conditions, the success counts are **preliminary evidence**, not a statistically established improvement.

## Relation to Other $\pi_{0.5}$ Deployment Results

[Dream Machines' manufacturing study](https://dream-machines.eu/blog/pi05-fine-tuning) also found human intervention data useful: adding rollout corrections increased their standard-setting success from 28% to 88%, using 1.7 hours of training data in total. Their retained data consisted of intervention segments and successful non-intervention trajectories, which differs from our autonomous-plus-intervention comparison. The shared observation is that data targeted at policy errors can be particularly valuable.

Their study also emphasizes uncertainty in small real-robot evaluations, an important consideration for our ten-garment comparisons. Their task does not evaluate EE auxiliary supervision; that part of this project rests on our own implementation and preliminary measurements.

## Lessons and Limitations

The clearest practical lesson is to collect data around the policy's actual failure modes. In this cloth-folding setup, corrective trajectories supplied useful recovery behavior that additional ordinary demonstrations did not. Their value also depended on how pauses, unsuccessful actions, and autonomous segments were represented during training.

EE auxiliary learning offers a complementary direction: use kinematically derived targets to supervise the geometry of manipulation while retaining joint-space execution. The initial results are encouraging, but a larger evaluation with matched initial conditions is needed to separate this effect from rollout variability. Ablating absolute and relative targets separately, and measuring retries and final fold quality, would clarify which aspects improve.

This project establishes a working reproduction and documents two practical routes toward more reliable execution. It does not yet establish robustness across unseen garment types, environments, or long unattended runs.

## References

{% bibliography --cited %}
