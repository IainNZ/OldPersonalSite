---
author: idunning
date: 2013-01-09 09:16:08+00:00
layout: post
title: Comparing the Weather of Different Cities
---

When people ask me about New Zealand, they often ask me about the weather. I can tell them the rough average temperatures in Auckland, but that isn't necessarily that meaningful. What would be more useful is telling them, "oh, its like X City in Y State" - it makes it more real. This came up at Thanksgiving when visiting my girlfriend's family, and I realised it'd make a good project. So here is what I did to make it a reality.

## Acquiring data

I wanted to get weather data for both US cities and NZ cities in a comparable format, and I knew from past experience that I should be able to get "Average" min, max and mean temperatures, precipitation, and sunshine at least. Data like that is provided by the [NOAA](http://www.noaa.gov/) in the USA, and [NIWA](http://www.niwa.co.nz/) in NZ. Hammering on Google for a while revealed [this page](http://ols.nndc.noaa.gov/plolstore/plsql/olstore.prodspecific?prodnum=C00095-PUB-A0001) for the USA and [this page](http://www.niwa.co.nz/education-and-training/schools/resources/climate) for NZ, so I was ready to go.

## Processing the data

The NOAA data was in a fixed-width format, so I made a quick function in Python that takes a filename, and a data-type, and stores it in a global dictionary object. Not the cleverest datastructure, but super easy to work with:

{% highlight python %}
def ReadNOAAFile(filename,field):
  f = open(filename,"r")
  firstLine = True
  for line in f:
    if firstLine:
      firstLine = False
      continue
    city = line[5:38].strip()
    if city not in data: data[city] = {}
      months = line[43:].split()
      monthFloat = [float(months[i]) for i in range(12)]
      data[city][field] = monthFloat
  f.close()
{% endhighlight %}

The NIWA data was in a CSV format, with some header lines. The numbers are in Celcius, but I converted them to Farenheit as I read them. Being lazy, I stripped out the header lines by hand and then split on commas:

{% highlight python %}
def ReadNIWAFile(filename,field):
  f = open(filename,"r")
  for line in f:
    s = line.split(",")
    city = s[0].strip()
    if city not in data: data[city] = {}
    monthFloat = [float(s[i])*9.0/5.0+32.0 for i in range(1,13)]
    mf2 = []
    offset = 6
    for i in range(offset,12): mf2.append(monthFloat[i])
    for i in range(0,offset): mf2.append(monthFloat[i])
    data[city][field] = mf2
  f.close()
{% endhighlight %}

Theres a bit more going on there than I'm saying here - an adjustment was required. Read on...

## First Attempt at Closeness Metric

With the data now in memory, it was time to code up a quick test. I just used the daily average temperatures, and calculated the sum of square errors between every city: given the temperature for each month for two cities, calculate the difference for each month. Square that difference, and the sum it up. _Things didn't go well._

The results seemed pretty strange - Mt Cook's weather was more similar to Auckland's weather than almost all US cities. This is a bit odd because Mt Cook is the tallest mountain in New Zealand, and is not a warm place at all. After checking my Farenheit conversion, I quickly wrote out the temperatures for a couple of US and NZ cities, and realized I had forgotten that **the seasons are reversed**! My solution to this was to just offset the months in the NZ data by 6 months. So January (USA) and July (NZ) are now equivalent, and so on. This is possibly not perfect, as the season offsets might not be uniform. Another option would be to check all offsets for each pair of cities, and find the offset that minimizes the error. Something to check later.

With this fixed, I ran it for Auckland, NZ and got the following preliminary results which seem encouraging. The number is the SSE when compared to Auckland. I omitted some results to make it easier to read.
	
``Auckland 0.0
Tauranga 11.0
Whangarei 13.5
Kaitaia 18.1
SANTA BARBARA, CA 29.3
Gisborne 33.4
Napier 37.9
SANTA MARIA, CA 47.9
Wanganui 54.4
SAN FRANCISCO AP, CA 66.4
New Plymouth 80.8
Hamilton 81.5
...
SAN DIEGO, CA 335.0
Christchurch 368.6
SACRAMENTO, CA 375.4
Hokitika 458.5
LONG BEACH, CA 458.6
Taupo 487.2
STOCKTON, CA 517.4
Chatham Islands 518.9
EUREKA, CA. 522.9
LOS ANGELES C.O., CA 586.0
Dunedin 644.8
SEATTLE C.O., WA 648.1
``

## Bringing it to the people

I quickly added the other data fields, and extended the error/difference calculation to include them. Changing the weightings on the different fields affected the answer, but its a pain to play with by changing code and running it again. This kind of thing is crying out for a website.

I grabbed the domain [www.tenkicompare.com](http://www.tenkicompare.com), and built a website using the following libraries:

  * Twitter's [Bootstrap](http://twitter.github.com/bootstrap/)
  * [jQuery](http://jquery.com/) and [jQuery UI](http://jqueryui.com/)
  * [Select2](http://ivaynberg.github.com/select2/) for dropdown boxes

Tenki (天気) is Japanese for weather - obviously most good domains with "weather" in them are either in use or someone is "squatting" on them. The "source code" of the website can be found at [GitHub: https://github.com/IainNZ/WeatherSite](https://github.com/IainNZ/WeatherSite)

## Extending the data

Having three types of temperature data isn't very helpful for the purposes of comparing cities, given they are all very correlated. On the other hand, they are nicely standardized. Other useful measures like "rainy-ness", "sunny-ness", and humidity are out there, but it aren't always so standardized. Here are some issues:
	
  * NIWA (New Zealand) provides monthly sunshine hours but the NOAA (USA) provides a percentage of possible sunshine hours. If you could get the number of possible sunshine hours per month, you could convert between the two. After much Googling I found the data for 1961 to 1990 [here](http://www.ncdc.noaa.gov/oa/wdc/index.php?name=climateoftheworld) but its pretty nasty to turn into a nice table. I also found [this](http://www.city-data.com/forum/weather/1583137-calculating-sunshine-hour-totals.html) which suggests that sunshine hours aren't going to really work if I'm comparing across countries.

  * Another issue is "rain days". NIWA records a day as being a "rain day" if it had more than 1 mm of precipitation, but NOAA records a day as being a "rain day" is it has more than 0.01 inches of precipitation, which is ~0.25 mm. There is no way to convert between these, but its probably close enough.

  * The NIWA sunhours data is missing some cities but has some additional ones. It doesn't have Whangarei, Milford Sound, or Manapouri, but has Te Anau. Whangarei being incomplete is annoying... but for now, I am omitting it.

  * There are errors in the NOAA data. Average temperature has a "Havre, TX" but the other files have a "Havre, MT" - as far as I can tell, there is no Havre in Texas, and if you look, they have the same station number. So there is a manual fix for that in the parsing code. Although Havre isn't included in the end, see below. Dallas-Love Field has average temperature and min temperature, but not max temperature or raindays. Further investigation revealed it was listed as "Dallad" in max temp data... In average temperature there is "AUSTIN/CITY, TX" but in raindays its "AUSTIN, TX", but same station code, so that required another tweak.

  * A large number of stations don't have sun percentage information, so for now sun percentage isn't being used. Perhaps the cities that appear in the sun percentage are all I need, but I'm not sure at this point.

The different-data issues lead to me creating three options:
	
  1. Compare against same country - all measures available.
  2. Compare against different countries - limited.
  3. Compare against all - limited.

## Not the end

I still need to add more countries, and add some visualizations of the city-vs-city comparisons - but that can wait for now, I've spent too much time fiddling with this as it is! So if you want to [compare the weather in two cities](http://www.tenkicompare.com), this is the site for you.
