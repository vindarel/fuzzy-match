;;; Extracted from Nyxt.
;;; Initial authors: Ambrevar, Vindarel.

(defpackage :fuzzy-match
  (:use :cl)
  (:export :fuzzy-match
           :*treshold*))
(in-package :fuzzy-match)

(defvar *treshold* 0.4
  ;; devel: Learn good value.
  "The score threshold below which candidates are discarded.")

(defun substring-norm (substrings string &key (substring-length 2))
  "Return the norm of SUBSTRINGS with regard to STRING.
The norm is closer to 1 if
- substrings start near the beginning of STRING;
- substrings length are closer to the length of STRING.

Only substrings of SUBSTRING-LENGTH characters or more are considered."
  ;; TODO: Remove duplicates in SUBSTRINGS?  Repeats could mean we insist more on it.
  (let ((position-factor 1.0)
        (length-factor 1.0)
        (long-substrings (remove-if (lambda (s) (> substring-length (length s)))
                                    substrings)))
    (if long-substrings
        (/ (apply #'+
                  (mapcar (lambda (s)
                            (let ((position (search s string)))
                              (if (not position)
                                  0
                                  (/ (+
                                      (* position-factor
                                         (/ 1
                                            ;; We use the sqrt to slow down the
                                            ;; decrease rate, we want the a
                                            ;; position of 10-15 still be >0.1.
                                            (sqrt (1+ position))))
                                      (* length-factor
                                         (/ (min (length s) (length string))
                                            (length string))))
                                     (+ position-factor length-factor)))))
                          long-substrings))
           (length long-substrings))
        0)))

(defun to-unicode (input)
  "Convert INPUT to (simple-array character) type."
  (if (typep input 'base-string)
      (coerce input `(simple-array character (,(length input))))
      input))

;; IDEA: Make score functions customizable, e.g. for global history.

(defun score-suggestion (input suggestion)
  "Return a SUGGESTION's score for INPUT.
A higher score means the suggestion comes first."
  ;; The Jaccard metric seems to provide much better results than, say,
  ;; Damerau-Levensthein but it's much slower.
  ;; TODO: Check out fzf for a possibly good scoring algorithm.
  (+ (* 1.0 (mk-string-metrics:norm-damerau-levenshtein suggestion input))
     (* 1.0 (substring-norm (str:split " " input) suggestion))))

(defun sort-candidates (input pairs)
  "Sort PAIRS, the pair closest to INPUT in the levenshtein distance comes first.
PAIRS is a list of (search-string real-item)."
  ;; WARNING: mk-string-metrics works on low-level arrays and might not get
  ;; the text encoding right.  We need to make sure the candidates and the
  ;; input are of the same encoding.
  (setf input (to-unicode input))
  (dolist (suggestion-pair pairs)
    (setf (first suggestion-pair) (to-unicode (first suggestion-pair))))
  (flet ((score-suggestion (pair)
           (cons (score-suggestion input (first pair)) pair))
         (sort-suggestion (triplet1 triplet2)
           (> (first triplet1)
              (first triplet2)))
         (triplet-to-pair (triplet)
           (rest triplet)))
    (mapcar #'triplet-to-pair
            (sort (mapcar #'score-suggestion pairs) #'sort-suggestion))))

(defun find-exactly-matching-substrings (input candidates &key (substring-length 2))
  "Return the list of input substrings that match at least one suggestion.
The substrings must be SUBSTRING-LENGTH characters long or more."
  (let ((input-strings (delete-if (lambda (s) (< (length s) substring-length))
                                  (str:split " " input :omit-nulls t))))
    (when input-strings
      (delete-duplicates
       (loop for suggestion in candidates
             append (remove-if
                     (lambda (i)
                       (not (search i suggestion)))
                     input-strings))
       :test #'string=))))

(defun keep-exact-matches-in-candidates (input pairs)
  "Destructively filter out non-exact matches from candidates.
If any input substring matches exactly (but not necessarily a whole word),
then all candidates that are not exactly matched by at least one substring are removed."
  (let* ((exactly-matching-substrings (find-exactly-matching-substrings
                                       input
                                       (mapcar #'first pairs))))
    (if exactly-matching-substrings
        (setf pairs
              (delete-if (lambda (suggestion-pair)
                           (not (loop for i in exactly-matching-substrings
                                      always (search i (first suggestion-pair)))))
                         pairs))
        pairs)))

(declaim (inline filter-by-treshold))
(defun filter-by-treshold (pairs &key (treshold *treshold*))
  "Keep pairs (string, number) only if number is >= than TRESHOLD.
  If TRESHOLD isn't a number, return all pairs."
  (cond
    ((numberp treshold)
     (loop :for pair :in pairs
           :if (>= (second pair) treshold)
             :collect pair))
    (t
     pairs)))

(defun fuzzy-match (input candidates &key (key #'identity) (treshold *treshold*))
  "From the user input and a list of candidates, return a filtered list of
candidates that have all the input words in them, and sort this list to have the
'most relevant' first.

KEY is an accessor function.

TRESHOLD, a float between 0 and 1, is the minimal score for a matching result. If a match scores below it, it is discarded.

The match is case-sensitive if INPUT contains at least one uppercase character."
  ;; To sort by the display value, we store all the candidates in a
  ;; (display-value real-value) list or pairs.
  (let ((pairs (mapcar (lambda (elt)
                         (list (funcall key elt)
                               elt))
                       candidates)))

    ;; slight cleanup.
    (setf input (str:replace-all " " " " input))  ;; unbreakable whitespace

    (if (str:emptyp input)
        ;; empty input, same candidates.
        candidates
        (let* ((pairs (if (str:downcasep input)
                          ;; Prefer to work with all downcased strings.
                          (mapcar (lambda (elt)
                                    (list (string-downcase (first elt))
                                          (second elt)))
                                  pairs)
                          pairs))
               (pairs (keep-exact-matches-in-candidates input pairs))
               ;; sort
               (pairs (sort-candidates input pairs))
               ;; score
               (score-pairs (mapcar (lambda (c)
                                      (list (first c)
                                            (score-suggestion (to-unicode input) (first c))))
                                    pairs))
               ;; filter low quality results
               (score-pairs (filter-by-treshold score-pairs :treshold treshold)))
          (mapcar #'first score-pairs)
          ))))
