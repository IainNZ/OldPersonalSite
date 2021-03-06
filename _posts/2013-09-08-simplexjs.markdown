---
author: idunning
date: 2013-09-08 12:00:00+00:00
layout: post
title: SimplexJS
---

**SimplexJS** is a Javascript library that solves [linear programming problems](http://en.wikipedia.org/wiki/Linear_programming) (LPs) and [mixed-integer linear programming problems](http://en.wikipedia.org/wiki/Linear_programming#Integer_unknowns) (MILPs) right in your browser. I'm not sure if this is particularily useful for any industrial application, but was fun to make, and could be used for teaching. It solves linear programs using the [Simplex](http://en.wikipedia.org/wiki/Simplex_algorithm) method, and uses branch-and-bound to solve problems with integer variables. LPs must be provided as dense matrices and vectors, in the following form:

 * minimize **c** . **x**
 * subject to A **x** = **b**
 * and **l** \<= **x** \<= **u**

This implementation is about as basic as it gets, but is hopefully "correct". The branch-and-bound solver might not be, and is certainly not very efficient. 


## Demo: Travelling Salesman Problem


### What is a "TSP"?

From the [Georgia Institue of Technology website](http://www.tsp.gatech.edu/problem/index.html):

> Given a collection of cities and the cost of travel between each pair of them, the traveling salesman problem, or TSP for short, is to find the cheapest way of visiting all of the cities and returning to your starting point. In the standard version we study, the travel costs are symmetric in the sense that traveling from city X to city Y costs just as much as traveling from Y to X.

### Integer Programming Formulation

Given our definition of a TSP from above, we can start formulating the problem as an integer program:

{% img /images/simplextspobj.png Minimize %}
{% img /images/simplextspcon1.png Must enter every city %}
{% img /images/simplextspcon2.png Must leave every city %}

where our *xij* is a binary (0 or 1) variable that says if we will go from city *i* to city *j* on our tour. We are dealing with just the case where the costs between cities are symmetric, that is *cij = cji*, so this can be simplified considerably. The simplified IP for a 4 city problem would have:

  * A variable xij for each link: (1,2) (1,3) (1,4) (2,3) (2,4) (3,4)
  * A constraint for each city, that says each city must be visited and left:
    * x1,2 + x1,3 + x1,4 = 2
    * x1,2 + x2,3 + x2,4 = 2
    * x1,3 + x2,3 + x3,4 = 2
    * x1,4 + x2,4 + x3,4 = 2

### Try it out

So now we've got our integer programming formulation, let's try it out on a problem. Click the Reset button below - the default configuration of cities should (magically) appear.

<div style="text-align: center;">

<canvas id="cityContainer" width="400" height="400"
        onmousemove="moveHandler(event);"
        onmousedown="mouseDownHandler(event);"
        onmouseup="mouseUpHandler(event);"
        onmouseout="mouseUpHandler(event);"></canvas>
<br>
<input type="button" value="Solve TSP using branch-and-bound" onclick="javascript:SolveTSP()">
<input type="button" value="Add city" onclick="javascript:AddCity()">
<input type="button" value="Reset" onclick="javascript:ResetCities();">

</div>

You can drag the cities around and re-solve, or add cities to make it more complex. When you are ready to move on, click the Reset button.

You may notice that the solution is not quite right for certain arrangements. While each city is visited and left, the optimal solution was not a path through all the cities but instead two smaller paths. We can call these smaller tours _subtours_, and the constraints necessary to eliminate them are called _subtour-elimination constraints_.


### Subtour-Elimination Constraints


For a better and more detailed explanation of this, check out the [Georgia Tech](http://www.tsp.gatech.edu/methods/opt/subtour.htm) website.

To complete our integer programming formulation we need to add these subtour-elimination constraints. An example of a subtour elimination constraint for the 6 city problem shown above would be:
	
  * x0,1 + x1,2 + x0,2 <= 2

This says that no more than two of the arcs between the nodes (0,1,2) are allowed to be in the solution. Here is something to try: how many possible subtour-elimination constraints are there for this problem? The answer is big, and keeps getting bigger as the number of cities grows. It'd take a long time to just write out all those constraints, let alone solve it. And yet, people solve TSPs with integer programming - so whats the secret?

Lets try adding that subtour-elimination constraint we worked out before:

<textarea id="subtoursEntry" cols="80" rows="10">
// Insert subtour elimination constraints here. The model building code in 
// this webpage will evaluate the code in this box before solving, allowing
// use to tell it to add some extra constraints by saying which arcs are in
// each subtour.
// Remove the // from the start of the next line to add a constraint.
// subtours.push([ [[0,1], [0,2], [1,2]], 2 ]) // Adds  x01 + x02 + x12 <= 2
</textarea>

Have you followed the above instructions? Now re-solve the TSP above. Perfect!

We only need one of the many possible subtour-elimination constraints to change our nearly-correct solution into the optimal solution. A very similar method was first used [quite some time ago, in 1954](http://www.tsp.gatech.edu/methods/dfj/index.html) to solve a problem with 49 cities! This way of solving a problem, by first solving a relaxed version of it and then adding constraints (or "cuts") to improve the relaxation, is one of the techniques used to solve all sorts of integer programs.

### Output from the Integer Progamming Solver

We can see what the solver is doing by looking at the output that appears below when we hit "Solve".

<p id="output" style="font-family: monospace">

</p>

<script type="text/javascript" src="/images/SimplexJS.js"></script>
<script type="text/javascript">
var numCities = 6;
var cities = [	[ 50, 200],
				[100, 100],
				[100, 300],
				[300, 100],
				[300, 300],
				[350, 200]	];
var curSolution = [];
var dragging = false;
var draggingIndex = -1;
var lastX = -1, lastY = -1;
var subtours = [];

function ResetCities(e)
{
	numCities = 6;
	cities = [	[ 50, 200],
				[100, 100],
				[100, 300],
				[300, 100],
				[300, 300],
				[350, 200]	];
	curSolution = [];
	dragging = false;
	draggingIndex = -1;
	lastX = -1, lastY = -1;
	subtours = [];
	DrawCities();
}

function mouseDownHandler(e)
{
	var x = e.pageX - e.target.offsetLeft;
	var y = e.pageY - e.target.offsetTop;
	for(var i = 0; i < numCities; i++) {
		var dist = (cities[i][0]-x)*(cities[i][0]-x) + (cities[i][1]-y)*(cities[i][1]-y);
		if (dist <= 25*25) {
			dragging = true;
			lastX = x;
			lastY = y;
			draggingIndex = i;
		}
	}
}

function mouseUpHandler(e)
{
	dragging = false;
	lastX = -1;
	lastY = -1;
}

function moveHandler(e) {
	if (dragging) {
		var x = e.pageX - e.target.offsetLeft;
		var y = e.pageY - e.target.offsetTop;
		var deltaX = x - lastX;
		var deltaY = y - lastY;

		cities[draggingIndex][0] += deltaX;
		cities[draggingIndex][1] += deltaY;
 
		lastX = x;
		lastY = y;
		DrawCities();
	}
}

function AddCity() {
	numCities += 1;
	cities.push([Math.random()*400, Math.random()*400]);
	DrawCities();
}


function DrawCities() {
	var canv = document.getElementById("cityContainer");
	var ctxt = canv.getContext("2d");
	ctxt.fillStyle = "#DDDDDD";
	ctxt.fillRect(0, 0, canv.width, canv.height);
	for (i = 0; i < curSolution.length; i++) {
		ctxt.beginPath();
		ctxt.moveTo(cities[curSolution[i][0]][0], cities[curSolution[i][0]][1]);
		ctxt.lineTo(cities[curSolution[i][1]][0], cities[curSolution[i][1]][1]);
		ctxt.closePath();
		ctxt.strokeStyle = "#FF0000";
		ctxt.stroke();

	}
	for (i = 0; i < numCities; i++) {
		ctxt.beginPath();
		ctxt.arc(cities[i][0], cities[i][1], 20, 0, Math.PI * 2, false);
		ctxt.closePath();
		ctxt.strokeStyle = "#000000";
		ctxt.stroke();
		ctxt.fillStyle = "#0000FF";
		ctxt.fill();
		ctxt.fillStyle = "#FFFFFF";
		ctxt.font = "bold 12px sans-serif";
		ctxt.fillText(i.toString(), cities[i][0]-5, cities[i][1]+5);
	}
}

function SolveTSP() {

	document.getElementById("output").innerHTML = "Starting SolveTSP()<br>"

	// Load city locations, and calculate distances
	var Cij = new Array(numCities);
	for (i = 0; i < numCities; i++) {
		Cij[i] = new Array(numCities);
		for (j = 0; j < numCities; j++) {
			Cij[i][j] = Math.sqrt( (cities[i][0] - cities[j][0]) * (cities[i][0] - cities[j][0])
								  +(cities[i][1] - cities[j][1]) * (cities[i][1] - cities[j][1]))
		}
	}

	// Create the IP
	var tsp = {};

	// Create cost vector, map arc to column
	// x00 x01 x02 x03 x04 x05 x10 x11 ...
	tsp.n = (numCities)*(numCities-1)/2;
	tsp.c = new Array(tsp.n);
	var col = new Array(), z=0;
	for (i = 0; i < numCities; i++) {
		for (j = i+1; j < numCities; j++) {
			col[[i,j]] = z;
			col[[j,i]] = z;
			tsp.c[z] = Cij[i][j];
			z++;
		}
	}

	// Create each row of A and b
	tsp.m = numCities;
	tsp.A = new Array(tsp.m);
	tsp.b = new Array(tsp.m);
	// Degree of each city = 2 (no constraint for last city)
	for (i = 0; i < numCities; i++) {
		tsp.A[i] = new Array(tsp.n);
		for (j = 0; j < tsp.n; j++) tsp.A[i][j] = 0;
		for (j = 0; j < numCities; j++) {
			if (i!=j) tsp.A[i][col[[i,j]]] = 1;
		}
		tsp.b[i] = 2;
	}

	// Set variable bounds and type
	tsp.xLB = new Array(tsp.n);
	tsp.xUB = new Array(tsp.n);
	tsp.xINT = new Array(tsp.n);
	for (i = 0; i < tsp.n; i++) {
		tsp.xLB[i] = 0; tsp.xUB[i] = 1; tsp.xINT[i] = true;
	}


	// Add subtours
	subtours = []
	eval(document.getElementById("subtoursEntry").value);
	for (st = 0; st < subtours.length; st++) {
		stArcs = subtours[st][0];
		stSize = subtours[st][1];
		// Add the slack for this subtour
		tsp.n += 1;
		tsp.xLB.push(0);
		tsp.xUB.push(Infinity);
		tsp.c.push(0);
		tsp.xINT.push(false);
		// Modify existing constraints
		for (i = 0; i < tsp.m; i++) tsp.A[i].push(0);
		// Add new constraint
		tsp.m += 1;
		tsp.b.push(stSize);
		tsp.A.push(new Array());
		for (i = 0; i < tsp.n; i++) tsp.A[tsp.m-1][i] = 0;
		for (starc = 0; starc < stArcs.length; starc++) {
			i = stArcs[starc][0];
			j = stArcs[starc][1];
			tsp.A[tsp.m-1][col[[i,j]]] = 1;
		}
		tsp.A[tsp.m-1][tsp.n-1] = 1; // slack
	}

	// Solve
	var log = [];
	SimplexJS.MAXITERATIONS = 1000;
	SimplexJS.SolveMILP(tsp, 20, log);
	var logstr = "";
	for (i = 0; i < log.length; i++) logstr += log[i] + "<br>"
	document.getElementById("output").innerHTML = logstr

	// Display answer
	if (tsp.status == SimplexJS.OPTIMAL) {
		//var out = "Solved!<br>Size of branch-and-bound tree was " + tsp.nodeCount.toString() + " (limit: 20)<br>";
		//out += tsp.n.toString() + " variables, " + tsp.m.toString() + " constraints.<br>";
		curSolution = [];
		for (i = 0; i < numCities; i++) {
			for (j = i+1; j < numCities; j++) {
				if (tsp.x[col[[i,j]]]) {
					//out += "Arc from City " + (i+1).toString() + " to City " + (j+1).toString() + "<br>";
					curSolution.push([i,j]);
				}
			}
		}
	}
	DrawCities();

}

DrawCities();
</script>
