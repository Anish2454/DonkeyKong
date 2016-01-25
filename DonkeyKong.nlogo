patches-own [ origColor ladderPatch? ground? pcord og]
breed [ barrels barrel ]
breed [ marios mario ]
marios-own [ cord velocity withground?]
barrels-own [ withground? direction]
globals [timestep acceleration lives score highscore]


; ------------------------------ SETUP --------------------------------

to startscreensetup;imports start screen and sets highscore to 0
  ca
  resize-world 0 700 0 700
  set-patch-size 1
  import-pcolors "insertcoin.jpg"
  set highscore 0
end

to flash; additional function for cool effects to the start screen just for fun
  set og pcolor
  set pcolor black
  wait .5
  set pcolor og
end

to insertcoin; brings all the set up functions together
  importMap
  ask patches
    [ patches_setup ]
  if any? turtles [
    ask turtles [
      die ]]
  create-marios 1
    [ mario_setup ]
  setupPhysics
  set lives 3
  set score 0
end

to setupPhysics
  set timestep 1 ;sets timedelta to 1s
  set acceleration 12 ; sets acceleration to 12 patches/sec^2
end

to importMap;imports main world map
  resize-world 0 700 0 700
  set-patch-size 1
  import-pcolors "donkeykong1.jpg"
end

to patches_setup; sets up certain patches to be true which helps in the later parts of the code such as gowithGroundMario function
  set origcolor pcolor
  if shade-of? pcolor orange or shade-of? pcolor red
    [ set ground? true
      set ladderPatch? true ] ; The platform is also a ladderpatch bc Mario needs to be able to climb it
  if shade-of? pcolor blue
    [ set ladderPatch? true
      ask patches in-radius 15 ; Takes care of patches inside the ladder as they are not blue
        [ set ladderPatch? true ]]
end

to mario_setup;sets up mario
  set xcor 155
  set ycor 90
  set size 60
  set shape "mario"
  set heading 90
  set velocity 0 ;Velocity for jumping
end

to barrelSetup ;spawns barrels
  setxy 198 530
  set size 60
  set heading 0
  set shape "barrel"
  set direction 1
end
; -----------------------------------------------------------------------


to go;main go function. This makes everything work together and starts the game
  ifelse any? Marios with [ xcor < 377 and ycor > 580] ; If mario has won, then go to the winscreen
    [ winscreen ]
    [ checkForDeathMario
      goWithGroundMario
      goWithGroundBarrel
      createBarrelsPeriodically
      checkForDeathBarrels
      score1
      highestscore
      if lives = 0 [deathscreen]]
end

to createBarrelsPeriodically; controls how often the barrels come
  every 10 [
         create-barrels 1 [
            barrelSetup ] ]
end

to gowithGroundMario; makes sure mario walks along the platform
  ask marios [
    checkForDeathMario
    if ladderPatch? != true
      [ gravity ] ]
end


to gowithGroundBarrel; makes sure barrels go along the platforms
  ask barrels
    [gravity]
  wait 0.0035
  ask barrels
    [moveBarrels 1]
end

to moveBarrels [speed]; makes the barrels move speed determines how fast they move
  if xcor >= 645 or xcor <= 55
        [set direction direction * -1
          set xcor xcor + (direction * 10) ]
  set xcor xcor + (direction * speed)
end

; If the patch directly beneath you is not a “ground patch” (a patch that is part of the red platform), 
; then repeatedly set your ycor one less until this condition is met. If however the patch above your 
; feet is a ground patch (you’ve “sunken” into the platform) then set your ycor to one more until you 
; are above the platform. This is run constantly to ensure that mario is always above the platform
to gravity 
  ifelse [ground?] of patch-at 0 -19 != true
    [if [ground?] of patch-at 0 -20 != true
       [ set ycor ycor - 1]]
    [if [ground?] of patch-at 0 20 != true
       [ set ycor ycor + 1]]
end

to checkForDeathBarrels; Controls when barrels die
  ask barrels [
    if xcor < 110 and ycor < 100
      [ die ]
  ]
end

to checkForDeathMario; kills mario when he comes in contact with a barrel
  ask marios [
    if any? barrels in-radius 15 [; if its near a certain radius he dies
      deathanimation
      set lives lives - 1 ];mario loses 1 life when he dies
  ]
end

; --------------------- JUMP FUNCTIONS (VERLET ALGORITHM) -----------------------
to jumpfinal; controls marios jumping
  ask marios [ set shape "mariojumping"
    set heading 0]
  resetPhysics ; sets velocity to 0 bc velocity is 0 at the apex of a jump
  jumpMario 4 1
  resetPhysics
  jumpMario 4 -1 ;reverse direction (fall down)
  ask marios [ set shape "mario"]
end

to resetPhysics
  ask marios [
    set velocity 0
  ]
end

to jumpMario [dist directionJump ]
  ask marios [
  repeat dist [
        checkForDeathMario ; This is here in case mario runs into a barrel while jumping
        ; Verlet Algorithm
        set ycor ycor + directionJump * (timestep * (velocity + timestep * acceleration / 2))
        set velocity velocity + timestep * acceleration
        ask barrels [
        ; This code is here so that the barrels keep moving even while mario is jumping
        ; Bc of the wait, all agents are paused while mario jumps
        ; This is a workaround
          ifelse xcor > 635 or xcor < 65
          [ moveBarrels 1]
          [ moveBarrels 14]]
        wait 0.08]
    ]

end

; -------------------------------------------------------------------------


; -------------------------- Functions For Movement --------------------------
to moveRight; allows mario to run right
  ask marios [
    set shape "runningmarioright"
    set heading 0
    set xcor xcor + 3]
end

to moveUp;allows mario to move up a ladder
  ask marios [
  ; Only move if on a ladder patch
    if ladderPatch? = true [
       set shape "climbingmario"
       set heading 0
       set ycor ycor + 1]]
end

to moveLeft; allows mario to move left
  ask marios [
    set shape "runningmarioleft"
    set heading 0
    set xcor xcor - 3 ]
end

to moveDown;allows mario to move down a ladder
  ask marios [
  ; Only move if on a ladder patch
    if ladderPatch? = true [
    set shape "climbingmario"
    set heading 0
    set ycor ycor - 1]]
end

; ----------------------------------------------------------------------------------
to marioreset; resets mario and barrels to their original posistion. This is important for when he dies
  ask marios [
    set xcor 155
    set ycor 90]
  ask barrels [
    setxy 198 530
    set direction 1
  ]
end


to deathanimation; animation for when mario dies
  ask marios [set shape "ripmario"]
  wait 0.1
  ask barrels [die]
  marioreset
end

to deathscreen; imports death screen
  ca
  import-pcolors "gameover.gif"
end

to score1; keeps track of score when mario is within a certain radius
  ask marios [
    if any? barrels in-radius 70
    [set score score + 100]
    ]
end

to winscreen;
  ifelse [hidden?] of one-of marios = true [
    import-pcolors "insertcoin.jpg" ]
    [ import-pcolors "win.png"
      ask turtles [
        set hidden? true]
      wait 3]
end

to highestscore;keeps track of highscore
  if score > highscore [set highscore score]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
921
742
-1
-1
1.0
1
10
1
1
1
0
1
1
1
0
700
0
700
0
0
1
ticks
30.0

BUTTON
22
44
107
77
NIL
insertcoin\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
144
144
208
177
NIL
moveRight
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
68
110
145
143
NIL
moveUp\n
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
2
143
69
176
NIL
moveLeft
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
69
143
144
176
NIL
moveDown
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
106
44
185
77
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
59
195
155
228
Jump
jumpfinal\n
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

BUTTON
57
10
152
43
 SETUP
startscreensetup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1
303
208
348
                            LIVES
LIVES
17
1
11

MONITOR
1
258
209
303
                           SCORE
score
17
1
11

MONITOR
-1
348
208
393
Highscore
highscore
17
1
11

@#$#@#$#@
## WHAT IS IT?

Recreation of the classic platform  game “Donkey Kong” in Netlogo. There are some things taken out from the original game such as the fire enemies and some ladders. However, this doesn’t affect the game that much. The user plays as Mario and tries to work his way to the top of them map while dodging barrels in order to save Princess Peach

## HOW IT WORKS

There are two main breeds in the game: Mario and Barrels

Rules for Mario:
If you are next to princess peach, then you winIf the patch directly beneath you is not a “ground patch” (a patch that is part of the red platform), then repeatedly set your ycor one less until this condition is met. If however the patch above your feet is a ground patch (you’ve “sunken” into the platform) then set your ycor to one more until you are above the platform. This is run constantly to ensure that mario is always above the platform
If you die with lives remaining, then just go back to the start. If no more lives are left, then end the game
If there is a barrel within a specified radius, then die
If you are next to princess peach, then you have won
You can only move up or down if you are currently on a ladder patch

Rules for Barrels:
Same as #1 for Mario
Keep setting your xcor to 1 more or 1 less, depending on your direction attribute
If your xcor is out of the bounds of the platform, then roll in the other direction
If you are at the fire, then die

Rules for Patches:
If you are a patch on the platform (pcolor = red) then set your ground? attribute to true
If you are a patch on a ladder (pcolor = blue) then set your ladderpatch? attribute to true and also ask any patches in your radius to do the same (this is to make the black patches inside the ladders also a ladderpatch)

Barrels are spawned every 10 seconds using the “every” primitive
Mario is moved using the up, down, left, right, and jump functions
The jump function uses the Verlet Algorithm to create the allusion of gravity which is described here:

The acceleration and change in time are declared as global variables as they do not change
The velocity variable is a marios-own variable
We update mario’s ycor as he accelerates up, then we accelerate him down back to his original spot



## HOW TO USE IT
If it’s your first time playing, press setup to load up the start screen. Once in the start screen, press the insert coin button to start. When the game loads use the A to move left, S to move down ladders, D to move right, and W to move up ladders. Press J to jump. The monitor keeps track off score, lives and highscore. Score resets every time you start a new game whether it's dying, winning, etc. The highscore only resets if you die or press setup.
## THINGS TO NOTICE

(suggested things for the user to notice while running the model)


## EXTENDING THE MODEL

You can add more enemies by breeding new turtles to make the game more difficult. You can also increase the rate at which barrels come out.

## CREDITS AND REFERENCES

Verlet Algorithm : https://en.wikipedia.org/wiki/Verlet_integration
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

barrel
true
0
Rectangle -955883 true false 105 150 180 165
Rectangle -955883 true false 75 165 210 180
Rectangle -955883 true false 60 180 225 255
Rectangle -955883 true false 75 255 210 270
Rectangle -955883 true false 105 270 180 285
Rectangle -6459832 true false 105 285 180 300
Rectangle -6459832 true false 75 270 105 285
Rectangle -6459832 true false 60 255 75 270
Rectangle -6459832 true false 60 75 45 135
Rectangle -6459832 true false 45 180 60 255
Rectangle -6459832 true false 60 165 75 180
Rectangle -6459832 true false 75 150 105 165
Rectangle -6459832 true false 105 135 180 150
Rectangle -6459832 true false 180 150 210 165
Rectangle -6459832 true false 210 165 225 180
Rectangle -6459832 true false 225 180 240 255
Rectangle -6459832 true false 210 135 210 150
Rectangle -6459832 true false 210 255 225 270
Rectangle -6459832 true false 180 270 210 285
Rectangle -13345367 true false 75 225 105 255
Rectangle -13345367 true false 135 180 150 195
Rectangle -13345367 true false 150 75 150 90
Rectangle -13345367 true false 150 195 165 210
Rectangle -13345367 true false 165 210 180 225
Rectangle -13345367 true false 180 225 195 240
Rectangle -13345367 true false 135 195 150 210
Rectangle -13345367 true false 150 210 165 225
Rectangle -13345367 true false 165 225 180 240
Rectangle -13345367 true false 120 180 135 195

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

climbingmario
true
0
Rectangle -13345367 true false 90 240 150 255
Rectangle -2674135 true false 90 225 90 240
Rectangle -13345367 true false 90 225 135 240
Rectangle -2674135 true false 135 225 135 240
Rectangle -2674135 true false 135 225 150 240
Rectangle -2674135 true false 75 210 135 225
Rectangle -2674135 true false 75 165 210 210
Rectangle -13345367 true false 150 210 210 225
Rectangle -2674135 true false 75 225 90 240
Rectangle -2674135 true false 60 165 75 225
Rectangle -2674135 true false 210 165 225 195
Rectangle -2674135 true false 60 150 135 165
Rectangle -2674135 true false 60 135 120 150
Rectangle -2674135 true false 150 150 210 165
Rectangle -2674135 true false 165 135 195 150
Rectangle -2674135 true false 90 105 105 135
Rectangle -2674135 true false 180 105 180 135
Rectangle -2674135 true false 165 105 180 135
Rectangle -13345367 true false 45 120 90 150
Rectangle -13345367 true false 60 105 90 120
Rectangle -13345367 true false 135 150 150 165
Rectangle -13345367 true false 105 105 165 150
Rectangle -6459832 true false 90 90 180 105
Rectangle -13345367 true false 210 135 225 165
Rectangle -13345367 true false 195 135 210 150
Rectangle -13345367 true false 90 75 180 90
Rectangle -2674135 true false 105 60 180 75
Rectangle -2674135 true false 90 45 195 60
Rectangle -6459832 true false 180 30 225 45
Rectangle -6459832 true false 195 45 225 75
Rectangle -6459832 true false 180 75 195 90
Rectangle -13345367 true false 180 75 225 135
Rectangle -6459832 true false 90 105 180 120
Rectangle -13345367 true false 240 120 225 90

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

mario
false
0
Rectangle -2674135 true false 105 15 150 30
Rectangle -2674135 true false 75 75 105 75
Rectangle -2674135 true false 90 30 195 45
Rectangle -13345367 true false 75 45 135 60
Rectangle -13345367 true false 105 60 120 90
Rectangle -13345367 true false 120 75 135 90
Rectangle -6459832 true false 75 60 105 90
Rectangle -6459832 true false 105 90 90 120
Rectangle -6459832 true false 90 90 150 120
Rectangle -6459832 true false 150 105 195 120
Rectangle -13345367 true false 150 90 210 105
Rectangle -13345367 true false 165 90 180 105
Rectangle -13345367 true false 165 75 180 90
Rectangle -13345367 true false 150 60 165 75
Rectangle -6459832 true false 150 45 150 90
Rectangle -6459832 true false 135 45 165 60
Rectangle -6459832 true false 120 60 150 75
Rectangle -6459832 true false 135 75 165 90
Rectangle -6459832 true false 165 60 210 75
Rectangle -6459832 true false 180 75 225 90
Rectangle -13345367 true false 75 120 165 135
Rectangle -13345367 true false 60 135 180 150
Rectangle -2674135 true false 135 135 135 150
Rectangle -2674135 true false 120 135 150 180
Rectangle -2674135 true false 105 150 120 165
Rectangle -2674135 true false 150 165 165 165
Rectangle -2674135 true false 180 165 195 210
Rectangle -1 true false 150 150 150 165
Rectangle -1 true false 135 150 150 165
Rectangle -13345367 true false 60 60 75 90
Rectangle -13345367 true false 60 90 75 105
Rectangle -13345367 true false 45 90 90 105
Rectangle -13345367 true false 60 150 75 180
Rectangle -13345367 true false 75 150 105 165
Rectangle -13345367 true false 90 165 90 180
Rectangle -13345367 true false 75 165 120 180
Rectangle -13345367 true false 75 180 90 195
Rectangle -6459832 true false 90 180 120 210
Rectangle -2674135 true false 120 180 135 195
Rectangle -6459832 true false 135 180 150 195
Rectangle -6459832 true false 120 180 135 195
Rectangle -2674135 true false 135 180 150 195
Rectangle -2674135 true false 60 180 75 225
Rectangle -2674135 true false 75 195 90 225
Rectangle -2674135 true false 90 210 120 225
Rectangle -2674135 true false 120 195 150 210
Rectangle -2674135 true false 135 210 180 225
Rectangle -13345367 true false 60 225 105 255
Rectangle -13345367 true false 105 240 120 255
Rectangle -13345367 true false 135 225 180 255
Rectangle -13345367 true false 180 240 195 255
Rectangle -2674135 true false 150 150 180 210

mariojumping
true
0
Rectangle -2674135 true false 90 15 210 30
Rectangle -2674135 true false 120 0 180 15
Rectangle -6459832 true false 120 45 150 45
Rectangle -6459832 true false 120 30 120 45
Rectangle -6459832 true false 120 30 150 45
Rectangle -13345367 true false 150 30 210 45
Rectangle -6459832 true false 75 45 120 60
Rectangle -6459832 true false 60 60 105 75
Rectangle -13345367 true false 120 45 135 60
Rectangle -13345367 true false 105 60 120 75
Rectangle -13345367 true false 75 75 135 90
Rectangle -6459832 true false 135 45 165 60
Rectangle -6459832 true false 120 60 150 75
Rectangle -6459832 true false 135 75 195 90
Rectangle -13345367 true false 150 60 180 75
Rectangle -13345367 true false 165 45 180 60
Rectangle -6459832 true false 90 90 195 105
Rectangle -13345367 true false 195 75 240 90
Rectangle -13345367 true false 210 45 210 75
Rectangle -13345367 true false 210 45 225 75
Rectangle -6459832 true false 180 45 210 75
Rectangle -2674135 true false 150 105 180 135
Rectangle -13345367 true false 120 105 150 120
Rectangle -13345367 true false 90 120 150 135
Rectangle -13345367 true false 90 105 90 135
Rectangle -13345367 true false 60 105 75 135
Rectangle -6459832 true false 30 90 60 120
Rectangle -6459832 true false 45 105 60 120
Rectangle -2674135 true false 135 135 150 135
Rectangle -2674135 true false 135 120 150 195
Rectangle -1184463 true false 150 150 165 165
Rectangle -13345367 true false 75 120 90 135
Rectangle -2674135 true false 150 135 180 150
Rectangle -2674135 true false 105 135 135 150
Rectangle -2674135 true false 105 150 150 165
Rectangle -2674135 true false 75 165 135 195
Rectangle -2674135 true false 165 150 180 195
Rectangle -2674135 true false 150 165 165 195
Rectangle -2674135 true false 180 150 210 210
Rectangle -2674135 true false 210 180 225 210
Rectangle -2674135 true false 165 210 180 210
Rectangle -2674135 true false 165 195 180 210
Rectangle -2674135 true false 180 210 210 225
Rectangle -13345367 true false 45 165 75 195
Rectangle -13345367 true false 45 150 60 165
Rectangle -13345367 true false 210 165 270 180
Rectangle -13345367 true false 255 180 270 195
Rectangle -13345367 true false 270 180 285 195
Rectangle -13345367 true false 225 150 255 165
Rectangle -13345367 true false 225 180 240 195
Rectangle -13345367 true false 180 105 210 150
Rectangle -13345367 true false 210 105 225 135
Rectangle -13345367 true false 225 120 240 120
Rectangle -13345367 true false 225 105 240 120
Rectangle -6459832 true false 240 90 255 135
Rectangle -6459832 true false 240 90 270 120
Rectangle -6459832 true false 270 105 285 120

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

ripmario
true
0
Rectangle -6459832 true false 30 195 90 240
Rectangle -13345367 true false 90 180 150 240
Rectangle -2674135 true false 150 225 165 240
Rectangle -13345367 true false 165 225 240 240
Rectangle -2674135 true false 240 150 255 240
Rectangle -2674135 true false 255 150 270 225
Rectangle -2674135 true false 255 120 270 135
Rectangle -13345367 true false 120 165 180 180
Rectangle -2674135 true false 90 165 135 180
Rectangle -6459832 true false 30 195 60 195
Rectangle -6459832 true false 60 180 90 195
Rectangle -6459832 true false 60 165 90 180
Rectangle -6459832 true false 75 150 90 165
Rectangle -13345367 true false 150 180 165 225
Rectangle -13345367 true false 165 180 180 210
Rectangle -6459832 true false 165 210 195 225
Rectangle -6459832 true false 180 195 225 210
Rectangle -13345367 true false 195 210 210 225
Rectangle -6459832 true false 210 210 225 225
Rectangle -13345367 true false 225 180 240 225
Rectangle -13345367 true false 210 180 225 195
Rectangle -6459832 true false 225 210 240 225
Rectangle -13345367 true false 225 180 240 195
Rectangle -2674135 true false 165 150 180 165
Rectangle -2674135 true false 150 135 165 150
Rectangle -2674135 true false 60 150 75 165
Rectangle -2674135 true false 45 105 150 150
Rectangle -2674135 true false 90 150 165 165
Rectangle -6459832 true false 195 150 240 180
Rectangle -2674135 true false 240 135 255 150
Rectangle -13345367 true false 180 180 210 195
Rectangle -13345367 true false 195 105 210 180
Rectangle -6459832 true false 180 180 210 195
Rectangle -6459832 true false 180 135 195 180
Rectangle -13345367 true false 165 135 180 150

runningmarioleft
true
0
Rectangle -13345367 true false 90 255 150 270
Rectangle -13345367 true false 105 240 150 255
Rectangle -2674135 true false 90 225 135 240
Rectangle -2674135 true false 165 255 225 240
Rectangle -2674135 true false 165 225 225 240
Rectangle -13345367 true false 225 240 225 255
Rectangle -13345367 true false 240 195 255 255
Rectangle -13345367 true false 225 195 240 240
Rectangle -2674135 true false 90 195 225 225
Rectangle -2674135 true false 75 195 90 225
Rectangle -2674135 true false 180 180 210 195
Rectangle -6459832 true false 210 180 210 195
Rectangle -6459832 true false 210 180 240 195
Rectangle -6459832 true false 210 165 225 180
Rectangle -13345367 true false 105 180 180 195
Rectangle -6459832 true false 75 165 105 195
Rectangle -6459832 true false 60 165 75 180
Rectangle -13345367 true false 105 165 195 180
Rectangle -13345367 true false 120 150 210 180
Rectangle -2674135 true false 105 150 120 165
Rectangle -6459832 true false 75 150 90 165
Rectangle -6459832 true false 60 135 180 150
Rectangle -6459832 true false 120 120 180 135
Rectangle -13345367 true false 45 120 120 135
Rectangle -13345367 true false 90 105 105 120
Rectangle -13345367 true false 105 90 120 105
Rectangle -6459832 true false 120 90 180 120
Rectangle -6459832 true false 105 105 120 120
Rectangle -6459832 true false 165 90 195 120
Rectangle -13345367 true false 180 120 225 135
Rectangle -13345367 true false 195 90 210 120
Rectangle -13345367 true false 150 75 165 120
Rectangle -13345367 true false 135 105 150 120
Rectangle -6459832 true false 135 75 150 90
Rectangle -6459832 true false 30 105 90 120
Rectangle -6459832 true false 45 90 105 105
Rectangle -6459832 true false 105 75 135 90
Rectangle -13345367 true false 135 75 210 90
Rectangle -2674135 true false 75 60 210 75
Rectangle -2674135 true false 120 45 195 60

runningmarioright
true
0
Rectangle -13345367 true false 150 255 210 270
Rectangle -13345367 true false 150 240 195 255
Rectangle -2674135 true false 165 225 210 240
Rectangle -2674135 true false 75 255 135 240
Rectangle -2674135 true false 75 225 135 240
Rectangle -13345367 true false 75 240 75 255
Rectangle -13345367 true false 45 195 60 255
Rectangle -13345367 true false 60 195 75 240
Rectangle -2674135 true false 75 195 210 225
Rectangle -2674135 true false 210 195 225 225
Rectangle -2674135 true false 90 180 120 195
Rectangle -6459832 true false 90 180 90 195
Rectangle -6459832 true false 60 180 90 195
Rectangle -6459832 true false 75 165 90 180
Rectangle -13345367 true false 120 180 195 195
Rectangle -6459832 true false 195 165 225 195
Rectangle -6459832 true false 225 165 240 180
Rectangle -13345367 true false 105 165 195 180
Rectangle -13345367 true false 90 150 180 180
Rectangle -2674135 true false 180 150 195 165
Rectangle -6459832 true false 210 150 225 165
Rectangle -6459832 true false 120 135 240 150
Rectangle -6459832 true false 120 120 180 135
Rectangle -13345367 true false 180 120 255 135
Rectangle -13345367 true false 195 105 210 120
Rectangle -13345367 true false 180 90 195 105
Rectangle -6459832 true false 120 90 180 120
Rectangle -6459832 true false 180 105 195 120
Rectangle -6459832 true false 105 90 135 120
Rectangle -13345367 true false 75 120 120 135
Rectangle -13345367 true false 90 90 105 120
Rectangle -13345367 true false 135 75 150 120
Rectangle -13345367 true false 150 105 165 120
Rectangle -6459832 true false 150 75 165 90
Rectangle -6459832 true false 210 105 270 120
Rectangle -6459832 true false 195 90 255 105
Rectangle -6459832 true false 165 75 195 90
Rectangle -13345367 true false 90 75 165 90
Rectangle -2674135 true false 90 60 225 75
Rectangle -2674135 true false 105 45 180 60

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
