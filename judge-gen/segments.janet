(import ./pegs :prefix "")

(defn segments/parse
  [buf]
  (var segments @[])
  (var from 0)
  (loop [parsed :iterate (peg/match pegs/top-level buf from)]
    (when (dyn :debug)
      (eprintf "parsed: %j" parsed))
    (when (not parsed)
      (break nil))
    (def segment (first parsed))
    (when (not segment)
      (eprint "Unexpectedly did not find segment in: " parsed)
      (break nil))
    (array/push segments segment)
    (set from (segment :end)))
  segments)

(comment

  (def code-buf
    @``
    (def a 1)

    (comment

      (+ a 1)
      # => 2

      (def b 3)

      (- b a)
      # => 2

    )
    ``)

  (deep=
    (segments/parse code-buf)
    #
    @[{:value "    (def a 1)\n\n    "
       :s-line 1
       :type :value
       :end 19}
      {:value (string "(comment\n\n      "
                      "(+ a 1)\n      "
                      "# => 2\n\n      "
                      "(def b 3)\n\n      "
                      "(- b a)\n      "
                      "# => 2\n\n    "
                      ")\n    ")
       :s-line 3
       :type :value
       :end 112}]
    ) # => true

  )

(defn segments/find-comment-blocks
  [segments]
  (var comment-blocks @[])
  (loop [i :range [0 (length segments)]]
    (def segment (get segments i))
    (def {:value code-str} segment)
    (when (peg/match pegs/comment-block-maybe code-str)
      (array/push comment-blocks segment)))
  comment-blocks)

(comment

  (def segments
    @[{:value "    (def a 1)\n\n    "
       :s-line 1
       :type :value
       :end 19}
      {:value (string "(comment\n\n      "
                      "(+ a 1)\n      "
                      "# => 2\n\n      "
                      "(def b 3)\n\n      "
                      "(- b a)\n      "
                      "# => 2\n\n    "
                      ")\n    ")
       :s-line 3
       :type :value
       :end 112}])

  (deep=
    (segments/find-comment-blocks segments)
    #
    @[{:value (string "(comment\n\n      "
                      "(+ a 1)\n      "
                      "# => 2\n\n      "
                      "(def b 3)\n\n      "
                      "(- b a)\n      "
                      "# => 2\n\n    "
                      ")\n    ")
       :s-line 3
       :type :value
       :end 112}]
    )
  # => true

  )
