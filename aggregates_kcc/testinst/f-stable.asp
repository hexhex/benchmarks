p(1..2000).
s(X) :- f_sum(X,">=",0), p(X).
f_set(X,1,s(X)) :- p(X).
f_set(X,-1,s(X)) :- p(X).
