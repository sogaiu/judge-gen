(import ./input :prefix "")
(import ./rewrite :prefix "")
(import ./segments :prefix "")

(defn jg/handle-one
  [opts]
  (def {:input input
        :output output} opts)
  # read in the code
  (def buf (input/slurp-input input))
  (when (not buf)
    (eprint)
    (eprint "Failed to read input for: " input)
    (break false))
  # slice the code up into segments
  (def segments (segments/parse-buffer buf))
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
  (buffer/blit buf (rewrite/rewrite-with-verify comment-blocks) -1)
  (if (not= "" output)
    (spit output buf)
    (print buf))
  true)

# XXX: since there are no tests in this comment block, nothing will execute
(comment

  (def file-path "./jg.janet")

  # output to stdout
  (jg/handle-one {:input file-path
                  :output ""
                  :single true})

  # output to file
  (jg/handle-one {:input file-path
                  :output "/tmp/judge-gen-test-output.txt"
                  :single true})

  )
