(import ./pegs :fresh true)

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
# XXX: an advantage of it being in a separate file is that testing
#      the contained code might be easier...
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
                   {:expected-form ',e-form
                    :expected-value ,$er
                    :name ,name
                    :passed (if (and ,$ts ,$es)
                                (deep= ,$tr ,$er)
                                nil)
                    :test-form ',t-form
                    :test-value ,$tr
                    :type :is})
       ,name)))

(defmacro _verify/is-error
  [form &opt name]
  (default name
    (string "test-" (inc (length _verify/test-results))))
  (with-syms [$s $r]
    ~(do
       (def [,$s ,$r] (protect ,form))
       (array/push _verify/test-results
                   {:name ,name
                    :passed (if ,$s false true)
                    :test-form ',form
                    :test-value ,$r
                    :type :is-error})
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
    (def {:name test-name
          :passed test-passed
          :test-form test-form
          :test-value test-value} result)
    (if test-passed
      (++ passed)
      (do
        (print "failed: " test-name)
        (printf "  form: %j" test-form)
        (printf " value: %j" test-value)
        (print "--------"))))
  (printf "\n\nTests finished in %.3f seconds"
          (- _verify/end-time _verify/start-time))
  (print passed " of " (length _verify/test-results) " tests passed.\n"))

(defn _verify/dump-results
  []
  (printf "%j" _verify/test-results))

``)

(defn has-tests
  [forms]
  # XXX: atm, if one of forms is [:returns val] or [:throws val]
  #      there is potentially at least one test.  the only other
  #      type of thing in forms should be a string
  (not (all |(not (tuple? $))
            forms)))

(comment

  (has-tests @["(+ 1 1)\n  " [:returns "2"]])
  # => true

  (has-tests @["(error \"2\")\n  " [:throws "2"]])
  # => true

  (has-tests @["(comment \"2\")\n  "])
  # => false

  )

(defn rewrite-block-with-verify
  [blk]
  (var rewritten-forms @[])
  # parse the comment block and rewrite some parts
  (set pegs/in-comment 0)
  (let [parsed (peg/match pegs/inner-forms blk)]
    (when (has-tests parsed)
      (each cmt-or-frm parsed
        (when (not= cmt-or-frm "")
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
                      (assert rewritten (string "match failed on long-string"))
                      (array/push rewritten-forms rewritten))))))))
        (set pegs/in-comment 0)))
    rewritten-forms))

(comment

  (def comment-str `
(comment

  (+ 1 1)
  # => 2

)
`)

  (rewrite-block-with-verify comment-str)
  # => @["(_verify/is (+ 1 1)\n   2)\n\n"]

  (do
    (set pegs/in-comment 0)
    (peg/match pegs/inner-forms comment-str))
  # => @["(+ 1 1)\n  " [:returns "2"]]

  (def comment-with-no-test-str `
(comment

  (+ 1 1)

)
`)

  (rewrite-block-with-verify comment-with-no-test-str)
  # => @[]

  (def comment-in-comment-str `
(comment

  (comment

     (+ 1 1)
     # => 2

   )
)
`)

  (do
    (set pegs/in-comment 0)
    (peg/match pegs/inner-forms comment-in-comment-str))
  # => @["" "(comment\n\n     (+ 1 1)\n     # => 2\n\n   )\n"]

  (rewrite-block-with-verify comment-in-comment-str)
  # => @[]

  )

(defn rewrite-with-verify
  [cmt-blks &opt format]
  (default format "jdn")
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
                     (cond
                       (= format "jdn")
                       "\n(_verify/dump-results)\n"
                       #
                       (= format "text")
                       "\n(_verify/summarize)\n"
                       # XXX: is this appropriate?
                       (do
                         (eprint "warning: unrecognized format: " format)
                         "\n(_verify/dump-results)\n"))]))
  (string verify-as-string
          (string/join forms "")))

(comment

  (def sample `
(comment

  (= 1 1)
  # => true

  )`)

  (comment

    (rewrite-with-verify [sample] "text")

    )

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

  (comment
    # XXX: expected value is large...store in external file?
    (rewrite-with-verify [sample-comment-form] "jdn")

    )

 (def comment-in-comment `
(comment

  (comment

    (+ 1 1)
    # => 2

  )

)
`)

 (comment
   # XXX: expected value is large...store in external file?
   (rewrite-with-verify [comment-in-comment] "jdn")

   )

 )
