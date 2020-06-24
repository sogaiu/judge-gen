(import ./pegs :prefix "")

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

(def verify-as-string
  (slurp "./_verify.janet"))

(defn rewrite-with-verify
  [cmt-blk]
  (var rewritten-forms @[])
  # parse the comment block and rewrite some parts
  (each cmt-or-frm (peg/match inner-forms cmt-blk)
    (if (= 0 (length rewritten-forms))
      (array/push rewritten-forms cmt-or-frm)
      (let [last-form (array/pop rewritten-forms)]
        (if (= (type cmt-or-frm) :tuple)
          # tuple requires special handling
          (let [rewritten
                (rewrite-tagged cmt-or-frm last-form)]
            (assert rewritten (string "match failed for: " cmt-or-frm))
            (array/push rewritten-forms rewritten))
          # long-bytes require special handling
          (let [maybe-long-bytes (peg/match long-bytes cmt-or-frm)]
            (if-not maybe-long-bytes
              (do
                (array/push rewritten-forms last-form)
                (array/push rewritten-forms cmt-or-frm))
              # long-bytes are handled like tuples
              (let [rewritten
                    (rewrite-tagged (first maybe-long-bytes) last-form)]
                (assert rewritten (string "match failed for long-string"))
                (array/push rewritten-forms rewritten))))))))
  # assemble pieces
  (var forms
       (array/concat @[]
                     @["\n\n"
                       "(_verify/start-tests)\n\n"]
                     rewritten-forms
                     @["\n(_verify/end-tests)\n"]))
  (string verify-as-string
          (string/join forms "")))

(comment

  (def sample `
(comment

  (= 1 1)
  # => true

  )`)

 (rewrite-with-verify sample)

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
 (rewrite-with-verify sample-comment-form)

 )
