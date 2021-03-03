(import ./path :prefix "")
(import ./display :prefix "")

(defn summary/report
  [results]
  (when (empty? results)
    (eprint "No test results")
    (break true))
  (var total-tests 0)
  (var total-passed 0)
  (def failures @{})
  (eachp [fpath test-results] results
    (def name (path/basename fpath))
    (when test-results
      (var passed 0)
      (var num-tests (length test-results))
      (var fails @[])
      (each test-result test-results
        (++ total-tests)
        (def {:passed test-passed} test-result)
        (if test-passed
          (do
            (++ passed)
            (++ total-passed))
          (array/push fails test-result)))
      (when (not (empty? fails))
        (put failures fpath fails))))
  (when (pos? (length failures))
    (print))
  (eachp [fpath failed-tests] failures
    (print fpath)
    (each fail failed-tests
      (def {:test-value test-value
            :expected-value expected-value
            :name test-name
            :passed test-passed
            :test-form test-form} fail)
      (print)
      (display/print-color (string "  failed: " test-name) :red)
      (print)
      (printf "    form: %M" test-form)
      (prin "expected")
      # XXX: this could use some work...
      (if (< 30 (length (describe expected-value)))
        (print ":")
        (prin ": "))
      (printf "%m" expected-value)
      (prin "  actual")
      # XXX: this could use some work...
      (if (< 30 (length (describe test-value)))
        (print ":")
        (prin ": "))
      (display/print-color (string/format "%m" test-value) :blue)
      (print)))
  (when (zero? (length failures))
    (print)
    (print "No tests failed."))
  (print)
  (display/print-dashes)
  (when (= 0 total-tests)
    (print "No tests found, so no judgements made.")
    (break true))
  (if (not= total-passed total-tests)
    (display/print-color total-passed :red)
    (display/print-color total-passed :green))
  (prin " of ")
  (display/print-color total-tests :green)
  (print " passed")
  (display/print-dashes)
  (= total-passed total-tests))

(comment

  (summary/report @{})
  # => true

  (def results
    '@[{:expected-value "judge-gen"
        :passed true
        :name "line-20"
        :test-form (base-no-ext "test/judge-gen.janet")
        :type :is
        :expected-form "judge-gen"
        :test-value "judge-gen"}])

  (let [buf @""]
    (with-dyns [:out buf]
      (summary/report @{"1-main.jimage" results}))
    (string/has-prefix? "\nNo tests failed." buf))
  # => true

  )

