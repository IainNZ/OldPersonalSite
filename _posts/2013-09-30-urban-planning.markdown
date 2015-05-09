---
author: idunning
date: 2013-09-30 12:00:00+00:00
layout: post
title: Solving an Urban Planning Puzzle with JuMP + Julia
---

[The PuzzlOR](http://puzzlor.com/) is a website connected to [INFORMS](https://www.informs.org) that publishes [operations research](https://www.informs.org/About-INFORMS/What-is-Operations-Research)-related problems bimonthly. In a series of posts I'm going to solve some of the problems to demonstrate [JuMP](https://github.com/JuliaOpt/JuMP.jl), an algebraic modeling language for/in [Julia](http://julialang.org).

## Urban Planning (August 2013)

[(Link to full problem statement)](http://puzzlor.com/2013-08_UrbanPlanning.html)

In this problem we have a 5x5 grid with two possibilities for each lot: residential or commercial. Let's define a binary variable  \\( x\_{ij} \\) that is 1 if and only if lot \\( (i,j) \\) is residential. The challenge now is to express the objective. For each row and column there are the following possibilities:

* Five residential \\( \\sum\_{j=1}^5 x\_{ij} = 5 \\) is +5 points
* Four residential \\( \\sum\_{j=1}^5 x\_{ij} = 4 \\) is +4 points
* Three residential \\( \\sum\_{j=1}^5 x\_{ij} = 3 \\) is +3 points
* Two residential \\( \\sum\_{j=1}^5 x\_{ij} = 2 \\) is -3 points
* One residential \\( \\sum\_{j=1}^5 x\_{ij} = 1 \\) is -4 points
* Zero residential \\( \\sum\_{j=1}^5 x\_{ij} = 0 \\) is -5 points

We will need additional variables that don't directly correspond to a decision in the original problem, commonly referred to as auxiliary variables, to model this problem. Before we talk about that let's first review some integer programming modelling "tricks". 

### Modeling Logical Constraints with Binary Variables

In linear integer programming, all constraints must be linear in the decision variables. Solving non-linear integer programming problems is possible, but is significantly more difficult. The challenge of integer programming modeling then is to "linearize" all the logic of the problem. Consider the following constraints:

<div>
$$
y \geq 0.5 \\
y \in {0,1}
$$
</div>

Because \\( y \\) is a binary variable, the effect of these two constraints is to force \\( y = 1 \\). Consider the following extension, where \\( z\_1, z\_2, z\_3 \\) are all binary variables:

<div>
$$
y \geq \frac{1}{3} \left( z_1 + z_2 + z_3 \right) \\
y \in {0,1}
$$
</div>

If any of the three \\( z \\) variables is 1, \\( y \\) is forced to equal one. This is equivalent to the logical statement *y = z1 or z2 or z3*. Another way to write this for binary \\( z \\) is

<div>
$$
y \geq z_1 \\
y \geq z_2 \\
y \geq z_3 \\
y \in {0,1}
$$
</div>

Let's apply this to the problem at hand.

### Modeling the positive point cases

Define new variables

* \\( y\_{R,i}^5 = 1 \\) iff row \\( i \\) has 5 residential,
* \\( y\_{R,i}^4 = 1 \\) iff row \\( i \\) has 4 or more residential,
* \\( y\_{R,i}^3 = 1 \\) iff row \\( i \\) has 3 or more residential

and equivalent \\( y_{C,i} \\) for columns. The objective function of our problem, for the positive parts at least, can be written as

<div>
$$
(\max) \sum_{i=1}^5 (3 (y_{R,i}^3 + y_{C,i}^3) + 1 (y_{R,i}^4 + y_{C,i}^4) + 1 (y_{R,i}^5 + y_{C,i}^5))
$$
</div>

Note that \\( x \\) does not appear in the objective, and that the optimizer will want to set these \\( y \\) variables to one if at all possible to drive the objective function value higher. Knowing that, we simply need to restrict these variables from being 1 if the condition is not met. The following constraints achieve this goal:

<div>
$$
y_{R,i}^5 \leq \frac{1}{5} \sum_{j=1}^5 x_{ij} \\
y_{R,i}^4 \leq \frac{1}{4} \sum_{j=1}^5 x_{ij} \\
y_{R,i}^3 \leq \frac{1}{3} \sum_{j=1}^5 x_{ij}
$$
</div>

To understand why, consider the case where \\( \\sum\_{j=1}^5 x\_{ij} = 4 \\). If we plug that in to the right-hand-side of each constraint we obtain:

<div>
$$
y_{R,i}^5 \leq \frac{4}{5} \rightarrow y_{R,i}^5 = 0 \\
y_{R,i}^4 \leq \frac{4}{4} \rightarrow y_{R,i}^4 \leq 1 \\
y_{R,i}^3 \leq \frac{4}{3} \rightarrow y_{R,i}^3 \leq 1
$$
</div>

When combined with the objective sense, the \\( \leq \\) is effectively an equality. Note also that if the sum of the \\( x \\) variables is zero on the right-hand-side, the problem is still feasible - that is, we don't force the \\( y \\) variables to satisfy mutually exclusive constraints like

<div>
$$
y_{R,i}^3 \leq -0.5 \\
y_{R,i}^3 \in {0,1}
$$
</div>

### Modeling the negative point cases

We can use a similar approach for the negative point cases, but the constraints are perhaps less intuitive. As before, define variables

* \\( y\_{R,i}^{-3} = 1 \\) iff row \\( i \\) has 2 residential or less,
* \\( y\_{R,i}^{-4} = 1 \\) iff row \\( i \\) has 1 residential or less,
* \\( y\_{R,i}^{-5} = 1 \\) iff row \\( i \\) has 0 residential.

The objective function "contribution" from these variables can be written as

<div>
$$
(\max) \sum_{i=1}^5 (-3 (y_{R,i}^{-3} + y_{C,i}^{-3}) - 1 (y_{R,i}^{-4} + y_{C,i}^{-4}) - 1 (y_{R,i}^{-5} + y_{C,i}^{-5}))
$$
</div>

The optimizer tries to drive these variables towards zero. Before we were restricting variables away from one, but now we will restrict them _away_ from zero with the following constraints:

<div>
$$
y_{R,i}^{-3} \geq 1 - \frac{1}{3} \sum_{j=1}^5 x_{ij} \\
y_{R,i}^{-4} \geq 1 - \frac{1}{2} \sum_{j=1}^5 x_{ij} \\
y_{R,i}^{-5} \geq 1 - \frac{1}{1} \sum_{j=1}^5 x_{ij}
$$
</div>

As before, let's consider an example. Suppose \\( \\sum\_{j=1}^5 x\_{ij} = 1 \\):

<div>
$$
y_{R,i}^{-3} \geq 1 - \frac{1}{3} \rightarrow y_{R,i}^{-3} = 1 \\
y_{R,i}^{-4} \geq 1 - \frac{1}{2} \rightarrow y_{R,i}^{-4} = 1 \\
y_{R,i}^{-5} \geq 1 - \frac{1}{1} \rightarrow y_{R,i}^{-5} \geq 0 
$$
</div>

You can also check that all variables will set to 1 in the case where the sum is zero, and that if the sum is 3 or higher then all can be set to zero.

### Putting it all together

Apart from a constraint to set the total number of residential lots, we have everything we need. Let's build the model in JuMP and Julia.

{% highlight julia %}
# Assuming a solver has been previously installed, e.g. Cbc
using JuMP

function SolveUrban()

  m = Model()

  # x is indexed by row and column
  @defVar(m, 0 <= x[1:5,1:5] <= 1, Int)

  # y is indexed by R or C, and the points
  # JuMP allows indexing on arbitrary sets
  rowcol = ["R","C"]
  points = [+5,+4,+3,-3,-4,-5]
  @defVar(m, 0 <= y[rowcol,points,i=1:5] <= 1, Int)

  # Objective - combine the positive and negative parts
  @setObjective(m, Max, sum{
    3*(y["R", 3,i] + y["C", 3,i]) 
  + 1*(y["R", 4,i] + y["C", 4,i]) 
  + 1*(y["R", 5,i] + y["C", 5,i]) 
  - 3*(y["R",-3,i] + y["C",-3,i]) 
  - 1*(y["R",-4,i] + y["C",-4,i])
  - 1*(y["R",-5,i] + y["C",-5,i]), i=1:5})

  # Constrain the number of residential lots
  @addConstraint(m, sum{x[i,j], i=1:5, j=1:5} == 12)

  # Add the constraints that link the auxiliary y variables
  # to the x variables
  # Rows
  for i = 1:5
    @addConstraint(m, y["R", 5,i] <=   1/5*sum{x[i,j], j=1:5}) # sum = 5
    @addConstraint(m, y["R", 4,i] <=   1/4*sum{x[i,j], j=1:5}) # sum = 4
    @addConstraint(m, y["R", 3,i] <=   1/3*sum{x[i,j], j=1:5}) # sum = 3
    @addConstraint(m, y["R",-3,i] >= 1-1/3*sum{x[i,j], j=1:5}) # sum = 2
    @addConstraint(m, y["R",-4,i] >= 1-1/2*sum{x[i,j], j=1:5}) # sum = 1
    @addConstraint(m, y["R",-5,i] >= 1-1/1*sum{x[i,j], j=1:5}) # sum = 0
  end
  # Columns
  for j = 1:5
    @addConstraint(m, y["C", 5,j] <=   1/5*sum{x[i,j], i=1:5}) # sum = 5
    @addConstraint(m, y["C", 4,j] <=   1/4*sum{x[i,j], i=1:5}) # sum = 4
    @addConstraint(m, y["C", 3,j] <=   1/3*sum{x[i,j], i=1:5}) # sum = 3
    @addConstraint(m, y["C",-3,j] >= 1-1/3*sum{x[i,j], i=1:5}) # sum = 2
    @addConstraint(m, y["C",-4,j] >= 1-1/2*sum{x[i,j], i=1:5}) # sum = 1
    @addConstraint(m, y["C",-5,j] >= 1-1/1*sum{x[i,j], i=1:5}) # sum = 0
  end

  # Solve it with the default solver (CBC)
  status = solve(m)
  if status == :Infeasible
    error("Solver couldn't find solution!")
  end

  # Print results
  println("Best objective: $(round(getObjectiveValue(m)))")
  println(getValue(x))
end

SolveUrban()
{% endhighlight %}

Try it yourself to see what the solution is. Do you believe the solution is correct, does it match your intuition?

### Discussion

While you can probably solve this problem just by inspection and trying a few ideas, its interesting to consider how the an integer programming solver would handle this problem. The deep details of this are way beyond the scope of this blog post, but there are two main issues:

* Symmetry: the rows and columns are all effectively interchangeable. For example, if row 1 has three residential lots and row 2 has four, we could swap these rows without changing the objective. This can be an issue for MIP solvers as there is a chance the solution will "bounce" between many equivalent possibilities before reaching optimality, although many techniques and heuristics are built into these solvers to counteract this and even harness it.

* Fractionality: MIP solvers actually solve a succession of linear problems where the constraints \\( x \\in {0,1} \\) are _relaxed_ to \\( 0 \\leq x \\leq 1 \\). The result of this is that when we initially solve the problem, many of \\( y \\) variables will be fractional. MIP solvers add _cuts_ (constraints that push the values towards the integer values) and _branch_ (solve two new problems with a fractional variables fixed to either 0 or 1) to eventually find an integer solution. They may also employ heuristics that attempt to construct an integer solution from the fractional solution.

The problem size here is so small that a solution is found almost instantly. However these are real issues for "real-world" problems and a lot of research is devoted to both improving solvers and studying the implications of different formulations.
