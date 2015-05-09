---
author: idunning
date: 2013-10-12 12:00:00+00:00
layout: post
title: INFORMS 2013 and JuliaOpt
---

The [INFORMS 2013](http://meetings2.informs.org/minneapolis2013/index.php) Annual Meeting took place this past week in Minneapolis, and I was lucky enough to have the chance to go. [Miles Lubin](http://www.mit.edu/~mlubin/) and I were there to present a talk based on our paper "Computing on Operations Research using Julia" ([paper](http://www.optimization-online.org/DB_HTML/2013/05/3883.html), [slides](http://www.mit.edu/~mlubin/informs2013.pdf)). I'd never been to a conference like this before, so I wasn't sure what to expect - it turned out to be a bit overwhelming! There were four time slots per day, with up to 72 sessions running during each time slot. As a result it was impossible to see anything but a small fraction of the talks. The highlights for me would have to be:

* Meeting with the team at [Forio](http://forio.com/) to talk about the work they are doing with Julia, including their simulation products and their open-source Julia IDE [Julia Studio](http://forio.com/products/julia-studio)
* Seeing the [Nicholson Prize](https://www.informs.org/Recognize-Excellence/INFORMS-Prizes-Awards/George-Nicholson-Student-Paper-Competition) contenders' presentations on Sunday, including [Vishal Gupta](www.mit.edu/~vgupta1)'s fantastic talk on data-driven robust optimization.
* Hacking on [JuMP](http://github.com/JuliaOpt/JuMP.jl) with Miles in our hotel room.
* Presenting the talk! We had a great, attentive audience, it was a real pleasure being there.
* Meeting the teams from [MOSEK](http://www.mosek.com) and [Gurobi](http://www.gurobi.com), who were really enthusiastic about the work we are doing in Julia and want to be involved.
* Finally meeting the [COIN-OR](http://www.coin-or.org/) team, especially [Ted Ralphs](http://coral.ie.lehigh.edu/~ted/).
* Celebrating Miles winning the [2013 COIN-OR Cup](http://www.coin-or.org/coinCup/coinCup.html)!

## JuliaOpt

Miles and I put a lot of thought into whats next for the burgeoning collection of optimization software and interfaces in Julia, and felt it would be appropriate to emulate the example set by [JuliaStats](https://github.com/JuliaStats) and pull all the code together in one place. We want to go further and make sure everything works together, is well documented, and well tested. One of the end goal is to make Julia _the_ choice for people working with optimization problems.

{% img http://juliaopt.org/images/logo300.png JuliaOpt logo - top: LP, left: NLP, right: IP %}

We've set up a [JuliaOpt GitHub organization](https://github.com/JuliaOpt) and a [JuliaOpt website](http://juliaopt.org) - check them out the projects, use it, report bugs, and contribute back - we'd love to have you join us.
