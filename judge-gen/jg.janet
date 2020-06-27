# LIMITS:
#
# * doesn't handle code that is not "well-formed"
#
# * newlines after comment blocks are currently considered part of the
#   identified comment block, this affects the searching for target
#   comment blocks.  to avoid including a comment block as a target,
#   place the cursor beyond the last non-whitespace character that
#   counts as part of the comment block (should be a closing paren)
#
# * likely only works with utf-8

# POSSIBILITIES:
#
# * `jpm test` integration -- an unsuccessful initial attempt was made.
#   various factors contributed to it not working out.  may try again.
#   one issue may be related to `jpm test` not currently changing its
#   current working directory before executing tests.
#
# * operate on multiple files and/or directories?
#
# * produce code with comment blocks unwrapped inline -- test context is
#   is more likely to be correct than just appending tests after original
#   code
#
# * could have option to send code to janet -k
#
# * could try to only parse not too far beyond current cursor location
#
# * consider various "rewriting" targets, e.g. testament
#
# * mode to run comment block tests from "all" files?
#
# * conversion of these types of "tests" to external files to
#   "transition" when things have solidifed enough

# ISSUES:
#
# * the function name `main` is special in janet.  having a function with this
#   name in a .janet file means that if the file is executed, `main` will be
#   called -- placing a call to `main` in the file will lead to a second call.
#   one consequence of this is that rewriting a .janet file that contains a
#   `main` function in it can lead to an undesirable call of `main` if that
#   file is executed.
#
# * exporting files to test directory has at least one complication --
#   if any such file calls `import` on something that was relative to the
#   original location, how should that be handled?  also, if the test files
#   are named the same, the following may cause a problem: support there are
#   two source files a.janet and b.janet both containing comment block tests.
#   further support that a.janet imports b.janet using relative paths.
#   exporting a.janet and b.janet to the test directory now leads to the
#   exported a.janet "referring" to the exported b.janet.  this may be
#   undesirable for at least one reason -- the tests in b will be run when
#   the tests for a are run.
#
# * how to handle rather large return values -- load from external file?
#
# * how / whether to try to test output (such as from `print`)
#
# * consider using :s instead of :ws in pegs, also in janet-peg-grammar
#
# * :refresh true is used for the project .janet files, is this a concern?

(import ./args :refresh true)
(import ./input :refresh true)
(import ./rewrite :refresh true)
(import ./segments :refresh true)

# XXX: consider `(break false)` instead of just `assert`?
(defn handle-one
  [opts]
  (def {:input input
        :line line
        :number number
        :output output
        :prepend prepend} opts)
  # read in the code, determining the byte offset of line with cursor
  (var [buf position]
       (input/slurp-input input line))
  (assert buf (string "Failed to read input for:" input))
  (when (dyn :verbose) (eprint "byte position for line: " position))
  # slice the code up into segments
  (var segments (segments/parse-buffer buf))
  (assert segments (string "Failed to parse input:" input))
  # top-level main defn is undesirable
  (when (segments/find-main-defn segments)
    (break false))
  # find which segment the cursor (position) is in
  (var from (segments/find-segment segments position))
  (assert from (string "Failed to find segment for position: " position))
  # find an appropriate comment block
  (var comment-blocks (segments/find-comment-blocks segments from number))
  (when (dyn :verbose)
    (eprint "first comment block found was: " (first comment-blocks)))
  # output rewritten content if appropriate
  (def out @"")
  (when (not (empty? comment-blocks))
    (when prepend
      (buffer/blit out buf -1))
    (buffer/blit out (rewrite/rewrite-with-verify comment-blocks) -1))
  (if (not= "" output)
    (spit output out)
    (print out))
  true)

(comment

 (def file-path "./jg.janet")

 (setdyn :args ["jg" file-path])

 (handle-one {:input file-path
              :line 1
              :number 0
              :output ""
              :prepend false})

 )

(defn main
  [& args]
  (when (not (handle-one (args/parse)))
    (os/exit 1)))
