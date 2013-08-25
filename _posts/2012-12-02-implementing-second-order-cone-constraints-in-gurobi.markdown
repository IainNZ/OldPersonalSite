---
author: idunning
comments: false
date: 2012-12-02 17:37:48+00:00
layout: post
slug: implementing-second-order-cone-constraints-in-gurobi
title: Implementing Second-order Cone Constraints in Gurobi
wordpress_id: 107
---

While working on a class project I came across the following constraint that arose from "robustifying" a linear constraint with an ellipsoidal uncertainty set:


[![](http://www.iaindunning.com/wp-content/uploads/2012/12/form1.png)](http://www.iaindunning.com/wp-content/uploads/2012/12/form1.png)


where D is a diagonal matrix. In our case, _a_ is the nominal value and the diagonal of D are the _"a-hat"_ values that represent the small deviations we are robustifying against. This is a second-order cone constraint, so I needed to use [second-order cone programming](http://en.wikipedia.org/wiki/Second-order_cone_programming) (SOCP). You can see from the Wikipedia page that this equation satisfies the form on that page. Gurobi 5.0 [supports](http://www.gurobi.com/products/gurobi-optimizer/what's-new-in-v5.0) quadratic constraints and second-order cone problems, so how do you implement them? There is no "L2 norm" function in the API, so we will have to modify the constraint into a different form. Your first guess might be to move the first term to the right hand side and square both sides


[![](http://www.iaindunning.com/wp-content/uploads/2012/12/form2.png)](http://www.iaindunning.com/wp-content/uploads/2012/12/form2.png)


There is a problem here: both sides of this equation are convex, so this constraint doesn't obviously describe a convex set (try it in [CVX](http://cvxr.com/cvx/), it will be unhappy with you). I actually tried this first, and Gurobi reported that the constraint was not positive-semi-definite (PSD), which is true. Gurobi sees this as me trying to enter an invalid quadratic constraint, not as entering a SO constraint. So what is the right form?

The key is to look at documentation in the [right place](http://www.gurobi.com/documentation/5.0/reference-manual/node265) (see second bullet point). However, what actually happened was that my friend [Miles Lubin](http://www.mit.edu/~mlubin/) and I ended up doing it the hard way by looking at Gurobi's MATLAB interface and figuring out the form SOCP's must follow from that! We also had help from Chris Maes on the [Gurobi Google Group](https://groups.google.com/d/topic/gurobi/UlCbvUjCs_w/discussion), which confirmed our suspicions. In retrospect it seems obvious, from the definition of a second-order cone, but we sure did manage to confuse ourselves. To save someone else time in the future, if you have a constraint like this that has come from using an ellipsoidal uncertainty set, you need to do the following:


[![](http://www.iaindunning.com/wp-content/uploads/2012/12/form3v2.png)](http://www.iaindunning.com/wp-content/uploads/2012/12/form3v2.png)




To demonstrate what this would look like in C++, I made the following code snippet:




    
    // Somewhere previously...
    // GRBModel model = ...
    // vector<GRBVar> x = ...
    // vector<double> a = ...
    // vector<double> ahat = ...
    // int n = ...; double b = ...;
    
    // New constraint 1
    GRBVar t = model.addVar(0, GRB_INFINITY, 0, GRB_CONTINUOUS);
    model.update();
    GRBLinExpr teq;
    teq += b;
    for (int j = 0; j < n; j++)
      teq -= a[j]*x[j];
    model.addConstr(t == teq);
    model.update();
    
    // New constraints 2
    vector<GRBVar> y(n);
    for (int j = 0; j < n; j++)
      y[j] = model.addVar(-GRB_INFINITY, GRB_INFINITY, 0, GRB_CONTINOUS);
    model.update();
    for (int j = 0; j < n; j++)
      model.addConstr(y[j] == ahat[j]*x[j]);
    model.update();
    
    // The final constraint
    GRBQuadExpr lhs;
    for (int j = 0; j < n; j++)
      lhs += y[j]*y[j];
    model.addQConstr(lhs <= t*t);
    model.update();
