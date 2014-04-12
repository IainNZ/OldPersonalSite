---
author: idunning
date: 2014-04-11 12:00:00+00:00
layout: post
title: Naval Warfare with JuMP + Julia
---

[The PuzzlOR](http://puzzlor.com/) is a website connected to [INFORMS](https://www.informs.org) that publishes [operations research](https://www.informs.org/About-INFORMS/What-is-Operations-Research)-related problems bimonthly. In a series of posts I'm going to solve some of the problems to demonstrate [JuMP](https://github.com/JuliaOpt/JuMP.jl), an algebraic modeling language for/in [Julia](http://julialang.org).

## Subs vs. Battleships (April 2013)

[(Link to full problem statement)](http://puzzlor.com/2013-04_SubsBattleships.html)

In this problem we have a 10-by-10 grid representing an area of ocean. We control 15 submarines and our mission is to destroy the 15 enemy battleships. Initially all the submarines and battleships are in different cells on the grid but if we can move a submarine to the same cell as a battleship, we will destroy it. Each submarine can only destroy one battleship, and battleships cannot move (perhaps it is a simultaneous surprise attack!). Our goal is to minimize the total distance the submarines need to travel to destroy all the battleships.

{% img /images/submarines.png Those battleships don't stand a chance! %}

### Modeling the Problem

Our decision variables are binary: \\( x\_{s,b} = 1 \\) if submarine \\( s \\) will be sent to destroy battleship \\( b \\), and will be 0 otherwise.

Our constraints are also fairly simple to state for this problem set up. First of all, all submarines must be destroyed. We can rephrase that to say that the total number of submarines that "visit" each battleship is 1:

<div>
$$
\sum_{s=1}^{15} x_{s,b} = 1 \quad \forall b = 1, \dots, 15
$$
</div>

The other constraint is that a submarine cannot destroy more than one battleship. We can rephrase this one slightly too, and instead say that that total number of battleships destroyed by a submarine is 1:

<div>
$$
\sum_{b=1}^{15} x_{s,b} = 1 \quad \forall s = 1, \dots, 15
$$
</div>


### Putting it all together

Let's build the model in JuMP and Julia!

{% highlight julia %}
# Assuming a solver has been previously installed, e.g. [CBC](http://github.com/JuliaOpt/Cbc.jl)
using JuMP

function solveSubBattle(sub_locs, ship_locs)

  m = Model()

  # x is a binary variable
  # x_s,b = 1 if sub s is matched with battleship b
  @defVar(m, x[s=1:15, b=1:15], Bin)

  # Objective - minimize total distance travelled
  @setObjective(m, Min, sum{ dist(sub_locs[s], ship_locs[b])*x[s,b], 
                                s=1:15, b=1:15})

  # Every ship must be attacked!
  for b = 1:15
    @addConstraint(m, sum{ x[s,b], s=1:15 } == 1)
  end

  # A submarine can attack only 1 ship
  for s = 1:15
    @addConstraint(m, sum{ x[s,b], b=1:15 } == 1)
  end

  # Solve it
  status = solve(m)
  if status == :Infeasible
    error("Solver couldn't find solution!")
  end

  # Print results
  println("Total distance traveled: ", 
            round(getObjectiveValue(m), 2))
  for s = 1:15
    for b = 1:15
      if getValue(x[s,b]) >= 0.9
        # This binary variable is set to 1
        # We use 0.9 though because due to floating point
        # error it might be not exactly 1.0
        println("Sub ", s, " at (", 
                sub_locs[s][1], ",", sub_locs[s][2], ")",
                " attacks ship ", b, " at (", 
                ship_locs[b][1], ",", ship_locs[b][2], ")")
      end
    end
  end
end
{% endhighlight %}

The code is a fairly direct translation of our mathematical model. Our function takes into two lists of ship locations - we'll describe their format more precisely in a moment. First we create a new model object, and define binary variables for each possible combination of submarine and battleship. We set our objective to minimize total distance, and add our two groups of constraints. Finally we solve and process the output.

To complete the code we need to define the ``dist(sub,ship)`` function used in the objective and create some test data.

{% highlight julia %}
function dist(sub, ship)
  # We use Euclidean distance between the cells
  return norm(sub - ship)
end

sub_locs = {  [ 6,10],
              [ 4, 7], [ 9, 7],
              [ 2, 6], [10, 6],
              [ 9, 5],
              [ 7, 4],
              [ 4, 3], [10, 3],
              [ 2, 2], [ 4, 2], [10, 2],
              [ 1, 1], [ 7, 1], [ 9, 1] }
ship_locs = { [10,10],
              [ 4, 9],
              [ 6, 8], [ 7, 8],
              [ 8, 7],
              [ 7, 6],
              [ 6, 5], [ 7, 5],
              [ 3, 4], [10, 4],
              [ 6, 3],
              [ 6, 2],
              [ 2, 1], [ 6, 1], [10, 1] }

solveSubBattle(sub_locs, ship_locs)

{% endhighlight %}

### Plotting the solution

There are many plotting solutions available in Julia but today I'm going to use [PyPlot.jl](https://github.com/stevengj/PyPlot.jl), a wrapper around the versatile [Matplotlib](http://matplotlib.org/). First, we need to modify our solve routine to return pairs of submarines and battleships:

{% highlight julia %}
  pairs = {}
  for s = 1:15
    # ...
      push!(pairs, (s,b))
    # ...
  end
  return pairs
{% endhighlight %}

then the plotting code follows pretty naturally from that - not much to say!

{% highlight julia %}
using PyPlot
# Setup the figure
fig = figure()
ax = fig[:gca]()
ax[:set_xticks]([1:11])
ax[:set_yticks]([1:11])

# Plot the submarines and battleships
for i = 1:15
  ax[:add_patch](plt.Circle((sub_locs[i][1],sub_locs[i][2]),
                            radius=0.4,facecolor="blue"))
  ax[:add_patch](plt.Circle((ship_locs[i][1],ship_locs[i][2]),
                            radius=0.4,facecolor="red"))
end

# Draw lines between each submarine and battleship
for pair in pairs
  s, b = pair
  plot( (sub_locs[s][1], ship_locs[b][1]),
        (sub_locs[s][2], ship_locs[b][2]), 
        "k", linewidth=2.0)
end

fig[:canvas][:draw]()
readline()  # Stop the program from exiting until we've seen it!
{% endhighlight %}

The result looks pretty sensible too - see the image at the top of the post.

### Extensions

Here some ideas for some things you could do with this problem, and a "difficulty" for each:

* _(easy)_ What happens if you use [Manhattan distance](http://en.wikipedia.org/wiki/Manhattan_distance) instead of [Euclidean distance](http://en.wikipedia.org/wiki/Euclidean_distance)? You can find out by making a very very small change to how the ``norm`` function is used.

* _(easy)_ How would you need to change the model if there were more battleships than submarines? Or more submarines than battleships?

* _(medium)_ How would you modify the model to limit how far a submarine could travel?

* _(medium)_ Suppose that some battleships require two submarines to be destroyed. How would you extend the model?

* _(hard)_ How would you extend the model to allow submarines to attack two ships? You'd need to model the order that the ships are visited in calculate the total distance.

* _(hard)_ How would could you model uncertainty in the locations of the battleships?