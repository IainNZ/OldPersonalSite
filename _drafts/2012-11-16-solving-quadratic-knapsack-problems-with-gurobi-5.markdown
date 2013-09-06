---
author: idunning
date: 2012-11-16 04:35:50+00:00
layout: post
title: Solving Quadratic Knapsack Problems with Gurobi
---

A friend in Material Science recently emailed me with a question: is there any easy-to-use code to solve quadratic knapsack problems? The application is awesome, especially because I don't get to see a lot of "real world problems" in my day-to-day life:

> The problem is minimizing the energy of a disordered crystal structure. We have a matrix that describes the energy of interactions between pairs of sites, and we'd like to figure out which ones are occupied in the lowest energy configuration.

He had found the paper ["Exact Solution of the Quadratic Knapsack Problem" by Caprara, et al.](http://joc.journal.informs.org/content/11/2/125.short) which uses a Lagrangian relaxation approach to provide good upper bounds in a branch-and-bound algorithm. It seems to get good results, and certainly is well-cited. Implementing it wouldn't be too bad, but it made me wonder if there was an easier way that was at least somewhat competitive. My favorite MILP solver, [Gurobi](http://www.gurobi.com), supports quadratic objectives for problems with integer variables, so it seemed worth a try. I implemented the same random instance generation used in the above paper, and then threw it at Gurobi. I also tried a reformulation which linearized the problem.

The code is available on GitHub at [https://github.com/IainNZ/QuadKnapBench](https://github.com/IainNZ/QuadKnapBench)

## Formulation of the quadratic knapsack problem

{% img /images/quadknapform.png  %}

For the linearization, replace _x(i)*x(j)_ with a new variable _y(i,j)_ that 

## Generating the instances

Given a density D (percentage of non-zero elements in P) and a size N, we generate an instance by doing the following:
	
  * _P(i,j)_ = _P(j,i)_, and the probability that the pair is non-zero is equal to the value of the density. If non-zero, it is sampled from the range 1 to 100.

  * Each weight _w(i)_ is sampled from the range 1 to 50.
	
  * The capacity _C_ is sampled from the range 50 to the sum of the weights.

## Results

My setup is a Dell laptop, Intel Core 2 Duo T9500 @ 2.60 GHz, in Windows 7, using the 32-bit version of Gurobi 5.0.2. In initial tests showed some massive variability in the run times, so I took a different approach than just recording the solve time. I set a time limit of 60 seconds, and recorded the relative gap between the best integer solution and the best fractional solution. I tested 10 instances each for different values of N and the density, and plotted the results.

[![density025](http://www.iaindunning.com/wp-content/uploads/2012/11/density025.png)](http://www.iaindunning.com/?attachment_id=137) [![density050](http://www.iaindunning.com/wp-content/uploads/2012/11/density050.png)](http://www.iaindunning.com/?attachment_id=138) [![density075](http://www.iaindunning.com/wp-content/uploads/2012/11/density075.png)](http://www.iaindunning.com/?attachment_id=139) [![density100](http://www.iaindunning.com/wp-content/uploads/2012/11/density100.png)](http://www.iaindunning.com/?attachment_id=140)
By looking at the raw output, it seems that Gurobi does a good job of getting a reasonable integer solution quickly, but doesn't close the bound fast enough - it does seem to close it steadily though. The results obtained above show some pretty high variance, and that by the time we get to N=100, 60 seconds is not enough time. This suggests that some sort of formulation strengthening is required.


## Reformulation


We will apply the reformulation described in the paper listed above to see if we can improve the performance. The description in the paper is very good, so I won't repeat it here. It increases the formulation size (N squared variables, and N squared constraints), but the hope is that it will improve performance. It is no longer a quadratic optimization problem.
