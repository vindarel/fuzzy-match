# Fuzzy-match

Fuzzy match candidates from an input string.

On Quicklisp and [Ultralisp](https://ultralisp.org/).

~~~lisp
CL-USER> (fuzzy-match "hl" '("foo" "bar" "hello" "hey!"))
("hello" "hey!" "foo" "bar")
~~~

~~~lisp
CL-USER> (fuzzy-match "zp" '("foo" "zepellin" "bar: zep"))
("zepellin" "bar: zep" "foo")
~~~

To give a list of non-string candidates, use the `:key` argument, a
function that will be `funcall`-ed on each candidate to get its string
representation.

```lisp
  (defstruct candidate
    (string)
    (stuff))

  (defparameter *objects*
    (list (make-candidate :string "project-switch")
          (make-candidate :string "bananas")))

  (fuzzy-match "proj ws" *objects* :key #'candidate-string)
```

The parameters are hand-picked for the results to feel natural. A
candidate that starts with the input substring should appear
first. For example, we use the Damerau-Levenshtein distance thanks to
the `MK-STRING-METRICS` library under the hood, but we don't obey to
its result.

# CHANGELOG

- 0.2 <2025-08-08>:
  - use a `:key` parameter to work with compound objects instead of `:suggestions-display`.
  - use a score threshold
  - regression: with no adaptative threshold so far, a short input string might not get results. E.g. searching for "bf" might not return "buffer-switch".
    - or in `(fuzzy-match "[" '("http://[1:0:0:2::3:0.]/" "foo") :threshold 0.01)` we need a low threshold.
- 0.1: initial


# Nyxt origin

This code was extracted from the Nyxt browser. Original authors: Ambrevar, Vindarel.

## Other projects using this

We know of:

- [cl-autocorrect](https://github.com/moneylobster/cl-autocorrect)
- Lem editor (soon©)

# Licence

MIT
