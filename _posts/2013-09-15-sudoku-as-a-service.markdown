---
author: idunning
date: 2013-09-15 12:00:00+00:00
layout: post
title: Sudoku-as-a-Service with Julia
---

[Sudoku](http://en.wikipedia.org/wiki/Sudoku) is (was?) an extremely popular number puzzle. Players are presented with a 9 by 9 grid, with some of the cells filled in with a number between 1 and 9. The goal is to complete the grid while respecting these rules:

 * Each row of the grid must contain each of the numbers 1 to 9 exactly once.
 * Each column of the grid must contain each of the numbers 1 to 9 exactly once.
 * Divide the grid into 9 3-by-3 non-overlapping subgrids. Each of these 3-by-3 grids must contain each of the numbers 1 to 9 exactly once.

## Solving Sudoku problems

This can be expressed as an [integer programming problem](http://en.wikipedia.org/wiki/Integer_programming) by defining a variable _x(i,j,k)_ that is 1 if and only if cell _(i,j)_ is set to value _k_, and is 0 otherwise. This can be written mathematically (with constraints to enforce the given cells omitted) as:

{% img /images/sudokuform.png MIP formulation of sudoku problem %}

Of course there are algorithms designed to solve sudoku problems directly that are probably more efficient than integer programming, but stay with me for a moment...

## Creating an online service in Julia

[Julia](http://julialang.org) is a fantastic up-and-coming dynamic language that emphasises high-performance scientific computing that is extensible and easy to read and write. It doesn't reinvent the wheel: it utilizes the [LLVM compiler](http://llvm.org/) to generate fast code, open-source linear algebra packages to provide fast number crunching, and the [libuv](https://github.com/joyent/libuv) library to provide excellent cross-platform IO. libuv is the library that powers the popular [node.js](http://nodejs.org) environment that has become very popular over the past couple of years for web development. Being a web development language is not an official goal of Julia, but there is certainly no reason it can't be used. For example, if server-side number crunching is one of the features your site needs, that part could be implemented in Julia and the rest of the application logic in node.js or your tool of choice.

The best way to get started with creating a web service is to use the [HttpServer.jl](https://github.com/hackerschool/HttpServer.jl) package, a package made at [Hacker School](https://www.hackerschool.com/). Documentation is pretty scarce at this point, but hopefully by inspecting the relatively short code and looking at some examples you can get started.

## SaaS == Sudoku-as-a-service?

To demonstrate that you can make pretty complex web-capable number crunching applications with relative ease, I decided to make [SudokuService](https://github.com/IainNZ/SudokuService) - a web service that solves sudoku problems. Apart from Julia and HttpServer.jl, I used the following tools:

 * [JuMP](https://github.com/IainNZ/JuMP.jl), an algebraic modelling language for linear (and integer and quadratic) programming created by myself and the very talented [Miles Lubin](http://www.mit.edu/~mlubin/). You should compare JuMP with tools like [PuLP](http://code.google.com/p/pulp-or/) and [AMPL](http://www.ampl.com).
 * [COIN-OR CBC](https://projects.coin-or.org/Cbc), an open-source integer programming solver. We also have interfaces to GLPK and Gurobi (closed-source).

### Sudoku-solving Code

All the code is in the repository, but I thought I'd put a snippet here of the JuMP code (``sudoku.jl``) where I formulate the model so you can get a feel for how it works:

{% highlight julia %}
using JuMP

function SolveModel(initgrid)
  m = Model(:Max)  # Feasibility problem, so sense not important

  # Create the variables
  @defVar(m, 0 <= x[1:9, 1:9, 1:9] <= 1, Int)

  # ... snip other constraints ...
  # Constraint 4 - Only one value in each cell
  for row in 1:9
    for col in 1:9
      @addConstraint(m, sum{x[row, col, val], val=1:9} == 1)
    end
  end

  # ... snip initial solution constraints ...
  # Solve it (default solver is CBC)
  status = solve(m)
  
  # Check solution
  if status == :Infeasible
    error("No solution found!")
  else
    mipSol = getValue(x)
    # ... snip transforming 3D 0-1 solution into 2D 1-9 grid ...
    return sol
  end
end
{% endhighlight %}

### Web-service Code

Finally, we need to make a server. Check out ``server.jl`` in the repository - its pretty straightforward and most of the work is input validation. Heres a taster:
{% highlight julia %}
using HttpServer

# Load the Sudoku solver
require("sudoku.jl")

# Build the request handler
http = HttpHandler() do req::Request, res::Response
  if ismatch(r"^/sudoku/", req.resource)
    # Expecting 81 numbers between 0 and 9
    reqsplit = split(req.resource, "/")
    # ...snip validation...#
    probstr = reqsplit[3]
    if length(probstr) != 81
      return Response("Error: expected 81 numbers.")
    end
    
    # Convert string into numbers, and place in matrix
    # Return error if any non-numbers or numbers out of range detected
    prob = zeros(Int,9,9)
    pos = 1
    try
      for row = 1:9
        for col = 1:9
          val = int(probstr[pos:pos])
          if val < 0 || val > 10
            return Response("Error: number out of range 0:9.")
          end
          prob[row,col] = val
          pos += 1
        end
      end
    catch
      return Response("Error: couldn't parse numbers.")
    end

    # Attempt to solve the problem using integer programming
    try
      sol = SolveModel(prob)
      if prettyoutput
        # ...snip...
      else
        # Return solution like input
        return Response(join(sol,""))
      end
    catch
      return Response("Error: coudn't solve puzzle.")
    end
  else
    # Not a valid URL
    return Response(404)
  end
end

# Boot up the server
server = Server(http)
run(server, 8000)
{% endhighlight %}

## Try it yourself!

Julia is still growing (rapidly) - I suggest grabbing the 0.2 pre-release and having a bit of patience in case of strange errors! Instructions for installing everything are in ``README.md``. I encourage you to check it out for yourself, and maybe extend it.  One project could be to implement a pure-Julia sudoku solver and benchmark performance against the MIP solver. Let me know how you go by reaching me at idunning AT mit.edu or [@iaindunning](https://www.twitter.com/iaindunning).
