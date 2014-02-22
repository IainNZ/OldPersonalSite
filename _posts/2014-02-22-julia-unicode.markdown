---
author: idunning
date: 2014-02-22 12:00:00+00:00
layout: post
title: Fun with Unicode and Julia
---

The [Julia](http://julialang.org) programming language has excellent support for Unicode. One of the main benefits is that you are no longer restricted to using English characters when writing code - for example, Chinese speakers may prefer to name their variables or functions in Chinese instead of English.

### Mathematical Notation

English users can still benefit though, especially when it comes to mathematics-heavy code. Mathematical academic papers make heavy use of the Greek alphabet but most languages don't support Unicode identifiers. This leads to code sprinkled with variables name `mu` and `sigma`. Julia, however, doesn't mind Unicode identifiers one bit. Take this example edited snippet from [Distributions.jl](https://github.com/JuliaStats/Distributions.jl), a Julia package that really uses the language's design to the maximum:

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

The only (and not insubstantial) downside to this is that this is difficult to write/edit in most text editors without a lot of copy-pasting. I would argue though that in limited cases like in Distributions.jl it is worth it - the code is not going to change, and is going to be read many more times than it will be edited.


### Non-standard string literals

What is a non-standard string literal? From the [Julia manual](http://docs.julialang.org/en/latest/manual/strings/#non-standard-string-literals):

> There are situations when you want to construct a string or use string semantics, but the behavior of the standard string construct is not quite what is needed. For these kinds of situations, Julia provides non-standard string literals. A non-standard string literal looks like a regular double-quoted string literal, but is immediately prefixed by an identifier, and doesn’t behave quite like a normal string literal. Regular expressions, as described below, are one example of a non-standard string literal.

A regular expression in Julia looks like this: ``r"^\s*(?:#|$)"``. You can define your own non-standard string literals using macros, and if you use Unicdoe... For example, consider the following macros:

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


### Optimization variables names

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