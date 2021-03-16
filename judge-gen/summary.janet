(import ./path :prefix "")
(import ./display :prefix "")
(import ./utils :prefix "")

(defn summary/report
  [results]
  (when (empty? results)
    (eprint "No test results")
    (break true))
  (var total-tests 0)
  (var total-passed 0)
  (def failures @{})
  # analyze results
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
  # report any failures
  (var i 0)
  (each fpath (sort (keys failures))
    (def failed-tests (get failures fpath))
    (each fail failed-tests
      (def {:test-value test-value
            :expected-value expected-value
            :name test-name
            :passed test-passed
            :test-form test-form} fail)
      (++ i)
      (print)
      (prin "--(")
      (display/print-color i :cyan)
      (print ")--")
      (print)
      (display/print-color "source file:" :yellow)
      (print)
      (display/print-color (string (utils/no-ext fpath) ".janet") :red)
      (print)
      (print)
      #
      (display/print-color "failed:" :yellow)
      (print)
      (display/print-color test-name :red)
      (print)
      #
      (print)
      (display/print-color "form" :yellow)
      (display/print-form test-form)
      #
      (print)
      (display/print-color "expected" :yellow)
      (display/print-form expected-value)
      #
      (print)
      (display/print-color "actual" :yellow)
      (display/print-form test-value :blue)))
  (when (zero? (length failures))
    (print)
    (print "No tests failed."))
  # summarize totals
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
    '@[{:expected-value true
        :passed true
        :name "line-6"
        :test-form (validate/valid-code? "true")
        :type :is
        :expected-form true
        :test-value true}
       {:expected-value false
        :passed true
        :name "line-9"
        :test-form (validate/valid-code? "(")
        :type :is
        :expected-form false
        :test-value false}
       {:expected-value true
        :passed true
        :name "line-12"
        :test-form (validate/valid-code? "()")
        :type :is
        :expected-form true
        :test-value true}
       {:expected-value false
        :passed true
        :name "line-15"
        :test-form (validate/valid-code? "(]")
        :type :is
        :expected-form false
        :test-value false}])

  (let [buf @""]
    (with-dyns [:out buf]
      (summary/report @{"validate.jimage" results}))
    (string/has-prefix? "\nNo tests failed." buf))
  # => true

  )
