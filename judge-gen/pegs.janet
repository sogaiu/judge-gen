(import ./grammar :prefix "")
(import ./validate :prefix "")

# XXX: any way to avoid this?
(var- pegs/in-comment 0)

(def- pegs/jg-comments
  (->
    # jg* from grammar are structs, need something mutable
    (table ;(kvs grammar/jg))
    (put :main '(choice (capture :value)
                        :comment))
    #
    (put :comment-block ~(sequence
                           "("
                           (any :ws)
                           (drop (cmt (capture "comment")
                                      ,|(do
                                          (++ pegs/in-comment)
                                          $)))
                           :root
                           (drop (cmt (capture ")")
                                      ,|(do
                                          (-- pegs/in-comment)
                                          $)))))
    (put :ptuple ~(choice :comment-block
                          (sequence "("
                                    :root
                                    (choice ")" (error "")))))
    # classify certain comments
    (put :comment
         ~(sequence
            (any :ws)
            (choice
              (cmt (sequence
                     (line)
                     "#" (any :ws) "=>"
                     (capture (sequence
                                (any (if-not (choice "\n" -1) 1))
                                (any "\n"))))
                   ,|(if (zero? pegs/in-comment)
                       (let [ev-form (string/trim $1)
                             line $0]
                         (assert (validate/valid-bytes? ev-form)
                                 {:ev-form ev-form
                                  :line line})
                         # record expected value form and line
                         [:returns ev-form line])
                       # XXX: is this right?
                       ""))
              (cmt (capture (sequence
                              "#"
                              (any (if-not (+ "\n" -1) 1))
                              (any "\n")))
                   ,|(identity $))
              (any :ws))))
    # tried using a table with a peg but had a problem, so use a struct
    table/to-struct))

(def pegs/inner-forms
  ~{:main :inner-forms
    #
    :inner-forms (sequence
                   "("
                   (any :ws)
                   "comment"
                   (any :ws)
                   (any (choice :ws ,pegs/jg-comments))
                   (any :ws)
                   ")")
    #
    :ws (set " \0\f\n\r\t\v")
    })

(comment

  (deep=
    #
    (peg/match
      pegs/inner-forms
      ``
      (comment
        (- 1 1)
        # => 0
      )
      ``)
    #
    @["(- 1 1)\n  "
      [:returns "0" 3]])
  # => true

  (deep=
    #
    (peg/match
      pegs/inner-forms
      ``
      (comment

        (def a 1)

        # this is just a comment

        (def b 2)

        (= 1 (- b a))
        # => true

      )
      ``)
    #
    @["(def a 1)\n\n  "
      "# this is just a comment\n\n"
      "(def b 2)\n\n  "
      "(= 1 (- b a))\n  "
      [:returns "true" 10]])
  # => true

  # demo of having failure test output give nicer results
  (def result
    @["(def a 1)\n\n  "
      "# this is just a comment\n\n"
      "(def b 2)\n\n  "
      "(= 1 (- b a))\n  "
      [:returns "true" 10]])

  (peg/match
    pegs/inner-forms
    ``
    (comment

      (def a 1)

      # this is just a comment

      (def b 2)

      (= 1 (- b a))
      # => true

    )
    ``)
    # => result

  )

(defn pegs/parse-comment-block
  [cmt-blk-str]
  # mutating outer pegs/in-comment
  (set pegs/in-comment 0)
  (peg/match pegs/inner-forms cmt-blk-str))

(comment

  (def comment-str
    ``
    (comment

      (+ 1 1)
      # => 2

    )
    ``)

  (pegs/parse-comment-block comment-str)
  # => @["(+ 1 1)\n  " [:returns "2" 4]]

  (def comment-with-no-test-str
    ``
    (comment

      (+ 1 1)

    )
    ``)

  (pegs/parse-comment-block comment-with-no-test-str)
  # => @["(+ 1 1)\n\n"]

  (def comment-in-comment-str
    ``
    (comment

      (comment

         (+ 1 1)
         # => 2

       )
    )
    ``)

  (pegs/parse-comment-block comment-in-comment-str)
  # => @["" "(comment\n\n     (+ 1 1)\n     # => 2\n\n   )\n"]

)

# recognize next top-level form, returning a map
# modify a copy of jg
(def pegs/jg-pos
  (->
    # jg* from grammar are structs, need something mutable
    (table ;(kvs grammar/jg))
    # also record location and type information, instead of just recognizing
    (put :main ~(choice (cmt (sequence
                               (line)
                               (capture :value)
                               (position))
                             ,|(do
                                 (def [s-line value end] $&)
                                 {:end end
                                  :s-line s-line
                                  :type :value
                                  :value value}))
                        (cmt (sequence
                               (line)
                               (capture :comment)
                               (position))
                             ,|(do
                                 (def [s-line value end] $&)
                                 {:end end
                                  :s-line s-line
                                  :type :comment
                                  :value value}))))
    # tried using a table with a peg but had a problem, so use a struct
    table/to-struct))

(comment

  (def sample-source
    (string "# \"my test\"\n"
            "(+ 1 1)\n"
            "# => 2\n"))

  (deep=
    #
    (peg/match pegs/jg-pos sample-source 0)
    #
    @[{:type :comment
       :value "# \"my test\"\n"
       :s-line 1
       :end 12}]) # => true

  (deep=
    #
    (peg/match pegs/jg-pos sample-source 12)
    #
    @[{:type :value
       :value "(+ 1 1)\n"
       :s-line 2
       :end 20}]) # => true

  (string/slice sample-source 12 20)
  # => "(+ 1 1)\n"

  (deep=
    #
    (peg/match pegs/jg-pos sample-source 20)
    #
    @[{:type :comment
       :value "# => 2\n"
       :s-line 3
       :end 27}]) # => true

  )

(comment

  (def top-level-comments-sample
    ``
    (def a 1)

    (comment

      (+ 1 1)

      # hi there

      (comment :a )

    )

    (def x 0)

    (comment

      (= a (+ x 1))

    )
    ``)

  (deep=
    #
    (peg/match pegs/jg-pos top-level-comments-sample)
    #
    @[{:type :value
       :value "(def a 1)\n\n"
       :s-line 1
       :end 11}]
    ) # => true

  (deep=
    #
    (peg/match pegs/jg-pos top-level-comments-sample 11)
    #
    @[{:type :value
       :value
       "(comment\n\n  (+ 1 1)\n\n  # hi there\n\n  (comment :a )\n\n)\n\n"
       :s-line 3
       :end 66}]
    ) # => true

  (deep=
    #
    (peg/match pegs/jg-pos top-level-comments-sample 66)
    #
    @[{:type :value
       :value "(def x 0)\n\n"
       :s-line 13
       :end 77}]
    ) # => true

  (deep=
    #
    (peg/match pegs/jg-pos top-level-comments-sample 77)
    #
    @[{:type :value
       :value "(comment\n\n  (= a (+ x 1))\n\n)"
       :s-line 15
       :end 105}]
    ) # => true

  )

(def pegs/comment-block-maybe
  ~{:main (sequence
            (any :ws)
            "("
            (any :ws)
            "comment"
            (any :ws))
    #
    :ws (set " \0\f\n\r\t\v")})

(comment

  (peg/match
    pegs/comment-block-maybe
    ``
    (comment

      (= a (+ x 1))

    )
    ``)
  # => @[]

  (peg/match
    pegs/comment-block-maybe
    ``

    (comment

      :a
    )
    ``)
  # => @[]

  )
