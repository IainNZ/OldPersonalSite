---
author: idunning
comments: false
date: 2013-05-16 21:12:36+00:00
layout: post
slug: simulation-study-of-a-laundry-room
title: Simulation Study of a Laundry Room
---

For my first two years at MIT I lived in graduate housing ([Sidney-Pacific](http://s-p.mit.edu/), to be exact). Its a big building: about 700 graduate students, one of, if not the, biggest graduate "dorm" in North America. What I'm going to discuss today is pretty mundane, but maybe of interest to some: the laundry room! Assuming nothing is broken, there are are 24 washing machines (washers) and 24 dryers. The length of a cycle on the washers is 30 minutes, and the length of a cycle is at least 1 hour on the dryers, although you can pay for longer cycles if you want.

{%img /images/laundryroom.jpg Screenshot from web-based laundry room monitor showing the layout %}

Here is the primary observation: if it takes 30 minutes for a washing cycle, and an hour for a drying cycle, how is it that there isn't a big problem? Obviously something is going on here to make it all work. What I wanted to do is experiment with [Julia](http://julialang.org/) to see what parameters would make the laundry room "work", and not have a lot of unhappy people with wet clothing!

First of all, lets characterize how people show up to the laundry. I'm going to assume initially that everyone uses only one washer, and that they arrive according to a [Poisson process](http://en.wikipedia.org/wiki/Poisson_process). The first assumption will be relaxed later, so lets look at the second assumption. Its probably not _too_ bad on a busy Saturday/Sunday morning, so we'll say thats the time of week we are looking at - if the laundry is quiet, it isn't a problem anyway. We must also acknowledge the implied assumption that the number of machines in use doesn't affect the arrival rate - this could be a big deal, although you could sort of get around it if this is the steady state rate after an adjustment for that.

Lets assume at "steady state" that 75% of the washers are in use on average (18 machines). If people are arriving at a rate of λ (lambda) per hour, and the service time is 0.5 hours (30 minutes), we will have steady state when the rate of people finishing equals the rate of people arriving. That is, λ = n/0.5. So to get an average of 18 machines in use, we should assume 36 people are arriving per hour. From my own observations, and given that less than 24 machines are often working, one person every 2 minutes at peak time seems OK. If we assume that people move their washing instantly into a dryer, again only using one of each,  λ = n/1.5, so we'd only need ~15 people an hour for things to start backing up. The model we will experiment with is as follows:
	
  * Residents arrive at a rate of λ=36 per hour. If all the washers are in use, they will leave - no queueing. If there is a free machine, they will take it and start a 30 minute cycle on a single machine.
  * At the end of the wash cycle, they will do one of two things:
    * With probability _p_ they will put their clothes in a dryer, if available, and set it for an hour cycle. If there is no free dryer they will wait for one.
    * With probability _1-p_ they will take their clothes to their room and put them on a drying rack.
    * The probabilities are independent of the number of dryers in use.

We will play with different values of p to investigate the affect on the time-averaged queue length of the dryers. The code to do this was written in [Julia](http://julialang.org/) using the [SimJulia](https://github.com/BenLauwens/SimJulia.jl) package, with inter-arrival times generated using [Distributions.jl](https://github.com/JuliaStats/Distributions.jl). We ignore the start-up effects for simplicity reasons by running the simulation for 1000 hours (only a takes a second to simulate it though). The code will be at the bottom of this post. The plotting was done with gnuplot, although Julia does have some good plotting functionality.

{%img /images/laundryroomdry.png Queue length versus probability of drying in room %}

As you can see, as the probability goes to zero the queue length starts to grow exponentially, as you'd expect from queuing theory/back of the envelope calculations. Increasing probability now, by the time we reach _p=0.4_, the average queue length is down to 1 - this is probably "good enough". So, under these assumptions, roughly half the people would need to be taking their laundry to their room. This seems unlikely to me, so lets revisit our model and change some things around.


## A more complex arrival process

One assumption we made above was that each person only uses one machine. This is definitely not true - you'll see people use two quite a bit. We will add a new parameter q - the probability someone uses two washing machines. I'll also make the assumption that even if someone uses two washing machines, they only use one dryer (or don't use a dryer at all). To maintain our 75% average usage of the washing machines, we need to calculate λ as a function of q. If we want 18 machines in use on average at steady state, we need λ to satisfy the formula ((1-q) + 2q)λ = (1 + q)λ = 18/0.5. We can check this is right: if q=0, we obtain λ=36 as before, and q=1 we obtain λ=18 - as you'd expect. Another intuition check: if every person uses two washing machines, and the steady state is less than capacity, then you'd expect the steady state usage of dryers to be equal to the steady state usage of washing machines. 

{%img /images/laundrytwowash.png Queue length versus probability of drying in room and probability of using two washing machines %}

The plot suggests we can get a similar queue length to _p=0.4, q=0.0_ with _p=0.2, q=0.3_, which seems more realistic.


## Conclusions and Future Work

In general this full model seems to suggest that the laundry room is barely stable at its busiest point, and that there are probably times during peak usage where someone might need to wait for a dryer (or give up and dry it in their room). Fortunately it seems that the laundry room rarely reaches that level of usage so its not a big deal. There are some factors that could make the situation 'worse': people running longer cycles, using two dryers if they use two washers, the delays between washer and dryer and with people taking dried clothing out of the dryer. Factors making it 'better' are that people might check the number of machines in use before coming down, thus the arrival rate slows as the number of machines in use grows. Because I used a simulator instead of doing it analytically, it would be easy to extend this code to include these effects. However, estimating parameters for these would require some data collection/surveying - probably not worth it!

Another thing that would be easy to change but hard to calibrate would be to model people queued for the dryers as leaving their washing in the washing machine(s). This would actually be a very easy change to the code, and would make the problem a lot more painful to analyze analytically - especially if you threw in a random time delay after the wash cycle. That is the beauty of simulation, but I'd spend so much time tinkering with parameters it didn't seem worth it. All in all, this was a good distraction from "real" work and shows the versatility of Julia.


## Appendix: the code

Here is the code for the one-person-one-washer version.

{% highlight julia %}
# Laundry Simulator
# Iain Dunning, 2013
using Distributions
using SimJulia
    
const MAX_WASHER = 24
const MAX_DRYER = 24
const STEADY_STATE = 18
const WASHER_SERVICE = 0.5
const DRYER_SERVICE = 1.0
    
function useWash(person::Process, washers::Resource, dryers::Resource, dryRoomChance::Float64)
  # Arrive at laundry
  arrivalTime = now(person)
  # Check if enough washing machines
  numWashInUse = length(washers.active_set)
  numWashToUse = 1
  if numWashInUse + 1 > MAX_WASHER
    # Insufficient washing machines
    return
  end
  # Using washing machines
  request(person, washers)
  hold(person, WASHER_SERVICE)
  release(person, washers)
    
  # Decide whether we will dry in room, or dry in dryer
  if rand() > dryRoomChance
    # Try to use dryer
    request(person, dryers)
    hold(person, DRYER_SERVICE)
    release(person, dryers)
  end
end

function genPerson(source::Process, washers::Resource, dryers::Resource, dryRoomChance::Float64)
  arrivalRate = STEADY_STATE / WASHER_SERVICE
  exp_dist = Exponential(1/arrivalRate)
  for i = 1:10000
    person = Process(simulation(source), @sprintf("Person%d",i))
    activate(person, now(source), useWash, washers, dryers, dryRoomChance)
    interArrival = rand(exp_dist)
    hold(source, interArrival)
  end
end

function runSim(dryRoomChance::Float64, seed)
  srand(seed)

  sim = Simulation(uint(50))
  washers = Resource(sim, "Washers", uint(MAX_WASHER), true)
  dryers = Resource(sim, "Dryers", uint(MAX_DRYER), true)
  source = Process(sim, "Source")
  activate(source, 0.0, genPerson, washers, dryers, dryRoomChance)
  run(sim, 1000.0)

  println("TimeAverage washers in use: $(time_average(activity_monitor(washers)))")
  println("TimeAverage dryers in use: $(time_average(activity_monitor(dryers)))")
  println("TimeAverage dryer queue length: $(time_average(wait_monitor(dryers)))")
  return time_average(wait_monitor(dryers))
end
{% endhighlight %}

