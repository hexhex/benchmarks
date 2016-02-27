#maxint=40.
p(X) :- #int(X).

aux(X) :- #sum{ 1:s(X); 1:sf(X) } >= 1, p(X).
	aux(X) :- s(X), p(X).
	aux(X) :- sf(X), p(X).
s(X) :- aux(X).

sf(X) :- not s(X), p(X).
sf(X) :- aux(X), p(X).
q(X) v sf(X) :- not auxp(X), p(X).
ausp(X) :- not aux(X), p(X).
