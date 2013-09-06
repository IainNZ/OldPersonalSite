---
author: idunning
comments: false
date: 2012-08-03 01:30:50+00:00
layout: page
slug: simplexjs
title: SimplexJS
wordpress_id: 32
---

[![](http://idunning.scripts.mit.edu/blog/wp-content/uploads/2012/08/simplexjs.png)](http://idunning.scripts.mit.edu/blog/wp-content/uploads/2012/08/simplexjs.png)[Download](https://github.com/IainNZ/SimplexJS/zipball/master) SimplexJS from GitHub ([repository](https://github.com/IainNZ/SimplexJS))




**SimplexJS** is a Javascript library that solves [linear programming problems](http://en.wikipedia.org/wiki/Linear_programming) (LPs) and [mixed-integer linear programming problems](http://en.wikipedia.org/wiki/Linear_programming#Integer_unknowns) (MILPs) right in your browser. I'm not sure if this is particularily useful for any industrial application, but was fun to make, and could be used for teaching. It solves linear programs using the [Simplex](http://en.wikipedia.org/wiki/Simplex_algorithm) method, and uses branch-and-bound to solve problems with integer variables.


The Simplex implementation is correct as far as I can tell, but the branch-and-bound solver might not be, and is certainly not very efficient. LPs must be provided as dense matrices and vectors, in the following form:

    
    min c.x
    st   Ax == b
     l <= x <= u




### Demonstration - solving the Travelling Salesperson Problem in your browser


To demonstrate that the code does indeed work, I made an [interactive demo](?page_id=39) that lets you construct instances of the Travelling Salesperson Problem (TSP) and solve them using the sub-tour elimination (cutting plane) method. You can find it here (probably will want a browser made in the past couple of years to make sure it works!)


### Future Plans


I haven't worked on it much since I initially made it, but I hope to do the following:



	
  * Check the implementation of the simplex method.

	
  * Add some modelling tools - making the A matrix by hand is very painful and is hindering the practicality of this code!

	
  * Accept problems in a more general form and transform them to the above form.

	
  * Make the branch-and-bound code less stupid. It was made in a very short amount of time!

	
  * Make more examples.


