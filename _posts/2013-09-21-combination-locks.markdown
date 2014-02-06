---
author: idunning
date: 2013-09-21 12:00:00+00:00
layout: post
title: Solving a Combination Lock Puzzle with JuMP + Julia
---

[The PuzzlOR](http://puzzlor.com/) is a website connected to [INFORMS](https://www.informs.org) that publishes [operations research](https://www.informs.org/About-INFORMS/What-is-Operations-Research)-related problems bimonthly. In a series of posts I'm going to solve some of the problems to demonstrate [JuMP](https://github.com/JuliaOpt/JuMP.jl), an algebraic modeling language for/in [Julia](http://julialang.org).

## Combination Locks (August 2012)

[(Link to full problem statement)](http://puzzlor.com/2012-08_CombinationLocks.html)

Our goal is to determine 6 numbers, where each of the 6 numbers has 6 possibilities and the sum of the numbers is 419. Lets first describe the possibilities (pulled from the image) as a matrix P:

<div>
$$
P =
 \begin{bmatrix}
  39 & 06 & 75 & 88 & 15 & 57 \\
   9 &  2 & 58 & 68 & 48 & 64 \\
  \vdots & \vdots & \vdots & \vdots & \vdots & \vdots \\
  44 & 63 & 10 & 83 & 46 & 03
 \end{bmatrix}
$$
</div>

We will model the problem as a integer program with variables \\( x\_{ij} \\) that equal 1 if and only if for lock (row) _i_ we select the number (column) _j_. Our model is thus the following feasibility problem:

<div>
$$
\begin{alignat*}{1}
\max \quad & 0\\
\text{subject to} \quad & \sum_{ij}D_{ij}x_{ij}=419\\
 & \sum_{j=1}^6 x_{ij} = 1 \qquad \forall i \in \{1,\dots,6\}\\
 & x_{ij}\in\left\{ 0,1\right\}
\end{alignat*}
$$
</div>
where the first constraint enforces the sum of the numbers equals 419, and the second constraint ensures we pick a number for each lock. We can solve this problem with the following code:

{% highlight julia %}
# Assuming a solver has been previously installed, e.g. Cbc
using JuMP

function SolveCombination(P)
  m = Model(:Max)  # Feasibility problem, sense unimportant
  
  # Variable x: 1 iff select number j for lock i
  @defVar(m, 0 <= x[i=1:6, j=1:6] <= 1, Int)

  # Constraint 1: Sum of numbers is equal to 419
  @addConstraint(m, sum{P[i,j]*x[i,j], i=1:6, j=1:6} == 419)

  # Constraint 2: Must pick a number from each lock
  for i in 1:6
    @addConstraint(m, sum{x[i,j], j=1:6} == 1)
  end

  # Solve with default solver (CBC)
  status = solve(m)

  if status == :Infeasible
    println("Couldn't find the numbers!")
  else
    println("Found the numbers:")
    for i in 1:6
      for j in 1:6
        if getValue(x[i,j]) >= 0.99
          println("Lock $i is $(P[i,j])")
          break
        end
      end
    end
  end
end

P = [39 06 75 88 15 57;
      9  2 58 68 48 64;
     29 55 16 67  8 91;
     40 54 66 22 32 25;
     49  1 17 41 14 30;
     44 63 10 83 46  3]
SolveCombination(P)
{% endhighlight %}
<br>
An extension question: what happens if relax constraint 2? How many locks would we need to make the sum 419 if we didn't need to set all 6 locks?
