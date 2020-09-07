(defpackage :fuzzy-match.tests
  (:use :common-lisp
        :parachute)
  (:import-from :fuzzy-match
                :fuzzy-match))

(in-package :fuzzy-match.tests)

;; (plan nil)


(defparameter *suggestions* '(
                              "SET-URL-NEW-BUFFER"
                              "HELP"
                              "NEW-BUFFER"
                              "SWITCH-BUFFER"
                              "BOOKMARK-DELETE"
                              "BUFFER"
                              "SWITCH-BUFFER"
                              "DELETE-BUFFER"
                              "DELETE-WINDOW"
                              "HELP-MODE"
                              "DELETE-CURRENT-BUFFER"
                              "SWITCH-BUFFER-PREVIOUS"
                              )
  "Existing commands.")

(define-test fuzzy-match
  (is #'equal (first (fuzzy-match "hel"
                          '("help-mode" "help" "foo-help" "help-foo-bar")))
      "help")
  (is #'equal (first (fuzzy-match "hel"
                          *suggestions*))
      "HELP"
      "match 'help' with real suggestions list")
  (is #'equal (first (fuzzy-match "swit buf"
                          '("about" "switch-buffer-" "switch-buffer"
                            "delete-buffer")))
      "switch-buffer"
      "match 'swit buf' (small list)")
  (is #'equal (first (fuzzy-match "swit buf"
                          *suggestions*))
      "SWITCH-BUFFER"
      "match 'swit buf' with real suggestions list")

  (is #'equal (first (fuzzy-match "buf swit"
                          '("about" "switch-buffer" "delete-buffer")))
      "switch-buffer"
      "reverse match 'buf swit' (small list)")
  ;; TODO: Fix reverse fuzzy matching.
  ;; (is #'equal (first (fuzzy-match "buf swit"
  ;;                               *suggestions*))
  ;;     "SWITCH-BUFFER"
  ;;     "reverse match 'buf swit' with real suggestions list")

  (is #'equal (first (fuzzy-match "de"
                          '("some-mode" "delete-foo")))
      "delete-foo"
      "suggestions beginning with the first word appear first")

  (is #'equal (first (fuzzy-match "foobar"
                          '("foo-dash-bar" "foo-bar")))
      "foo-bar"
      "search without a space. All characters count (small list).")
  (is #'equal (first (fuzzy-match "sbf"
                          *suggestions*))
      "SWITCH-BUFFER"
      "search without a space. All characters count, real list.")
  (is #'equal (first (fuzzy-match "FOO"
                          '("foo-dash-bar" "FOO-BAR")))
      "FOO-BAR"
      "input is uppercase (small list).")
  (is #'equal (first (fuzzy-match "[" '("test1"
                                "http://[1:0:0:2::3:0.]/"
                                "test2")))
      "http://[1:0:0:2::3:0.]/"
      "match regex meta-characters"))

(finalize)
