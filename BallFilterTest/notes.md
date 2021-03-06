# Notes on testing

# Can our trajectory matching algorithm handle lots of objects dropping in and out?

# Drop the frame if there's a certain number of "balls" in it?
Look at 09. Lots of "balls" detected even though there's no balls in the image. With a person moving around, this is what's going to happen.

Maybe if there are >8 balls in image, drop? 
The only concern here is: what do you do if the batter is swinging and this happens? We need to collect that data.

Will also drop the frame if there are < 2 balls in it?


## Can check the "fullness" of the square
If you count the number of pixels in an object, and then divide that number by the area of the bounding box, then you can use a eliminate long strandy objects 

## Measure squareness?
If short/long < 0.5, then not our ball

## Timing of trajectory
How long does the trajectory matching take for 2 objects? 4? 8? 16? If we reduce the number of objects enough will it be fast enough to do the rest?

## Larger pixel requirement
If we can determine a higher number of pixels that are always seen, we should be able to reduce the number of objects further.
This seems unlikely, given that some balls are too small right now (see 27). But we would need to test more. 

## Minimum pixel requirement
Can we eliminate objects that are larger than a particular size in either direction, because for the bottom of the strike zone (or near to it) we'll never see a ball that big?

## Objects on edge
If we eliminate objects on the edge, we will reduce some objects, but it's unclear how many/how useful it would be.

## Object clustering
Can we detect object clustering, and eliminate objects that are within some radius of each other? Will only ever be two balls. If there are >3 objects in some radius, then eliminate all objects from consideration in a radius around the combined center of mass.i
This might cause isues if the ball is near the catcher's mitt, a la test 07.
Also wouldn't do much in the case of 28, but that's probably fine, because if you only have ~2 objects in there then you're (hopefully) it won't add too much to the calculations.

centroids = calculateCentroids(largeObjects)
for i in centroids:
	


# Notes on results of testing
Balls from pitcher: 25, 28, 30, 32, 33, 36-41, 51-52, 54, 56-58, 60-64, 66, 68-72, 74-79, 80, 82-83, 85-89, 91-92     
Balls from catcher: 26-27, 29, 31, 34-35, 53, 55, 59-65, 67, 73, 81, 84, 90, 93
Misc no Balls: 9-23, 42-50

This document contains notes on what each folder is.
lines that say "good" indicate ones I think we could/should use.
lines that say "wah" indicate some confusing behavior.
lines that say "comment" indicate something that will impact future videos.

0 --> 2-23: good blank
1 --> 26-47: good blank
2 --> 50-71: top right bat
3 --> 74-95: blank
4 --> 98-119: catcher mitt
5 --> 146-167: catcher moving 
6 --> 194-215: catcher throwing, ~ 10 frames ball
7 --> 218-239: catching, ~ 3 frames ball
8 --> 314-335: action by catcher
9 --> 657-680: walking near plate
10 --> 683-704: swinging bat low 
11 --> 758-780: swinging bat mid, some action by catcher
12 --> 808-830: catcher, batter moving 
13 --> 908-929: big swing 
14 --> 933-955: big swing
15 --> 983-1004: batter moving 
16 --> 1033-1055: wiggling bat by plate
17 --> 1083-1105: swinging bat low, in reverse direction
18 --> 1108-1130: checking swing 
19 --> 1183-1205: swinging bat, in reverse direction (high low high)
20 --> 1233-1255: wiggling bat up high 
21 --> 1308-1330: wiggling bat up high
22 --> 1458-1480: batter moving to leave or something similar
23 --> 1858-1880: batter walking away 
24 --> 2064-2080: catcher throwing, ball in all frames
25 --> 2083-2105: ball from pitcher in last 3 frames
26 --> 2150-2155: ball from catcher in ~ 4 frames
27 --> 2208-2228: ball from catcher in ~ 15 frames, high 
28 --> 2233-2255: ball from pitcher in ~ 10 frames
29 --> 2283-2305: ball from catcher in most frames
30 --> 2333-2355: ball from pitcher in the first 3 frames
31 --> 2433-2455: ball from catcher in most frames
32 --> 2512-2530: ball from pitcher in most frames
33 --> 2591-2605: ball from pitcher in most frames
34 --> 2873-2881: ball from catcher in most frames
35 --> 2908-2931: slow ball from catcher in most frames
36 --> 2962-2980: ball from pitcher in most frames
37 --> 3190-3205: ball from pticher in most frames
38 --> 3256-3280: ball from pitcher in ~10 frames
39 --> 3308-3313: ball from pitcher in a few frames
40 --> 3461-3480: high ball from pitcher
41 --> 3508-3530: ball from pitcher in most frames
42 --> 3683-3705: people walking around
43 --> 3908-3930: batter walking 
44 --> 3933-3955: catcher walking over plate
45 --> 3958-3980: people walking around plate
46 --> 3983-4005: batter walking 
47 --> 4035-4055: wiping plate
48 --> 4083-4105: ump approaching to wipe
49 --> 4208-4230: wiping plate
50 --> 4233-4255: wiping plate
51 --> 4458-4480: ball from pitcher in the last few frames; batter moving around
52 --> 4558-4579: ball from pitcher in first few frames; batter/catcher visible
53 --> 4658-4680: ball from catcher in most frames; catcher/batter visible
54 --> 4708-4730: ball from pitcher in most frames; catcher/batter visible
55 --> 4808-4830: ball from catcher in most frames; batter visible
56 --> 4833-4855: ball from pitcher in most frames; catcher/batter visible
57 --> 5033-5054: ball from pitcher in most frames; catcher/batter visible 
58 --> 5058-5080: good. ball from pitcher (faster) in most frames; catcher/batter visible
59 --> 5083-5105: ball from catcher in most frames.
60 --> 5458-5480: ball from pitcher in most frames.
61 --> 5666-5680: ball from pitcher in most frames.
62 --> 5683-5705: ball from pitcher in most frames
63 --> 5758-5780: ball from pitcher in most frames
64 --> 5834-5855: ball from pitcher in most frames
65 --> 5883-5905: ball from catcher in most frames
66 --> 6056-6080: fast ball from pitcher in most frames
67 --> 6233-6255: ball from catcher in most frames
68 --> 6258-6280: ball from pitcher in most frames
69 --> 6334-6355: ball from pitcher in most frames
70 --> 6733-6755: ball from pitcher in most frames in lower image
71 --> 6808-6830: ball from pitcher in most frames in lower image
72 --> 6933-6955: small ball from pitcher in most fram
73 --> 7108-7130: high ball from catcher in most frames
74 --> 7308-7330: high ball from pitcher in most frames
75 --> 7383-7405: ball from pitcher in most frames
76 --> 7433-7455: ball from pitcher in most frames
77 --> 7568-7581: ball from pitcher in most frames
78 --> 7783-7805: small ball from pitcher in most frames
79 --> 7833-7855: ball from pitcher in most frames

rotate camera. now catcher is on the left.

80 --> 9483-9505: ball from pitcher in a couple of the early frames
81 --> 9558-9580: ball from catcher in most frames
82 --> 9633-9655: ball from pitcher in most frames. large ball.
83 --> 9683-9705: ball from pitcher in most frames
84 --> 10083-10105: ball from catcher in most frames.
85 --> 10483-10505: ball from pitcher in most frames.
86 --> 10533-10555: ball from pitcher in most frames.
87 --> 10608-10630: ball from pitcher in most frames.
88 --> 10658-10680: small ball from pitcher in most frames.
89 --> 10708-10730: small ball from pitcher in most frames.
90 --> 10933-10955: SMALL ball from catcher in most frames.
91 --> 10983-11005: ball from pitcher in most frames
92 --> 11033-11055: small ball from pitcher in most frames.
93 --> 11058-11080: small ball from catcher in most frames.

