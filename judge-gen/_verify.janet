# influenced by janet's tools/helper.janet

(var _verify/start-time 0)
(var _verify/end-time 0)
(var _verify/test-results @[])

(defmacro _verify/is
  [t-form e-form &opt name]
  (default name
    (string "test-" (inc (length _verify/test-results))))
  (with-syms [$ts $tr
              $es $er]
    ~(do
       (def [,$ts ,$tr] (protect ,t-form))
       (def [,$es ,$er] (protect ,e-form))
       (array/push _verify/test-results
                   {:type :is
                    :passed (if (and ,$ts ,$es)
                                (deep= ,$tr ,$er)
                                nil)
                    :expected-form ',e-form
                    :expected-value ,$er
                    :test-form ',t-form
                    :test-value ,$tr
                    :name ,name})
       ,name)))

(defmacro _verify/is-error
  [form &opt name]
  (default name
    (string "test-" (inc (length _verify/test-results))))
  (with-syms [$s $r]
    ~(do
       (def [,$s ,$r] (protect ,form))
       (array/push _verify/test-results
                   {:type :is-error
                    :passed (if ,$s false true)
                    :form-value ,$r
                    :test-form ',form
                    :name ,name})
       ,name)))

(defn _verify/start-tests
  []
  (set _verify/start-time (os/clock))
  (set _verify/test-results @[]))

(defn _verify/end-tests
  []
  (set _verify/end-time (os/clock)))

(defn _verify/summarize
  []
  (var passed 0)
  (each result _verify/test-results
    (def {:form-value form-value
          :name test-name
          :passed test-passed
          :test-form test-form} result)
    (if test-passed
      (++ passed)
      (do
        (print "failed: " test-name)
        (printf "  form: %j" test-form)
        (printf " value: %j" form-value)
        (print "--------"))))
  (printf "\n\nTests finished in %.3f seconds"
          (- _verify/end-time _verify/start-time))
  (print passed " of " (length _verify/test-results) " tests passed.\n"))
