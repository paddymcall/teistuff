;; Together with the definitions in channels.scm, the following list
;; defines a full computing environment for running some core TEI
;; operations.
(define tei-required-packages
  (list
   "ant"
   "bash"
   "coreutils"
   "findutils"
   "gawk"
   "git"
   "grep"
   "less"
   "libxml2"
   "make"
   ;; We need a version < 24, it turns out, because some security
   ;; manager has been permanently disabled in v24 (see
   ;; https://docs.oracle.com/en/java/javase/24/security/security-manager-is-permanently-disabled.html)
   "openjdk@23.0.2"
   "parallel"
   "perl"
   "sed"
   "tree"))

(specifications->manifest tei-required-packages)

;; (packages->manifest tei-required-packages)


