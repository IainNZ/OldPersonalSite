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

In this post I'm going to
 
 * walk through one way to solve sudoku puzzles, and 
 * how you can offer that functionality as a online service

using the [Julia](http://julialang.org) programming language.

## Solving Sudoku puzzles with integer programming

The rules of sudoku can be expressed as an [integer programming problem](http://en.wikipedia.org/wiki/Integer_programming) which can be solved by any of the many linear and integer programming solvers out there. Of course there are algorithms designed to solve sudoku problems directly that are probably more efficient than integer programming, but stay with me for a moment - I'll justify it later on! We will start our model by defining a variable _x(i,j,k)_ that equals 1 if and only if cell _(i,j)_ is set to value _k_, and is 0 otherwise.  This can be written mathematically (with constraints to enforce the fixed cells omitted) as:

{% img /images/sudokuform.png MIP formulation of sudoku problem %}

Lets break down how these constraints translate back to the rules above. In the first set of constraints we enforce that for every row _i_, across the columns _j_ the value _k_ must appear once and once only. For example, for value 5 and row 3, we say that _x(3,1,5) + x(3,2,5) + x(3,3,5) + ... + x(3,9,5) == 1_. We can check: if a 5 appeared in row 3 column 2 and row 3 column 6, the sum on the left hand side would be 2. If 5 doesn't appear in row 3 at all, the sum would be 0. Note that _x(3,1,5) = 0.5, x(3,2,5) = 0.5_ would be feasible with respect to this constraint, but that we are enforcing the constraint (not shown) that _x_ can only be 0 or 1.

The second set of constraints is very similar to the first, and enforces the second 'rule' above regarding columns. The third set of constraints is not so obvious. This set of constraints enforces that any given position _i,j_ can only contain one digit by summing across all values. This is kinda self-evident for a human so I didn't even mention it above. Finally, the fourth set of constraints corresponds to the third rule. Its the most complex notationally, but is conceptually the same as the previous two. On the right side of the equations we iterate over the 9 3-by-3 subgrids, where (0,0) is the top left subgrid and (2,2) is the bottom subgrid. The sum is then over the 9 cells inside that subgrid. Lets pick an example subgrid, e.g. _(i,j)=(0,1)_ and _k=5_, which corresponds to the left-center subgrid. We then sum over _a_ and _b_: 

 * ``x(3*0+1,3*1+1,5) + x(3*0+2,3*1+1,5) + x(3*0+3,3*1+1,5) + x(3*0+1,3*1+2,5) + x(3*0+2,3*1+2,5) + ... == 1``
 * ``x(1,4,5) + x(2,4,5) + x(3,4,5) + x(1,5,5) + x(2,5,5) + ... == 1``

As I mentioned above, we have ommitted constraints that would fix particular _x(i,j,k)_ based on the provided cells, but there is no clean way to write that above. The question now is, how do we implement this model in an expressive and maintainable way in code?

## JuMPing Julia!

[Julia](http://julialang.org) is a fantastic up-and-coming dynamic language that emphasises high-performance scientific computing that is extensible and easy to read and write. It doesn't reinvent the wheel: it utilizes the [LLVM compiler](http://llvm.org/) to generate fast code, open-source linear algebra packages to provide fast number crunching, and the [libuv](https://github.com/joyent/libuv) library to provide excellent cross-platform IO. libuv is the library that powers the popular [node.js](http://nodejs.org) environment that has become very popular over the past couple of years for web development. Being a web development language is not an official goal of Julia, but there is certainly no reason it can't be used. For example, if server-side number crunching is one of the features your site needs, that part could be implemented in Julia and the rest of the application logic in node.js or your tool of choice.

But back to sudoku. The Julia package [JuMP](https://github.com/IainNZ/JuMP.jl) is an algebraic modelling language for linear (and integer and quadratic) programming created by myself and the very talented [Miles Lubin](http://www.mit.edu/~mlubin/). You should compare JuMP with tools like [PuLP](http://code.google.com/p/pulp-or/) and [AMPL](http://www.ampl.com). If you aren't familiar with algebraic modelling languages embedded in other languages, you can think of them as an embedded [domain specific language (DSL)](http://en.wikipedia.org/wiki/Domain_specific_language). Julia's fantastic [metaprogramming functionality](http://docs.julialang.org/en/latest/manual/metaprogramming/) has allowed us to create a particularily fast and expressive modelling language. I encourage you to read to the brief documentation, but here is a taste of what it looks like.


{% highlight julia linenos %}
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
    
    sol = zeros(Int, 9, 9)
    for row in 1:9
      for col in 1:9
        for val in 1:9
          if mipSol[row, col, val] >= 0.9  # mipSol is stored as floats
            sol[row, col] = val
          end
        end
      end
    end

    return sol
  end
end
{% endhighlight %}

Line 7 creates our variable _x_ with three indices over the range 1 to 9, and enforces integrality. ``@defVar`` is a macro, not a function, which lets it create a variable ``x`` in the local scope. I have removed the other constraints for brevity and left the constraint that enforces that each cell contains only one value. Note the correspondance between the mathematical notation ("for all rows, for all columns") and the ``for`` loops (lines 11 and 12). ``@addConstraint`` (line 13) is another macro that facilitates the efficient storage of the constraint as a sparse vector, and matches the mathematical description very closely. On line 19 we solve the model with the default solver [COIN-OR CBC](https://projects.coin-or.org/Cbc) - an open-source integer programming solver. As a side note, Julia/JuMP also has interfaces to GLPK (open-source) and Gurobi (closed-source). Finally, we pull the solution back from the solver (if a feasible solution could be found) as a three-dimensional matrix of 0s and 1s which we convert to a two-dimensional vector of 1-to-9s (lines 27 to 36).

If you are interested in how macros and metaprogramming offer up new possibilities for optimization, operations research, and modelling languages, check out our [paper](http://www.optimization-online.org/DB_FILE/2013/05/3883.pdf).

## SaaS == Sudoku-as-a-service?

Now we can solve sudoku puzzles, we should share this functionality with the world. The best way to get started with creating a web service is to use the [HttpServer.jl](https://github.com/hackerschool/HttpServer.jl) package, a package made at [Hacker School](https://www.hackerschool.com/). Documentation is pretty scarce at this point, but hopefully by inspecting the relatively short code and looking at some examples you can get started. 

I bundled my sudoku solver with a server in [SudokuService](https://github.com/IainNZ/SudokuService). This kinda brings me back to why I used integer programming - to demonstrate that you can make pretty complex web-capable number crunching applications with relative ease. Check out ``server.jl`` in the repository - its pretty straightforward and most of the work is input validation. The form of a query is ``/sudoku/123...123`` or ``/sudoku/123...123/pretty`` for human-readable response. There should be 81 numbers, one for each cell of the 9x9 sudoku board, row-wise. A zero indicates a blank. Heres a taster of the server code:

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
      return Response(400, "Error: expected 81 numbers.")
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
            return Response(422, "Error: number out of range 0:9.")
          end
          prob[row,col] = val
          pos += 1
        end
      end
    catch
      return Response(422, "Error: couldn't parse numbers.")
    end

    # Attempt to solve the problem using integer programming
    try
      sol = SolveModel(prob)
      if prettyoutput
        # Human readable output
        out = "<table>"
        for row = 1:9
          out = string(out,"<tr>")
          for col = 1:9
            out = string(out,"<td>",sol[row,col],"</td>")
          end
          out = string(out,"</tr>")
        end
        out = string(out,"</table>")
        return Response(out)
      else
        # Return solution like input
        return Response(join(sol,""))
      end
    catch
      return Response(422, "Error: coudn't solve puzzle.")
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

Julia is still growing (rapidly) - I suggest grabbing the 0.2 pre-release and having a bit of patience in case of strange errors! You may also see some warnings regarding deprecation - hopefully they'll be cleaned up soon once we reach version 0.2 for Julia and have a chance to go back and tidy up all the packages. Instructions for installing everything are in ``README.md``. I encourage you to check it out for yourself, and maybe extend it.  Some ideas:
 
 * Implement a pure-Julia sudoku solver and benchmark performance against the MIP solver.
 * Generalize the code to accept and solve n-by-n sudoku problems

Let me know how that goes by contacting me at idunning AT mit.edu or [@iaindunning](https://www.twitter.com/iaindunning).
