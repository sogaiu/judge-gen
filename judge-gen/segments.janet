(import ./pegs :refresh true)

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

(defn find-segment
  [segments position]
  (var ith nil)
  (var val nil)
  (var shifted 0)
  (eachp [i segment] segments
         (def {:end end
               :start start
               :value value} segment)
         (when (dyn :debug)
           (eprint "start: " start)
           (eprint "end: " end))
         (when (<= start position (dec end))
           (set ith i)
           (set val value)
           (set shifted (- position start))
           (break)))
  # adjust if position is within trailing whitespace
  (when ith
    # attempt to capture any non-whitespace
    (when (empty? (peg/match '(any (choice :s (capture :S)))
                              val shifted))
      (++ ith)))
  ith)

(defn find-comment-blocks
  [segments from number]
  (var comment-blocks @[])
  (var remaining number)
  (loop [i :range [from (length segments)]]
    (when (and (not= number 0)
               (= remaining 0))
      (break))
    (def {:value code-str} (get segments i))
    (when (peg/match pegs/comment-block-maybe code-str)
      (-- remaining)
      (array/push comment-blocks code-str)))
  comment-blocks)
