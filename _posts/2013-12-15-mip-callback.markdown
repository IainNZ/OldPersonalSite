---
author: idunning
date: 2013-12-15 12:00:00+00:00
layout: post
title: Using JuMP to Solve a TSP with Lazy Constraints
---

[JuMP](http://github.com/JuliaOpt/JuMP.jl) is an algebraic modeling language for optimization problems implemented as a package for the [Julia](http://julialang.org) programming language. It works with many solvers, both open-source and commercial - see the [JuliaOpt](http://juliaopt.org) home page for more information. I've written [a](http://iaindunning.com/2013/urban-planning.html) [few](http://iaindunning.com/2013/combination-locks.html) [times](http://iaindunning.com/2013/sudoku-as-a-service.html) about solving problems with JuMP.

We just released **version 0.2** of JuMP which, among other things, provides solver-independent callbacks for [mixed-integer linear programming problems](http://en.wikipedia.org/wiki/Linear_programming#Integer_unknowns) (MILPs). MILPs are usually solved by solving a succession of linear relaxations of the original problem in a process known as branch-and-bound. Basically: if the solution of a linear relaxation has a fractional value for a variable that should be integral, (e.g. x = 4.3), we branch on that variable to create two new linear relaxation problems - one where the variable is constrained to be less than or equal to the rounded down value (e.g. x = 4) and other where the variable is constrained to be greather than or equal to the rounded up value (e.g. x = 5). There is a lot more that goes on to make this efficient, but that's the basic idea.

Optimization software often allows users to provide **callback functions** that run when certain events happen in the branch-and-bound process, allowing the user to modify the solve process. The one I will describe today allows us to add a new constraint to the problem that may "cut off" a solution to the problem whenever a new solution is found -  a **"lazy constraint"**. You can read more about lazy constraints at [Paul Rubin's blog](http://orinanobworld.blogspot.com/2012/08/user-cuts-versus-lazy-constraints.html).

A problem with solver callbacks is that each solver implements them differently. Some solvers may allow the user to provide one callback function and pass a parameter into the callback telling it what the solve state is and what the user can now do. Other solvers want a different callback for every possible situation. For this reason, and probably others, unifying all these interfaces across solvers in a simple way hasn't really been done before in an solver-independent algebraic modeling language. JuMP makes the process as simple as can be (hopefully), and you can **[read the documentation to find out more](https://jump.readthedocs.org/en/release-0.2/jump.html#solver-callbacks)**.

In this blog post I will demonstrate how you can use JuMP's lazy constraint callback functionality to solve a travelling salesman problem (TSP) using **subtour elimination constraints**. To follow along at home you'll need one (but preferably at least two of): GNU GLPK, Gurobi, or CPLEX. To install Julia, see the [Download page](http://julialang.org/downloads/) and to install JuMP you can run the following commands at the Julia prompt:

{% highlight julia %}

# Update package listing
Pkg.update()

# Install JuMP
Pkg.add("JuMP")

# Install interface to your solver of choice.
# Further setup might be required for these - see the README for each package!

# Gurobi
# https://github.com/JuliaOpt/Gurobi.jl
Pkg.add("Gurobi")
 
# GNU GLPK
# https://github.com/JuliaOpt/GLPK.jl
Pkg.add("GLPK")
Pkg.add("GLPKMathProgInterface")

# CPLEX (experimental!)
# https://github.com/joehuchette/CPLEXLink.jl
Pkg.add("CPLEXLink")

{% endhighlight %}

<h3>Formulating the TSP integer program</h3>

From the <a href="http://www.tsp.gatech.edu/problem/index.html">Georgia Institue of Technology website</a>:

<blockquote>Given a collection of cities and the cost of travel between each pair of them, the traveling salesman problem, or TSP for short, is to find the cheapest way of visiting all of the cities and returning to your starting point. In the standard version we study, the travel costs are symmetric in the sense that traveling from city X to city Y costs just as much as traveling from Y to X.</blockquote>

One way to write the (partial) integer programming formulation of the undirected version of this problem is:

<div>
$$
\begin{align}
\min_{x\in\{0,1\}} & \sum_{i=1,\dots,n,j=i,\dots,n} d_{i,j} x_{i,j} \\
\text{Subject to}  & x_{i,j} = x_{j,i} \quad \forall i,j \\
                   & x_{i,i} = 0 \quad \forall i \\
                   & \sum_{j=1,\dots,n} x_{i,j} = 2 \quad \forall i
\end{align}
$$
</div>

The translation of this math is as follows:

 * \\( x_{i,j} \\) variable is 1 if we go between city \\( i \\) and city \\( j \\)  on our tour.
 * \\( d_{i,j} \\) is the distance or cost between the two cities.
 * The first constraint makes our problem undirected (going from i to j is the same as going from j to i)
 * The second constraint removes the variables that correspond to leaving and entering the same city.
 * The final constraints says we must enter and leave a city once and once only.

This is unfortunately not sufficient to model the TSP. Consider the following solution, which you can check satisfies all the constraints and is significantly shorter than the true solution.

{% highlight julia %}
# The + are our cities
#       +           +
#   +                   +
#       +           +
# The solution to the above problem is
#    /--+           +--\
#   +   |           |   +
#    \--+           +--/
# But it should be
#    /--+-----------+--\
#   +                   +
#    \--+-----------+--/
{% endhighlight %}

We can remove these "incorrect" solutions using so-called "subtour-elimination constraints" (see again the [Georgia Tech](http://www.tsp.gatech.edu/methods/opt/subtour.htm) website). These constraints essentially say that for any given set of cities, if you treat that set as a black box there must be at least one trip into that set and one trip out. Unfortunately there are an **exponential number of subsets of cities**, and so an exponential number of constraints. We could generate them all but you will find that, in practice, very few are actually needed. The secret is to add them "lazily" - only when they are needed. You only need one constraint to "correct" the solution to our example problem above.

### Solving the relaxed problem with JuMP

Let's first solve the problem without callbacks and subtour elimination constraints. Here is the code I came up with. I solved it with Gurobi, and the full final code is in the [JuMP examples](https://github.com/JuliaOpt/JuMP.jl/blob/master/examples/tsp.jl) folder. I don't define ``extractTour`` here - see the example file, it simply turns the ``x`` matrix of 0-1s into a human-readable description of the tour.

{% highlight julia %}
using JuMP
using Gurobi

# solveTSP
# Given a matrix of city locations, solve the TSP
# Inputs:
#   n       Number of cities
#   cities  n-by-2 matrix of (x,y) city locations
# Output:
#   path    Vector with order to cities are visited in
function solveTSP(n, cities)

    # Calculate pairwise distance matrix
    dist = zeros(n, n)
    for i = 1:n
        for j = i:n
            d = norm(cities[i,1:2] - cities[j,1:2])
            dist[i,j] = d
            dist[j,i] = d
        end
    end

    # Create a model that we will use Gurobi to solve
    # We need to tell Gurobi we are using lazy constraints
    m = Model(solver=GurobiSolver(LazyConstraints=1))

    # x[i,j] is 1 iff we travel between i and j, 0 otherwise
    # Although we define all n^2 variables, we will only use
    # the upper triangle
    @defVar(m, x[1:n,1:n], Bin)

    # Minimize length of tour
    @setObjective(m, Min, sum{dist[i,j]*x[i,j], i=1:n,j=i:n})

    # Make x_ij and x_ji be the same thing (undirectional)
    # Don't allow self-arcs
    for i = 1:n
        @addConstraint(m, x[i,i] == 0)
        for j = (i+1):n
            @addConstraint(m, x[i,j] == x[j,i])
        end
    end

    # We must enter and leave every city once and only once
    for i = 1:n
        @addConstraint(m, sum{x[i,j], j=1:n} == 2)
    end

    # Solve the problem
    solve(m)

    # Return best tour
    return extractTour(n, getValue(x))
end  # end solveTSP


# Create a simple instance that looks like
#       +           +
#   +                   +
#       +           +
n = 6
cities = [ 50 200;
          100 100;
          100 300;
          500 100;
          500 300;
          550 200]
tour = solveTSP(n, cities)
println("Solution: ")
println(tour)
{% endhighlight %}

As you can see, there is pretty much a line-to-line correspondence between the JuMP constraint and objective definitions and the mathematical statement of the problem.


### Implementing the lazy constraint callback

To add a subtour elimination constraint, we first need to identify a subtour. In the [example code](https://github.com/JuliaOpt/JuMP.jl/blob/master/examples/tsp.jl) I create a simple function ``findSubtour(n, sol)`` that takes the matrix of 0-1 solutions and returns a length ``n`` vector of Booleans encoding the set of cities in one possible subtour. We can now use that to build a new constraint and add it to the problem:

{% highlight julia %}
function subtour(cb)
    # Find any set of cities in a subtour
    subtour, subtour_length = findSubtour(n, getValue(x))

    if subtour_length == n
        # This "subtour" is actually all cities, so we are done
        return
    end
    
    # Subtour found - add lazy constraint
    # We will build it up piece-by-piece (variable-by-variable)
    arcs_from_subtour = AffExpr()
    
    for i = 1:n
        if !subtour[i]
            # If this city isn't in subtour, skip it
            continue
        end
        # Want to include all arcs from this city, which is in
        # the subtour, to all cities not in the subtour
        for j = 1:n
            if i == j
                # Self-arc
                continue
            elseif subtour[j]
                # Both ends in same subtour
                continue
            else
                # j isn't in subtour
                arcs_from_subtour += x[i,j]
            end
        end
    end

    # Add the new subtour elimination constraint we built
    addLazyConstraint(cb, arcs_from_subtour >= 2)
end
{% endhighlight %}

Again, nothing too fancy. There are a few key things to understand here:

 * As you can see in the full listing in the example code, this function is defined inside the same scope as the variables - this means you have access to ``x[i,j]``, making creating the new constraint easy.
 * The logic for determining the subtour is elsewhere, and all we define here is the callback "stub". This is good code design as it allows us to test the subtour code in isolation, as well as not "cluttering" the model definition.
 * ``addLazyConstraint`` is a function defined by JuMP, and ``AffExpr`` is a type defined by JuMP - it stands for affine expression.
 * Our ``subtour`` callback takes one argument, ``cb``. This is a handle used by JuMP to keep track of where things are in the solve process. ``addLazyConstraint`` acts on ``cb``, unlike ``addConstraint``.

All that is left is for us to tell JuMP to use our ``subtour`` callback, as in the following snippet:

{% highlight julia %}
    # ......
        # Add the new subtour elimination constraint we built
        addLazyConstraint(cb, arcs_from_subtour >= 2)
    end  # End function subtour

    # Solve the problem with our cut generator
    setlazycallback(m, subtour)
    solve(m)

    # Return best tour
    return extractTour(n, getValue(x))
end  # end solveTSP
{% endhighlight %}

### Go try it!

This feature is new and (internally) a bit complicated to smooth over the differences in solvers. It *should* work, but we are always happy to have more testers! To experience the magic of solver-independent callbacks you should only need to change two things - the ``using`` line and the ``Model`` line, e.g.

{% highlight julia %}
# Gurobi
using Gurobi
# ...
    m = Model(solver=GurobiSolver(LazyConstraints=1))

# GLPK
using GLPKMathProgInterface
# ...
    m = Model(solver=GLPKSolverMIP())

# CPLEX
using CPLEXLink
# ...
    m = Model(solver=CplexSolver())
{% endhighlight %}

Let us know how it goes. If you have issues open a report at the [JuMP issues page](https://github.com/JuliaOpt/JuMP.jl/issues?state=open), [Tweet at me](https://twitter.com/iaindunning), or email me (idunning AT mit DOT edu).

### Coming soon

We hope to add support in JuMP for other common callbacks such as heuristics, cuts, and branching rules in the near future. Also on our mind is adding support for [SCIP](http://scip.zib.de/) (which has a wide variety of callbacks) and [Sulum](http://www.sulumoptimization.com/) (callbacks are coming soon).