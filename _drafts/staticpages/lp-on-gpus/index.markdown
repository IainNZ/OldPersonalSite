---
author: idunning
comments: false
date: 2012-08-06 05:01:20+00:00
layout: page
slug: lp-on-gpus
title: LP on GPUs
wordpress_id: 55
---

[![LPG](http://www.iaindunning.com/wp-content/uploads/2012/08/lpg.png)](http://www.iaindunning.com/wp-content/uploads/2012/08/lpg.png)Most people are familiar with the steady increases in the computing power of desktop computers, but it is never enough for researchers who can always find uses for more! One option is to re-purpose a common computer component that is usually only used for producing 3D graphics: the **GPU**, or Graphics Processing Unit. GPUs are very good at doing a very large number of small steps all at once - for example, simultaneously figuring out what colour each pixel on your computer screen should be at any given moment. Recent changes in the software that drives these GPUs has opened up the possibility of using them to perform non-graphical tasks.


### Simplex Method


My first attempt at using GPUs to solve linear programming problems was in (Southern Hemisphere!) summer 2010-2011 in the Department of Engineering Science, Univeristy of Auckland. The project was supervised by [Dr Michael O'Sullivan](http://www.des.auckland.ac.nz/uoa/michael-osullivan) and [Dr Cameron Walker](http://www.des.auckland.ac.nz/uoa/cameron-walker). I implemented a version of the revised simplex method that did all the linear algebra on GPUs. I tried to implement it in a very similar way that only used the CPU, in order to make a comparison. The GPU code performed better than the CPU code at sufficiently large problem sizes. There is a couple of catches here:



	
  * The implementation was quite simplistic compared to leading implementations. Taking a look at a more advanced LP code like [CLP](https://projects.coin-or.org/Clp/) shows many clever tricks to improve over the textbook version of the simplex algorithm - many of these may not extend well to GPUs. On the other hand, the GPU may make other things possible.

	
  * My implementation did not exploit sparsity. This is a huge issue, because linear programming problems tend to be very sparse (each constraint only involves a few variables). I would expect, based on research on sparse linear algebra on GPUs, that the performance of the CPU method would increase substantially more than the GPU method would improve if I implemented sparsity. This could be more than enough to swallow the lead the GPU had in my limited tests.

	
  * I implemented pretty much everything myself in [OpenCL](http://www.khronos.org/opencl/). I am completely sure that my code was not perfect, in fact I suspect it is far from it, because coding for GPUs to extract maximum performance is pretty tricky. At the time there was not a good ecosystem of open-source libraries for linear algebra on GPUs that used OpenCL. This has changed somewhat now. In contrast, my CPU implementation was probably not too bad, with the above points taken into consideration.




### Interior Point Method


I made a second attempt in (Northern Hemisphere) spring 2012 as a project for [Prof. Rob Freund](http://web.mit.edu/rfreund/www/)'s nonlinear programming course. In this attempt, I implemented the most simple version of the "primal-dual" interior point method. The key step is solving a large linear system, with sparsity. My code again did not include sparsity, and had lots of inefficiencies and even some implementation errors. I hope to find some time to give this another go, as I think the nature of the algorithm might lend itself more to GPUs. My main logic behind this is that it has far fewer tests than simplex, and fewer iterations - its performance is characterized by the big effort in solving that linear system.
