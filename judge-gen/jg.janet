(import ./args :refresh true)
(import ./input :refresh true)
(import ./rewrite :refresh true)
(import ./segments :refresh true)

# XXX: consider `(break false)` instead of just `assert`?
(defn handle-one
  [opts]
  (def {:format format
        :input input
        :line line
        :number number
        :output output
        :prepend prepend
        :version version} opts)
  # XXX: review
  (when version
    (break true))
  # read in the code, determining the byte offset of line with cursor
  (var [buf position]
       (input/slurp-input input line))
  (assert buf (string "Failed to read input for:" input))
  (when (dyn :debug) (eprint "byte position for line: " position))
  # slice the code up into segments
  (var segments (segments/parse-buffer buf))
  (assert segments (string "Failed to parse input:" input))
  # find which segment the cursor (position) is in
  (var from (segments/find-segment segments position))
  (assert from (string "Failed to find segment for position: " position))
  # find an appropriate comment block
  (var comment-blocks (segments/find-comment-blocks segments from number))
  (when (dyn :debug)
    (eprint "first comment block found was: " (first comment-blocks)))
  # output rewritten content if appropriate
  (when (empty? comment-blocks)
    (break false))
  (def out @"")
  (when prepend
    (buffer/blit out buf -1))
  (buffer/blit out (rewrite/rewrite-with-verify comment-blocks format) -1)
  (if (not= "" output)
    (spit output out)
    (print out))
  true)

(comment

 (def file-path "./jg.janet")

 (comment
  # XXX: this kind of expression isn't handled properly by jg
  (handle-one {:input file-path
               :line 1
               :number 0
               :output ""
               :prepend false})
 )

 )

(defn main
  [& args]
  (when (not (handle-one (args/parse)))
    (os/exit 1)))
