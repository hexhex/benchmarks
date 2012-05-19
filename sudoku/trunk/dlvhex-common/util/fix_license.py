#!/usr/bin/env python

# call with list of files where the license should be fixed as follows:
# * if a license is found at the top of the file
#   and it is different than fix_license.lic,
#   the license is replaced
# * if no license is found at the top of the file
#   the license is added

import sys
import re

def dbg(st):
  st = st # <-- to make the interpreter happy
  #print >>sys.stderr, "dbg: %s" % (st,)

if len(sys.argv) < 3:
  print >>sys.stderr, "usage: %s <licensefile> <files to fix>" % (sys.argv[0],)
  sys.exit(-1)

# give files to manage as arguments
licfilename = sys.argv[1]
files = sys.argv[2:]
dbg("fixing files %s with license %s" % (files,licfilename))

def fixLicenseIn(fname, lic):
  f = open(fname,"r")
  contents = f.read()
  f.close()

  license = re.search(r"""
    # multiline verbose regex
    ^ # start of file
    \s* # whitespace
    \/\* # comment start
    ([^\*]|\*(?!\/))* # anything not containing */
    \*\/\n # comment ends
    """, contents, re.VERBOSE | re.MULTILINE)
  action = 'none'
  if license != None:
    license = license.group(0)
    dbg("match:\n" + license)
    if re.search("License", license) != None:
      dbg("is a license!")
      # compare
      if lic != license:
        # replace
        action = 'replace'
    else:
      dbg("is not a license!")
      # prepend license
      action = 'prepend'
  else:
    dbg("no match")
    # prepend license
    action = 'prepend'

  if action == 'none':
    print >>sys.stdout, "license in %s is ok!" % (fname,)
  else:
    if action == 'replace':
      contents = lic + contents[len(license):]
    elif action == 'prepend':
      contents = lic + contents
    else:
      print >>sys.stderr, "error action %s" % (action,)

    dbg("new file contents:\n" + contents)
    newf = open(fname,"w")
    newf.write(contents)
    newf.close()
    print >>sys.stdout, "%sd license in %s!" % (action, fname,)

licfile = open(licfilename, 'r')
lic = licfile.read()
licfile.close()
dbg("got license\n" + lic)

for f in files:
  dbg("fixing file %s" % (f,))
  fixLicenseIn(f, lic)
