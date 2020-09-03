# Fuzzy-match

commit 1: extracted from the Nyxt browser. Original authors: Ambrevar, Vindarel.

~~~lisp
CL-USER> (fuzzy-match "hl" '("foo" "bar" "hello" "hey!"))
("hello" "hey!" "foo" "bar")
~~~

~~~lisp
CL-USER> (fuzzy-match "zp" '("foo" "zepellin" "bar: zep"))
("zepellin" "bar: zep" "foo")
~~~

The parameters are hand-picked for the results to feel natural. A
candidate that starts with the input substring should appear
first. For example, we use the Damerau-Levenshtein distance thanks to
the `MK-STRING-METRICS` library under the hood, but we don't obey to
its result.

To give any objects as candidates, and not only strings, make them
implement `object-display`, that returns a string representation.


# Licence

MIT
