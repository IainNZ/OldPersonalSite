---
author: idunning
date: 2015-08-11 12:00:00+00:00
layout: post
category: julia
title: Analyzing Julia's issue counts over time
---

In this post we'll be analyzing the number of issues open on the [Julia language](http://julialang.org)'s [issue tracker](https://github.com/JuliaLang/julia/issues?q=sort%3Aupdated-desc). We'll be counting both issues (bug reports, ideas, plans) and "pull requests" (PRs, code that has been submitted for review before merging it into the langauge). What I'm mainly interested in how the number of "open" issues/PRs varies over time, and how that relates to the total number of issues/PRs.

For this job we'll need three Julia packages, all made by community members:

* [`GitHub.jl`](https://github.com/WestleyArgentum/GitHub.jl), to query the issue tracker. We could do this manually through the GitHub API, but this is much easier.
* [`JLD.jl`](https://github.com/JuliaLang/JLD.jl), which we'll use to cache the API results in a file.
* [`Gadfly.jl`](https://gadflyjl.org), a plotting package for Julia.
* If you are on Julia 0.3, you'll also need [`Dates.jl`](https://github.com/quinnj/Dates.jl), which provides string-to-date conversions and more. Its built into the standard library in Julia 0.4, but Julia 0.4 hasn't been released as of the time of writing.

All of these can be installed with the Julia package manager, e.g. `Pkg.add("GitHub"); Pkg.add("JLD")` and so on. If you haven't used Julia in a while, you might want to run `Pkg.update()` first so you get the freshest versions of these packages.

First step, load the packages

{% highlight julia %}



using GitHub, JLD, Gadfly
using Dates  # Only needed on Julia 0.3.x


{% endhighlight %}

We use the `issues` function of the `GitHub.jl` package to download every open and closed issue or pull request (PR) for the `julia` repository - this takes a while, as it needs to download a fair bit of data. You'll want to get an "auth token", so that Github won't bounce our request as a spam attack of some sort. You can get this by signing up for a Github account, if you don't already have one, and going to your settings page.

{% highlight julia %}



# Replace with your token
TOKEN = "yourauthtokenhere"
# Authenticate with GitHub, so they know we're legit
my_auth = authenticate(TOKEN)
# Pull all open issues...
open_issues = issues(my_auth,"JuliaLang","julia",state="open")
# ... and all closed issues (10x as many of these)
closed_issues = issues(my_auth,"JuliaLang","julia",state="closed")
# Combine them into one vector of issues
all_issues = vcat(open_issues,closed_issues)


{% endhighlight %}

We'll create a little type that just keeps the creation and close dates.
If an issue is open, it doesn't have a close date, so we'll just use a time far in the future (Jan 1, 2099!) for now. The `DateTime` function creates a `DateTime` object from a string (or from manually spelling out a date).

{% highlight julia %}



# Define our reduced issue type
type SimpleIssue
    created_at::DateTime
    closed_at::DateTime
end
# Provide a constructor that takes in
# cr   creation date
# cl   close data - might be `nothing` = open
SimpleIssue(cr::String,cl) = SimpleIssue(
    DateTime(cr), 
    cl == nothing ? DateTime(2099,1,1) : DateTime(cl) )


{% endhighlight %}

We now use the `JLD.jl` package to serialize this data to a file in case we want to come back and analyze it later. `JLD.jl` can save pretty much any Julia thing, even types you define. Read the README for caveats!

{% highlight julia %}



save("all_issues.jld","all_issues",
    [SimpleIssue(i.created_at, i.closed_at) for i in all_issues])


{% endhighlight %}

We'll pretend we're revisiting this some time in the future. Loading data is just the reverse of saving it with JLD:

{% highlight julia %}



all_issues = load("all_issues.jld", "all_issues");


{% endhighlight %}

Now for some actual work. We collect a vector of every date "seen" - this is basically every day something happened on the issue tracker, which is probably almost every day since the announcement of Julia.

{% highlight julia %}



all_create_dts = [Date(i.created_at) for i in all_issues]
all_close_dts = [Date(i.closed_at) for i in all_issues]
all_dates = unique(sort(vcat(all_create_dts,all_close_dts)))
length(all_dates)


{% endhighlight %}




1457



Now for the actual counting. We'll use a not-particularly-efficient method, but quick enough for the data at hand. For each issue/PR, simply increment a count for each date that the issue/PR was open (the dates between its opening and closing). We'll also keep a count of total opened ever versus date.

{% highlight julia %}



# Initialize two dictionaries of dates=>counts
open_at_count  = Dict{Date,Int}()
total_at_count = Dict{Date,Int}()
for d in all_dates
    open_at_count[d]  = 0
    total_at_count[d] = 0
end
# For each issue/PR...
for iss in all_issues
    create_dt = iss.created_at
    close_dt  = iss.closed_at
    # For every date...
    for d in all_dates
        # If the issue was made before...
        if d >= create_dt
            # Then it existed on this date
            total_at_count[d] += 1
            # If it was closed after this...
            if d <= close_dt
                # Then it is open on this date
                open_at_count[d] += 1
            end
        end
    end
end


{% endhighlight %}

To finish, lets plot these two quantities versus time using `Gadfly` - just simple line plots will do.

{% highlight julia %}



# Collect results into vectors
open_vec = [open_at_count[d] for d in all_dates];
total_vec = [total_at_count[d] for d in all_dates];
# Correct for special last day (currently open)
plot_dates = vcat(all_dates[1:end-1], all_dates[end-1]+Day(1))
# Draw the results as a PNG (default is SVG)
draw(PNG(8inch,4inch),
plot(x=plot_dates,y=total_vec,Geom.line,
        Guide.Title("Total Issues/PR"),
        Guide.xlabel("Date"), Guide.ylabel("Count"))
)


{% endhighlight %}


![Total Issues](/images/JuliaIssueCount/JuliaIssueCount_15_0.png)


{% highlight julia %}



draw(PNG(8inch,4inch),
plot(x=plot_dates,y=open_vec,Geom.line,
        Guide.Title("Open Issues/PR"),
        Guide.xlabel("Date"), Guide.ylabel("Count"))
)


{% endhighlight %}


![Open Issues](/images/JuliaIssueCount/JuliaIssueCount_16_0.png)


Finally, we'll look at what fraction of the issues/PRs are open at any one time. As you can see, it seems to have "converged" to about 10% - I wonder why? One explanation is that whenever it gets much over 10% then people get the urge to review older issues and fix or close them. When it drops below 10%, people don't care too much. Another explanation is that there is a core of things in the "too hard" pile at any one time, and the number of those "too hard" things is going up but at no greater a rate than the overall number of issues.

{% highlight julia %}



draw(PNG(8inch,4inch),
plot(x=plot_dates,y=open_vec./total_vec,Geom.line,
        Guide.Title("Open:Total Issues/PR"),
        Guide.xlabel("Date"), Guide.ylabel("Fraction"))
)


{% endhighlight %}

![Open/Total Issues](/images/JuliaIssueCount/JuliaIssueCount_18_0.png)

