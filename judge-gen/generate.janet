(import ./input :prefix "")
(import ./name :prefix "")
(import ./rewrite :prefix "")
(import ./segments :prefix "")
(import ./validate :prefix "")

(defn generate/handle-one
  [opts]
  (def {:input input
        :output output} opts)
  # read in the code
  (def buf (input/slurp-input input))
  (when (not buf)
    (eprint)
    (eprint "Failed to read input for: " input)
    (break false))
  # light sanity check
  (when (not (validate/valid-code? buf))
    (eprint)
    (eprint "Failed to parse input as valid Janet code: " input)
    (break false))
  # slice the code up into segments
  (def segments (segments/parse buf))
  (when (not segments)
    (eprint)
    (eprint "Failed to find segments: " input)
    (break false))
  # find comment blocks
  (def comment-blocks (segments/find-comment-blocks segments))
  (when (empty? comment-blocks)
    (when (dyn :debug)
      (eprint "no comment blocks found"))
    (break true))
  (when (dyn :debug)
    (eprint "first comment block found was: " (first comment-blocks)))
  # output rewritten content
  (let [rewritten (try
                    (rewrite/rewrite-with-verify comment-blocks)
                    ([err]
                      (def {:ev-form ev-form
                            :line line
                            :offset offset} err)
                      (eprint)
                      (eprintf "Mal-formed value: `%s` in: `%s` line: %d"
                               ev-form
                               input
                               (dec (+ line offset)))
                      nil))]
    (when (nil? rewritten)
      (break false))
    (buffer/blit buf rewritten -1))
  (if (not= "" output)
    (spit output buf)
    (print buf))
  true)

# since there are no tests in this comment block, nothing will execute
(comment

  (def file-path "./generate.janet")

  # output to stdout
  (generate/handle-one {:input file-path
                        :output ""})

  # output to file
  (generate/handle-one {:input file-path
                        :output (string "/tmp/"
                                        name/prog-name
                                        "-test-output.txt")})

  )
