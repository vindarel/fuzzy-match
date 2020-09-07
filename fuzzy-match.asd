(in-package #:asdf-user)

(defsystem :fuzzy-match
  :author "Nyxt project, Ambrevar, Vindarel"
  :maintainer "vindarel <vindarel@mailz.org>"
  :license "MIT"
  :version "0.1"
  :homepage "https://github.com/vindarel/fuzzy-match"
  :bug-tracker "https://github.com/vindarel/fuzzy-match/issues"
  :source-control (:git "git@github.com:vindarel/fuzzy-match.git")
  :description "From a string input and a list of candidates, return the most relevant candidates first."
  :depends-on (:str
               :mk-string-metrics)
  :components ((:file "fuzzy-match"))

  :long-description
  #.(uiop:read-file-string
     (uiop:subpathname *load-pathname* "README.md"))
  :in-order-to ((test-op (test-op :str.test))))

(defsystem :fuzzy-match/tests
  :depends-on (:fuzzy-match
               :prove)
  :components ((:file "test-fuzzy"))

  ;XXX: to finish integrate.
  :in-order-to ((test-op (test-op :fuzzy-match/test))))
