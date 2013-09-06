---
author: idunning
comments: false
date: 2012-08-02 04:30:17+00:00
layout: page
slug: macrostats
title: MacroStats
wordpress_id: 26
---

[![](http://idunning.scripts.mit.edu/blog/wp-content/uploads/2012/08/macrostats.png)](http://idunning.scripts.mit.edu/blog/wp-content/uploads/2012/08/macrostats.png)


[Download](https://github.com/IainNZ/MacroStats/zipball/master) MacroStats from GitHub ([repository](https://github.com/IainNZ/MacroStats))


**MacroStats** is a collection of statistics-related functions for Excel's [VBA macro language](http://en.wikipedia.org/wiki/Visual_Basic_for_Applications). The library arose from some work I did on various projects at [Scarlatti](http://www.scarlatti.co.nz/) in 2011, and I thought they might save someone from "reinventing the wheel" - possibly myself!

There aren't a huge number of functions, but I'd really love feedback if you use it at all. It is licensed under the very permissive [MIT License](http://www.opensource.org/licenses/mit-license.php), which will let you use it safely in commercial projects.


### Features




#### Random Number Generators





	
  * RandomFromNormal (_mean_, _stddev)_

	
    * Uses [Box-Mueller](http://en.wikipedia.org/wiki/Normal_distribution#Generating_values_from_normal_distribution) to generate a random number from a [normal distribution](http://en.wikipedia.org/wiki/Normal_distribution).




	
  * FlipCoin (_prob_)

	
    * Returns True with probability _prob_.




	
  * SampleDiscreteCDF (_CDF()_)

	
    * Generate a random integer from a [cumulative distribution function](http://en.wikipedia.org/wiki/Cumulative_distribution_function).




	
  * SampleDiscreteCDFon2D (_CDF(), FirstIndex_)

	
    * Generate a random integer from a cumulative distribution function.

	
    * Use this when you have a 2D array, where the CDF is in the 2nd dimension.




	
  * SampleDiscreteCDFon3D (_CDF(), FirstIndex, SecondIndex_)

	
    * Generate a random integer from a cumulative distribution function.

	
    * Use this when you have a 3D array, where the CDF is in the 3rd dimension.





As an example of how to use the SampleDiscreteFromCDF functions, consider the following code snippet:

    
    Dim myCDF(3 to 6) as Double
    myCDF(3) = 0.1
    myCDF(4) = 0.5
    myCDF(5) = 0.9
    myCDF(6) = 1.0
    Debug.Print SampleDiscreteCDF(myCDF)
    ' 10% chance of returning a 3, 40% chance of a 4, etc.


The 2D and 3D versions are useful when you have a matrix describing multiple CDFs. See the code for a detailed example on exactly how to use these.


#### Distribution Fitting Functions





	
  * FitNormalDistributionToData

	
    * Inputs: _data()_

	
    * Outputs: _mean, stddev_

	
    * Fits a [normal distribution](http://en.wikipedia.org/wiki/Normal_distribution) to a data set provided by the user. Uses [Maximum Likelihood Estimation](http://en.wikipedia.org/wiki/Normal_distribution#Estimation_of_parameters).




	
  * FitNormalDistributionToPercentiles

	
    * Inputs: _X1, P1, X2, P2_

	
    * Outputs: _mean, stddev_



	
    * Fits a normal distribution to two percentiles. For example:

	
      * 50th percentile is 60 => _X1 = 60, P1 = 0.5_

	
      * 84th percentile is 80 => _X2 = 80, P2 = 0.84_

	
      * Therefore _mean = 60, stddev = 20_







	
  * FitGammaDistributionToData

	
    * Inputs: _data()_

	
    * Outputs: _shapeP, scaleP_

	
    * Fits a [gamma distribution](http://en.wikipedia.org/wiki/Gamma_distribution) to a data set provided by the user. Uses [Maximum Likelihood Estimation with Newton-Rhapson](http://en.wikipedia.org/wiki/Gamma_distribution#Maximum_likelihood_estimation).




	
  * FitGammaDistributionToPercentiles

	
    * Inputs: _X1, P1, X2, P2_

	
    * Outputs: _shapeP, scaleP_

	
      * 50th percentile is 5000 => X1 = 5000, P1 = 0.5

	
      * 84th percentile is 6500 >= X2 = 6500, P2 = 0.84

	
      * Therefore _shapeP = 13.5, scaleP = 378.9_









