var(exists,x1,1).
var(exists,x2,2).
var(exists,x3,3).
var(exists,x4,4).
var(exists,x5,5).
var(exists,x6,6).
var(exists,x7,7).
var(exists,x8,8).
var(exists,x9,9).
var(exists,x10,10).
var(exists,x11,11).
var(exists,x12,12).
var(exists,x13,13).
var(exists,x14,14).
var(exists,x15,15).
var(exists,x16,16).
var(exists,x17,17).
var(exists,x18,18).
var(exists,x19,19).
var(exists,x20,20).
var(exists,x21,21).
var(exists,x22,22).
var(exists,x23,23).
var(exists,x24,24).
var(exists,x25,25).
var(exists,x26,26).
var(exists,x27,27).
var(exists,x28,28).
var(exists,x29,29).
var(all,y1,1).
var(all,y2,2).
var(all,y3,3).
var(all,y4,4).
var(all,y5,5).
var(all,y6,6).
var(all,y7,7).
var(all,y8,8).
var(all,y9,9).
var(all,y10,10).
var(all,y11,11).
var(all,y12,12).
var(all,y13,13).
var(all,y14,14).
var(all,y15,15).
var(all,y16,16).
var(all,y17,17).
var(all,y18,18).
var(all,y19,19).
var(all,y20,20).
var(all,y21,21).
var(all,y22,22).
var(all,y23,23).
var(all,y24,24).
var(all,y25,25).
var(all,y26,26).
var(all,y27,27).
var(all,y28,28).
var(all,y29,29).
k(443).

        {true(exists,X,C)} :- var(exists,X,C).
        :- not saturate.
        true(all,X,C) :- var(all,X,C), saturate.
        saturate :- f_sum(0,"!=",K), k(K).
        f_set(0,C,true(exists,X,C)) :- var(exists,X,C).
        f_set(0,C,true(all,X,C)) :- var(all,X,C).
    