;;; @name Unit Testing
;;; @desc Provides simple JUnit-style unit testing for Scheme.

(define *run-tests?* #t)

;;@ignore
(define (print-indented indent . str)
  (set! str (apply string-append str))
  (print (string-append (list->string (make-list indent #\space)) str)))

;;@ignore
(define (make-simple-test-case name thunk)
  (lambda (indent)
    (print-indented indent "* Running \"" name "\"... ")
    (call/cc
     (lambda (k)
       (bind-condition-handler
        `(,condition-type:error)
        (lambda (condition)
          (let ((message
                 (case (condition/type condition)
                   ((condition-type:simple-error) (access-condition condition 'message))
                   (else (condition/type condition)))))
            (print "FAILED:\n")
            (print-indented (+ indent 2) (condition/report-string condition))
            (newline)
            (k (list 0 1 message))))
        (lambda ()
          (thunk)
          (println "OK")
          (list 1 0 #f)))))))


;;@ignore
(define (make-test-suite name . test-cases)
  (lambda (indent)
    (print-indented indent "* Running \"" name "\"... \n")
    (let* ((results (map (lambda (tcase) (tcase (+ indent 4))) test-cases))
           (num-ok     (sum (map first results)))
           (num-failed (sum (map second results)))
           (num-total  (+ num-ok num-failed)))
      (print-indented (+ indent 4) "-------------------------------------\n")
      (print-indented (+ indent 4) "SUITE SUMMARY (" name ")\n")
      (print-indented (+ indent 4) (number->string num-ok) "/" (number->string num-total) " tests passed.\n")
      (if (not (eqv? num-failed 0))
          (print-indented (+ indent 4) "There were " (number->string num-failed) " failures.\n"))
      (print-indented (+ indent 4) "-------------------------------------\n")
      (newline)
      (list num-ok num-failed #f))))


;; Creates a new test suite. A test suite consists of either other suites or
;; unit tests. For example:
;; <pre>
#|
 (test-suite "Example Suite"
  (unit-test "example test"
   (assert-equal 5 (+ 2 3))
   (assert-equal-fp 0 1e-14 1e-13)
   (assert (even? 3) "Expected 3 to be even")))
|#
;; </pre>
;; You can then run the suite with c{run-suite}. The output will look like this:
;; <pre>
#|
 * Running "Example Suite"... 
    * Running "example test"... FAILED:
      Expected 3 to be even
    -------------------------------------
    SUITE SUMMARY (Example Suite)
    0/1 tests passed.
    There were 1 failures.
    -------------------------------------
|#
;; </pre>
;; @args name {unit-test/test-suite}
(define-syntax test-suite
  (syntax-rules ()
    ((test-suite name)
     (let ((suite (make-test-suite name)))
       suite))
    ((test-suite name t1 ...)
     (let ((suite (make-test-suite name t1 ...)))
       suite))))

;; Runs a test suite if tests are enabled (default), or returns without doing
;; anything if they are disabled. See c{enable-unit-tests} and c{disable-unit-tests}
;; for more information.
(define (run-suite suite)
  (if *run-tests?*
      (begin (suite 0)
             'complete)
      'skipping-test-suite))

;; Creates a new unit test. See c{test-suite} for an example.
;; @args name {expression}
(define-syntax unit-test
  (syntax-rules ()
    ((unit-test name e1 ...)
     (make-simple-test-case name (lambda () e1 ...)))))

;; Enables unit test execution. Subsequent calls to c{run-suite} will now run tests.
(define (enable-unit-tests)  (set! *run-tests?* #t))

;; Disables test execution. Subsequent calls to c{run-suite} will be a no-op.
(define (disable-unit-tests) (set! *run-tests?* #f))



; Useful assertions

;; Asserts that c{val} is true, and fails with an error if it is not.
;; @args val [optional: message]
(define (assert val #!optional message)
  (default message "Assertion failed")
  (if (not val)
      (error message)
      'ok))

;; Asserts that c{val} is <b>not</b> true, and fails with an error if it is.
(define (assert-not val)
  (assert (not val)))

;; Asserts that two values are equal, and fails with an error if they are not.
(define (assert-equal expected actual)
  (if (not (equal? actual expected))
      (error "Assertion failed. Expected: " expected " but got: " actual)
      'ok))

;; Asserts that two floating point values are equal within the given
;; precision.
;;@args expected actual [optional: precision]
(define (assert-equal-fp expected actual #!optional precision)
  (default precision 0.000000001)
  (if (< precision (abs (- actual expected)))
      (error "Assertion failed. Expected: " expected " but got: " actual)
      'ok))

