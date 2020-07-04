


# Find Online Meetups on Any Topic

With local Data Science meetups cancelled, I sought to find where in the world has upcoming online meetups on the topic - and find I did! 

Some have some spectacular speaker line-ups, including some of the world's best in natural language processing, image classification systems, reinforcement learning in robotics, forecasting and a lot on more niche topics! - much more variety than I would ever have access to locally.

Many of these meetups are intended for a smallish (<300) audiences, so some are fairly unpolished, which, IMHO, adds to the enjoyment of pilfering through them for hidden teasures, and the kind of frank discussion not possible in wider forums. As PG once [alluded to](https://www.youtube.com/watch?v=3mAd5LJFdb4#t=25m43s), after audiences become sufficiently large, speakers will cease speaking frankly:

<br>

> "If we ever broadcast them ... speakers would clam up"
> — Paul Graham, [EconTalk with Russ Roberts](https://www.econtalk.org/graham-on-start-ups-innovation-and-creativity/)

<br>

So will this renaissance of candid, intellectual discussion persist? Probably not, so check them out while they last! 



# Installation

First, install R, and RStudio IDE (both free). Installation time: ~ 2 minutes for both. 



# Try for yourself!

Clone the repo and open `meetups.R` with RStudio and set the `topic` variable (line 5) to something you enjoy - here are [some ideas](https://www.meetup.com/topics/) - copy the topic from the url: whatever comes after 'meetup.com/topics/'.

Last, select all the code in the script and run it with command + enter (or run it line by line if you prefer). In a few minutes, you'll have a curated `data.frame` of meetups on your topic of choice, their time (in your timezone), descriptions and, importantly, the video conference links! 



# Example

Clone the repo and read in `r_meetups.RDS` with `meetups <- readRDS("r_meetups.RDS")`. 

View and explore the file you read with `View(meetups)`

![First 23 R meetups](https://github.com/stevecondylios/meetups-not-near-you/blob/master/meetups.png?raw=true)









