(import ./pegs)

(defn parse-buffer
  [buf]
  (var segments @[])
  (var from 0)
  (loop [parsed :iterate (peg/match pegs/jg-pos buf from)]
    (when (dyn :debug)
      (eprintf "parsed: %j" parsed))
    (when (not parsed)
      (break))
    (def segment (first parsed))
    (assert segment
            (string "Unexpectedly did not find segment in: " parsed))
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
    (parse-buffer code-buf)
    #
    @[{:value "    (def a 1)\n\n    "
       :start 0
       :type :value
       :end 19}
      {:value (string "(comment\n\n      "
                      "(+ a 1)\n      "
                      "# => 2\n\n      "
                      "(def b 3)\n\n      "
                      "(- b a)\n      "
                      "# => 2\n\n    "
                      ")\n    ")
       :start 19
       :type :value
       :end 112}]
    ) # => true

  )

(defn find-comment-blocks
  [segments]
  (var comment-blocks @[])
  (loop [i :range [0 (length segments)]]
    (def {:value code-str} (get segments i))
    (when (peg/match pegs/comment-block-maybe code-str)
      (array/push comment-blocks code-str)))
  comment-blocks)

(comment

  (def segments
    @[{:value "    (def a 1)\n\n    "
       :start 0
       :type :value
       :end 19}
      {:value (string "(comment\n\n      "
                      "(+ a 1)\n      "
                      "# => 2\n\n      "
                      "(def b 3)\n\n      "
                      "(- b a)\n      "
                      "# => 2\n\n    "
                      ")\n    ")
       :start 19
       :type :value
       :end 112}])

  (deep=
    (find-comment-blocks segments)
    #
    @[(string "(comment\n\n      "
              "(+ a 1)\n      "
              "# => 2\n\n      "
              "(def b 3)\n\n      "
              "(- b a)\n      "
              "# => 2\n\n    "
              ")\n    ")]
    ) # => true

)
