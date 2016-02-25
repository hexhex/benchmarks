1 {assign(X,C) : colour(C)} 1 :- node(X).

:- not saturate.
in(X) | out(X) :- node(X).
in(X) :- node(X), saturate.
out(X) :- node(X), saturate.

saturate :- in(X), in(Y), X != Y, not link(X,Y).

saturate :- out(X), f_sum(X,">=",0).
f_set(X,N,saturate) :- node(X), N = #count{node(Y)}.
f_set(X,-1,in(Y)) :- node(X), node(Y), X != Y.
f_set(X,1,in(Y)) :- node(X), link(X,Y).

saturate :- in(X), in(Y), assign(X,CX), assign(Y,CY), CX != CY.

link(X,Y) :- link(Y,X).
