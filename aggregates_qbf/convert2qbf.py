#!/usr/bin/env python3

GPL = """
Instantiate ASP programs in order to compute G-stable models by means of ordinary ASP solvers.
Copyright (C) 2015  Mario Alviano (mario@alviano.net)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

VERSION = "0.2"

import argparse

args = None

def parseArguments():
    global VERSION
    global GPL
    global args
    parser = argparse.ArgumentParser(description=GPL.split("\n")[1], epilog="Copyright (C) 2015  Mario Alviano (mario@alviano.net)")
    parser.add_argument('-v', '--version', action='version', version='%(prog)s ' + VERSION, help='print version number')
    parser.add_argument('--mode', metavar='<type>', type=str, help='specify how to encode internal variables: disjunction (default), sum, agg')
    parser.add_argument('filename', type=str, help="input file")
    args = parser.parse_args()
    
    if not args.mode: args.mode = "disjunction"
    assert(args.mode in ["disjunction", "sum", "agg"])
    
def main():
    parseArguments()

    a = set()
    e = set()
    body = []

    with open(args.filename) as f:
        for line in f:
            line = line.strip()
            if line[0] == 'c':
                pass
            elif line[0] == 'p':
                pass
            elif line[0] == 'a':
                assert(len(a) == 0)
                assert(len(e) == 0)
                for v in line[1:].split():
                    if v == '0':
                        continue
                    assert(not v in a)
                    a.add(int(v))

                if args.mode == "agg":
                        print("{%s}." % ("; ".join(["a(%d)" % (x,) for x in a])))
                else:
                        print("{%s}." % (", ".join(["a(%d)" % (x,) for x in a])))
            elif line[0] == 'e':
                assert(len(a) > 0)
                assert(len(e) == 0)
                for v in line[1:].split():
                    if v == '0':
                        continue
                    assert(not v in a)
                    assert(not v in e)
                    e.add(int(v))

                for v in e:
                    if args.mode == "disjunction":
                        print("e(%d) | e_(%s)." % (v,v))
                        print("e(%d) :- sat." % (v,))
                        print("e_(%d) :- sat." % (v,))
                    elif args.mode == "sum":
                        print("e(%d) :- f_sum(%d, \">=\", 0)." % (v,v), end=" ")
                        print("f_set(%d,1,sat)." % (v,), end=" ")
                        print("f_set(%d,-1,e_(%d))." % (v,v))

                        print("e_(%d) :- f_sum(-%d, \">=\", 0)." % (v,v), end=" ")
                        print("f_set(-%d,1,sat)." % (v,), end=" ")
                        print("f_set(-%d,-1,e(%d))." % (v,v))
                    elif args.mode == "agg":
                        print("e(%d) :- #sum{ 1 : sat; m : e_(%d) } >= 0." % (v,v), end=" ")
                        print("e_(%d) :- #sum{ 1 : sat; m : e(%d) } >= 0." % (v,v), end=" ")

                print(":- not sat.")
            else:
                assert(len(a) > 0)
                assert(len(e) > 0)
                for l in line.split():
                    if l == '0':
                        if len(body) > 0:
                            print("sat :- %s." % (', '.join(body),))
                        else:
                            print("sat.")
                        body = []
                        continue
                    
                    l = int(l)
                    v = l if l > 0 else -l    
                    if v in a:
                        body.append("%sa(%d)" % ("" if v != l else "not ", v));
                    else:
                        assert(v in e)
                        body.append("e%s(%d)" % ("" if v != l else "_", v));

if __name__ == "__main__":
    main()
