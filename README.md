This is a [LÖVE](love2d.org) program that lets you fiddle with values which are fed into a shader to make some interesting/colourful pictures.

# What the Values do

* Red/Green/Blue Index : These control which function that produces the given colour value of each pixel, based upon the pixel's x and y positions. These functions include
  * binary xor : x XOR y
  * binary and : x AND y
  * binary or : x OR y
  * product of differences : (x - y) * (y - x)
  * sum of quotients :  (x / y) + (y / x)
  * product : x * y
  * sum : x + y

* translation : these values translate the pixel values before feeding them into the functions selected by Red/Green/Blue Index

* Red/Green/Blue Trans : These control whether the given colour is affected by the translation values.
  * 1: both x and y are affected
  * 2: x is affected, y isn't
  * 3: y is affected, x isn't
  * 4: neither are affected
 
* scale : this number is multiplied by the output of the function selected by Red/Green/Blue Index, just before normalization.
