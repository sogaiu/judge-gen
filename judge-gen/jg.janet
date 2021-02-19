(import ./args)
(import ./input)
(import ./rewrite)
(import ./segments)

# XXX: consider `(break false)` instead of just `assert`?
(defn handle-one
  [opts]
  (def {:input input
        :output output
        :version version} opts)
  # XXX: review
  (when version
    (break true))
  # read in the code
  (def buf (input/slurp-input input))
  (assert buf (string "Failed to read input for:" input))
  # slice the code up into segments
  (def segments (segments/parse-buffer buf))
  (assert segments (string "Failed to parse input:" input))
  # find comment blocks
  (def comment-blocks (segments/find-comment-blocks segments))
  (when (empty? comment-blocks)
    (break false))
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
  (handle-one {:input file-path
               :output ""
               :single true})

  # output to file
  (handle-one {:input file-path
               :output "/tmp/judge-gen-test-output.txt"
               :single true})

  )

(defn main
  [& args]
  (def opts (args/parse))
  (unless opts
    (os/exit 1))
  (cond
    (opts :version)
    (print "judge-gen alpha")
    #
    (handle-one opts)
    true))
