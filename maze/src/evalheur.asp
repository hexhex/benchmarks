% put all rules in one component!

% find smallest component idx in inf/1
before(X,Y) :- component(X), component(Y), X < Y.
hasBefore(Y) :- before(X,Y).
inf(Y) :- component(Y), not hasBefore(Y).

unit(U) :- inf(U).
use(U,C) :- unit(U), component(C).

% vim:syntax=prolog:
