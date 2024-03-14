---
layout: post
title: Clearing Disk Space on Ubuntu 22.04
date: 2024-03-14
description: A Record of how I clear up disk space
tags: system
related_posts: false
---

### Background 

The idea is simple, it is that I do not have enough disk space, since I only allocated around 90GB for my Ubuntu system. And in fact, there are a lot of abundant files that can be removed.

**A Useful Command:** `du -hx --max-depth=1 --threshold=800M`, which helps us find directories that takes up over 800MB, and these would be our targets.

### Root `/`

1. I first find out that there are a number of kernel instances in `/usr/lib/modules/`, and the fact is that I only need one or two of them. Then I follow the instructions in [ref1](#reference) and obtain a few more GBs.

2. Remove Snap (in fact I can find alternatives). Details are in [ref2](#reference).

3. Big journels in `/var/log/journal`!. Details are in [ref3](#reference) 

### Home `~`

1. I have been using `VSCode` since first year at college. Although it is great, there are quite a lot issues related to storage.
    - Do you use the `cpp-extension` in VSCode? If yes, you may need to consider cpptools in `~/.cache/vscode-cpptools`. If you want to shorten the space usage of it, please go to settings and edit cache size.

    - Please check `~/.config/Code/User/workspaceStorage`, it may also surprise you. See [ref4](#reference) for more details.


### Reference
- [ref1](https://serverfault.com/questions/1098556/how-to-cleanup-usr-lib-modules-and-usr-lib-x86-64-linux-gnu)
- [ref2](https://sysin.org/blog/ubuntu-remove-snap/)
- [ref3](https://askubuntu.com/questions/1238214/big-var-log-journal)
- [ref4](https://www.jianshu.com/p/7497160db18b)
