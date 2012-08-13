echo "strategic(X1) v strategic(X2) v strategic(X3) v strategic(X4) :- &product[\"$1\"](P), &producedBy[\"$1\", P](X1,X2,X3,X4)."
echo "strategic(C) :- &company[\"$1\"](C), &controlledBy[\"$1\", C](X1,X2,X3,X4), strategic(X1), strategic(X2), strategic(X3), strategic(X4)."
