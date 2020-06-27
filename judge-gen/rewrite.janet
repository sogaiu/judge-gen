(import ./pegs :refresh true)

(defn rewrite-tagged
  [tagged-item last-form]
  (let [[tag value] tagged-item]
    (match [tag value]
      [:returns value]
      (string "(_verify/is " last-form " " value ")\n\n")
      [:throws _]
      (string "(_verify/is-error " last-form ")\n\n")
      nil)))

(comment

 (rewrite-tagged [:returns true] "(= 1 1)")
 # => "(_verify/is (= 1 1) true)\n\n"

 (rewrite-tagged [:throws "yuck"] "(error \"yuck\")")
 # => "(_verify/is-error (error \"yuck\"))\n\n"

 )

# XXX: tried putting the following into a file, but kept having
#      difficulty getting it to work out
(def verify-as-string ``
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
``)

(defn rewrite-block-with-verify
  [blk]
  (var rewritten-forms @[])
  # parse the comment block and rewrite some parts
  (each cmt-or-frm (peg/match pegs/inner-forms blk)
    (if (empty? rewritten-forms)
      (array/push rewritten-forms cmt-or-frm)
      (let [last-form (array/pop rewritten-forms)]
        (if (= (type cmt-or-frm) :tuple)
          # tuple requires special handling
          (let [rewritten
                (rewrite-tagged cmt-or-frm last-form)]
            (assert rewritten (string "match failed for: " cmt-or-frm))
            (array/push rewritten-forms rewritten))
          # long-bytes require special handling
          (let [maybe-long-bytes (peg/match pegs/long-bytes cmt-or-frm)]
            (if-not maybe-long-bytes
              (do
                (array/push rewritten-forms last-form)
                (array/push rewritten-forms cmt-or-frm))
              # long-bytes are handled like tuples
              (let [rewritten
                    (rewrite-tagged (first maybe-long-bytes) last-form)]
                (assert rewritten (string "match failed for long-string"))
                (array/push rewritten-forms rewritten))))))))
  rewritten-forms)

(defn rewrite-with-verify
  [cmt-blks]
  (var rewritten-forms @[])
  # parse comment blocks and rewrite some parts
  (each blk cmt-blks
    (array/concat rewritten-forms (rewrite-block-with-verify blk)))
  # assemble pieces
  (var forms
       (array/concat @[]
                     @["\n\n"
                       "(_verify/start-tests)\n\n"]
                     rewritten-forms
                     @["\n(_verify/end-tests)\n"
                       "\n(_verify/summarize)\n"]))
  (string verify-as-string
          (string/join forms "")))

(comment

  (def sample `
(comment

  (= 1 1)
  # => true

  )`)

 (rewrite-with-verify [sample])

  (def sample-comment-form `
(comment

  (def a 1)

  # this is just a comment

  (def b 2)

  (= 1 (- b a))
  # => true

  (error "ouch")
  # !

)
`)

 # XXX: expected value is large...store in external file?
 (rewrite-with-verify [sample-comment-form])

 )