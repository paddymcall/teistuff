;; Together with the definitions in channels.scm, the following list
;; defines a full computing environment for running some core TEI
;; operations.
(define tei-required-packages
  (list
   ;; Required for ‘make html-web’ to succeed:
   "ant"
   "bash-minimal"
   "coreutils"
   "git"
   "libxml2"
   "make"
   "openjdk@23.0.2" ; see note below
   "perl"
   "sed"
   "tar"))

(define tei-useful-packages
  (list
   ;; These are not necessary but useful in general:
   "findutils"
   "gawk"
   "grep"
   "less"
   "parallel"
   "tree"))

;; Note to "openjdk@23.0.2": We need a version < 24, it turns out,
;; because some security manager has been permanently disabled in v24
;; (see
;; https://docs.oracle.com/en/java/javase/24/security/security-manager-is-permanently-disabled.html).

;; TEIC’s Dockerfile has openjdk-17-jdk-headless, see
;; https://github.com/TEIC/teidev-docker/blob/7606892c69e2ac24ca5a8fc6cd041487311c0d74/Dockerfile#L6

;; Run as ‘TEISTUFF-MINIMAL-ONLY=0 guix’ to only use ‘tei-required-packages’

(specifications->manifest
 (append
  tei-required-packages
  tei-useful-packages))


