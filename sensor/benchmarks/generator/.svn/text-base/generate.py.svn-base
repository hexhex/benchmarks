
import math
import random
import os

# generate with two robots starting in corners on one side and object initial location random on opposite side
def generateocro(maxx,maxy,num_objects,planlen,instidx):
  filename = "../instances/patrol_%02dx%02d_r2ocro_o%02d_l%02d_%02d.asp" % (maxx,maxy,num_objects,planlen,instidx)
  if os.path.isfile(filename):
    print "skipping %s" % filename
    return
  print "writing %s" % (filename,) 
  f = open(filename,'w+')
  maxint = max(max(maxx,maxy),planlen)
  f.write("#maxint=%d.\n" % maxint)
  f.write("laststep(%d).\n" % planlen)
  f.write("maxx(%d).\n" % maxx)
  f.write("maxy(%d).\n" % maxy)
  f.write("sensorrange(\"2.5\").\n")
  f.write("robot(r1).\n")
  f.write("robotX(r1,1,0). robotY(r1,1,0).\n")
  f.write("robot(r2).\n")
  f.write("robotX(r2,1,0). robotY(r2,%d,0).\n" % maxy)
  for idx in range(1,num_objects+1):
    f.write("object(o%d).\n" % idx)
    x = maxx #random.randint(1,maxx)
    y = random.randint(1,maxy)
    f.write("objectX(o%d,%d,0). objectY(o%d,%d,0).\n" % (idx, x, idx, y))
  f.close()

# generate with two robots starting in opposite corners and no random object initial location
def generateoc(maxx,maxy,num_objects,planlen):
  filename = "../instances/patrol_%02dx%02d_r2oc_o%02d_l%02d.asp" % (maxx,maxy,num_objects,planlen)
  if os.path.isfile(filename):
    print "skipping %s" % filename
    return
  print "writing %s" % (filename,) 
  f = open(filename,'w+')
  maxint = max(max(maxx,maxy),planlen)
  f.write("#maxint=%d.\n" % maxint)
  f.write("laststep(%d).\n" % planlen)
  f.write("maxx(%d).\n" % maxx)
  f.write("maxy(%d).\n" % maxy)
  f.write("sensorrange(\"2.5\").\n")
  f.write("robot(r1).\n")
  f.write("robotX(r1,1,0). robotY(r1,1,0).\n")
  f.write("robot(r2).\n")
  f.write("robotX(r2,%d,0). robotY(r2,%d,0).\n" % (maxx,maxy))
  for idx in range(1,num_objects+1):
    f.write("object(o%d).\n" % idx)
  f.close()

# generate with two robots starting in opposite quarters of the map and no random object initial location
def generaters(maxx,maxy,num_objects,planlen,instidx):
  filename = "../instances/patrol_%02dx%02d_r2rs_o%02d_l%02d_%02d.asp" % (maxx,maxy,num_objects,planlen,instidx)
  if os.path.isfile(filename):
    print "skipping %s" % filename
    return
  print "writing %s" % (filename,) 
  f = open(filename,'w+')
  maxint = max(max(maxx,maxy),planlen)
  f.write("#maxint=%d.\n" % maxint)
  f.write("laststep(%d).\n" % planlen)
  f.write("maxx(%d).\n" % maxx)
  f.write("maxy(%d).\n" % maxy)
  f.write("sensorrange(\"2.5\").\n")
  f.write("robot(r1).\n")
  f.write("robotX(r1,%d,0). robotY(r1,%d,0).\n" % (random.randint(1,maxx/2), random.randint(1,maxy/2)))
  f.write("robot(r2).\n")
  f.write("robotX(r2,%d,0). robotY(r2,%d,0).\n" % (random.randint(maxx/2,maxx), random.randint(maxy/2,maxy)))
  for idx in range(1,num_objects+1):
    f.write("object(o%d).\n" % idx)
  f.close()

num_objects = 1

# too difficult for explicit, intended to use sensorrange 2.5
if False:
	for maxcoo in range(4,8+1):
	  for planlen in range(3,maxcoo+2):
	    for instidx in range(1,11):
	      #planlen = maxcoo-2+planlenadd
	      # with random object start position
	      generateocro(maxcoo,4,num_objects,planlen,instidx)

# good for comparing explicit with others
if False:
	for maxcoo in range(4,10+1):
	  for planlenadd in range(0,2):
	    planlen = maxcoo/2-1+planlenadd
	    # without random object start position
	    generateoc(maxcoo,4,num_objects,planlen)

# for comparing all methods, including multiple instances with random robot starts
if True:
	for maxcoo in range(3,9+1):
	    for instidx in range(1,11):
	      planlen = max(1,maxcoo/2-1)
	      # without random object start position
	      generaters(maxcoo,4,num_objects,planlen,instidx)
