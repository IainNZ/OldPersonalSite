---
author: idunning
date: 2014-02-22 12:00:00+00:00
layout: post
title: Fun with Unicode and Julia
---

The [Julia](http://julialang.org) programming language has excellent support for Unicode. One of the main benefits is that you are no longer restricted to using English characters when writing code - for example, Chinese speakers may prefer to name their variables or functions in Chinese instead of English.

### Serious-fun: Mathematical notation

English users can still benefit though, especially when it comes to mathematics-heavy code. Mathematical academic papers make heavy use of the Greek alphabet, but you don't often seem them in code - this leads to variables name like `mu` and `sigma` appearing everywhere. Julia, however, doesn't mind Unicode identifiers one bit (apparently [many other languages](http://rosettacode.org/wiki/Unicode_variable_names) don't either) and in fact has a much more welcoming attitude to them than I've seen elsewhere. Take this example (abridged) snippet from [Distributions.jl](https://github.com/JuliaStats/Distributions.jl), a Julia package that really uses the language's design to the maximum:

{% highlight julia %}

immutable Normal <: ContinuousUnivariateDistribution
    μ::Float64
    σ::Float64
    function Normal(μ::Real, σ::Real)
        σ > zero(σ) || error("std.dev. must be positive")
        new(float64(μ), float64(σ))
    end

    Normal(μ::Real) = Normal(float64(μ), 1.0)
    Normal() = Normal(0.0, 1.0)
end

mean(d::Normal) = d.μ
median(d::Normal) = d.μ
zval(d::Normal, x::Real) = (x - d.μ)/d.σ
var(d::Normal) = abs2(d.σ)
std(d::Normal) = d.σ
pdf(d::Normal, x::Real) = φ(zval(d,x))/d.σ

{% endhighlight %}

We could even dream up our own (substantially less useful) code:

{% highlight julia %}
∑(x) = sum(x)  # Could also do ∏(x) = prod(x)
√(x) = sqrt(x)
function normalize(x)
    return x ./ √(∑(x.^2))
end
println(normalize([4,2,1]))
{% endhighlight %}

The only (and not insubstantial) downside to this is that this is difficult to write/edit in most text editors without a lot of copy-pasting or add-ins (e.g. [Sublime Text](https://github.com/mvoidex/UnicodeMath)). I would argue though that in limited cases like in Distributions.jl it is worth it - the code is not going to change, and is going to be read many more times than it will be edited.


### Fun: non-standard string literals

What is a non-standard string literal? From the [Julia manual](http://docs.julialang.org/en/latest/manual/strings/#non-standard-string-literals):

> There are situations when you want to construct a string or use string semantics, but the behavior of the standard string construct is not quite what is needed. For these kinds of situations, Julia provides non-standard string literals. A non-standard string literal looks like a regular double-quoted string literal, but is immediately prefixed by an identifier, and doesn’t behave quite like a normal string literal. Regular expressions, as described below, are one example of a non-standard string literal.

A regular expression in Julia looks like this: ``r"^\s*(?:#|$)"``. You can define your own non-standard string literals using macros, and if you use Unicode... For example, consider the following macros:

{% highlight julia %}

macro ♥‿♥_str(s)
    "I LOVE $(uppercase(s))"
end

println( ♥‿♥"Julia" )  # I LOVE JULIA

macro 爆発_str(text)
    out_str = "****BOOM**** "
    for c in text
        r = rand()
        if r < 0.45
            out_str = string(out_str, lowercase(c))
        elseif r < 0.90
            out_str = string(out_str, uppercase(c))
        else
            out_str *= "#"
        end
    end
    return out_str * " ****BOOM****"
end
println( 爆発"Julia and Unicode" )  # ****BOOM**** juli# #nd UNIco## ****BOOM****
println( 爆発"Julia and Unicode" )  # ****BOOM**** J#L## aND unICODE ****BOOM****
println( 爆発"Julia and Unicode" )  # ****BOOM**** julIa And UniC#dE ****BOOM****

{% endhighlight %}


### Fun-for-some: Optimization variables names

Unicode names might make for interesting keys in a dictionary. The following code requires [JuMP](http://github.com/JuliaOpt/JuMP.jl) and an integer programming solver, e.g. [Cbc](http://github.com/JuliaOpt/Cbc.jl) - both are available through the Julia package manager.

{% highlight julia %}
using JuMP

type Suit
    value
    weight
end
♠ = Suit(5.0, 2.0)
♣ = Suit(2.0, 1.0)
♥ = Suit(3.0, 2.0)
♦ = Suit(6.0, 3.0)
suits = [♠,♣,♥,♦]

m = Model()
@defVar(m, x[suits], Bin)
@setObjective( m, Max, sum{s.value  * x[s], s in suits})
@addConstraint(m,      sum{s.weight * x[s], s in suits} <= 3.0)
solve(m)

print("Selected hand: [")
getValue(x[♠]) > 0.99 && print("♠")
getValue(x[♣]) > 0.99 && print("♣")
getValue(x[♥]) > 0.99 && print("♥")
getValue(x[♦]) > 0.99 && print("♦")
println("]")  # Selected hand: [♠♣]

{% endhighlight %}


### Here-be-dragons-fun: Visually similar symbols

Something the Julia community recently had to work through is how to handle Unicode characters that look very similar. One issue that I don't believe affects Julia but affects other languages is the non-breaking-space, which is visually identical to the normal space: this [sample code from Ruby](http://www.rubyinside.com/the-split-is-not-enough-whitespace-shenigans-for-rubyists-5980.html) shows the counter-intuitive results.

The issue with Julia (version 0.2) can be summed in a short snippet of code:

{% highlight julia %}
julia> const μ = 3
3

julia> µ + 1
ERROR: µ not defined
{% endhighlight %}

The problem is that we are using ``μ`` ("micro sign") and ``µ`` ("Greek small letter mu"), an easy mistake to make in practice. This was discussed at length in [Issue #5434](https://github.com/JuliaLang/julia/issues/5434). To summarize the outcome, it turns out that there is a [whole Wikipedia page](https://en.wikipedia.org/wiki/Unicode_equivalence) dedicated to the various degrees of equivalences one can draw. The decision to be made is what degree of conservativeness you want to apply. At one end of the spectrum is making almost everything possible equivalent, e.g. treat ``ℍ`` and ``H`` as the same. At the other end is basically doing nothing (or maybe only for a strict subset of "common" mistakes.) In the end the discussion settled on using the "NFC" normalization, with any further issues addressed as they arise. Python3 seems to have [selected NFC as well](http://legacy.python.org/dev/peps/pep-3131/#implementation).

The ability to use Unicode in identifiers is not a widely used one for general purpose computing, and with the exception of non-English identifiers this is probably a good thing for maintainability. I do hope to see it used with more confidence in technical computing, if it aids understanding of algorithm implementation.