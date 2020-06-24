# GOALS:
#
# * make simple testing low-cost and automatable especially during
#   exploratory coding
#
# * provide a canonical location for illustrative examples to help
#   potential users begin to form appropriate mental models

# MECHANISMS:
#
# * using `comment` blocks, record expressions / forms to be tested
#
# * express an expected return value by either a single line comment
#   immediately following an expression to test, e.g.:
#
#     (- 1 1)
#     # => 0
#
# * instead of a single line comment, a long-string may be used to
#   express an expected return value.  this makes it possible to format
#   the expected return value for easier human recognition, e.g.:
#
#     (put (table :alpha "first" :beta "second") :gamma "third")
#     `
#     {:alpha "first"
#      :beta "second"
#      :gamma "third"}
#     `
#
# * expected errors may also be expressed using a single line comment,
#   e.g.:
#
#     (error "this is an error")
#     # !
#
# N.B. remember to place these expressions and "expected values / errors"
#      inside a `(comment ...)` block

# TIPS:
#
# * use [] instead of () in some places to express return values
#   (e.g. `# => [:hi 1]` not `# => (:hi 1)`)
#
# * express return values that span multiple lines by using long strings

# LIMITS:
#
# * doesn't handle code that is not "well-formed"
#
# * likely only works with utf-8

# POSSIBILITIES:
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
# * how to handle rather large return values -- load from external file?
#
# * how / whether to try to test output (such as from `print`)
#
# * don't have start-tests and end-tests print directly, but rather
#   return info or output via indirection?

(import argparse)
(import ./input :prefix "")
(import ./pegs :prefix "")
(import ./rewrite :prefix "")

(defn- slurp-input
  [input line]
  (var f nil)
  (if (= input "-")
    (set f stdin)
    (if (os/stat input)
      # XXX: handle failure?
      (set f (file/open input :rb))
      (do
        (eprint "path not found: " input)
        (break [nil nil]))))
  (read-input f line))

(defn- parse-to-segments
  [buf]
  (var segments @[])
  (var from 0)
  (loop [parsed :iterate (peg/match jg-pos buf from)]
    (when (dyn :verbose)
      (eprintf "parsed: %j" parsed))
    (when (not parsed)
      (break))
    (def segment (first parsed))
    (assert segment
            (string "Unexpectedly did not find segment in: " parsed))
    (array/push segments segment)
    (set from (segment :end)))
  segments)

(defn- find-segment
  [segments position]
  (var ith nil)
  (eachp [i segment] segments
         (def {:end end
               :start start} segment)
         (when (dyn :verbose)
           (eprint "start: " start)
           (eprint "end: " end))
         (when (<= start position (dec end))
           (set ith i)
           (break)))
  ith)

(defn- find-comment-blocks
  [segments from number]
  (var comment-blocks @[])
  (var remaining number)
  (loop [i :range [from (length segments)]]
    (when (and (not= number 0)
               (= remaining 0))
      (break))
    (def {:value code-str} (get segments i))
    (when (peg/match comment-block-maybe code-str)
      (-- remaining)
      (array/push comment-blocks code-str)))
  comment-blocks)

(def- params
  ["Rewrite comment blocks as tests."
   # vim, vscode
   # emacs uses 0 for beginning of line
   #"column" {:default "1"
   #          :help "Column number, 1-based."
   #          :kind :option
   # emacs, vim, vscode
   "line" {:default "1"
           :help "Line number to start search near, 1-based."
           :kind :option
           :short "l"}
   "number" {:default "1"
             :help "Number of comment blocks to select, 0 for all remaining."
             :kind :option
             :short "n"}
   "verbose" {:help "Verbose output."
              :kind :flag
              :short "v"}
   :default {:default "-"
             :help "Source path or - for STDIN."
             :kind :option}])

(comment

 (setdyn :args ["jg" "judge-gen.janet"])
 # => ["jg" "judge-gen.janet"]

 (argparse/argparse ;params)
 # => @{"line" "1" :order @[:default] :default "judge-gen.janet"}

 )

# XXX: how to indicate error when invoked by external program such as editor?
(defn main
  [& args]
  (let [res (argparse/argparse ;params)
        #column (scan-number (res "column"))
        input (res :default)
        line (scan-number (res "line"))
        number (scan-number (res "number"))]
    (setdyn :verbose (res "verbose"))
    (assert input "Input should be filepath or -")
    #(assert (<= 1 column) "Column should be 1 or greater.")
    (assert (<= 1 line) "Line should be 1 or greater.")
    (assert (<= 0 number) "Number should be 0 or greater.")
    (when (dyn :verbose) (eprint "line number (cursor at): " line))
    # read in the code, determining the byte offset of line with cursor
    (var [buf position]
         (slurp-input input line))
    (assert buf (string "Failed to read input for:" input))
    (when (dyn :verbose) (eprint "byte position for line: " position))
    # slice the code up into segments
    (var segments (parse-to-segments buf))
    (assert segments (string "Failed to parse input:" input))
    # find which segment the cursor (position) is in
    (var from (find-segment segments position))
    (assert from (string "Failed to find segment for position: " position))
    # find an appropriate comment block
    (var comment-blocks (find-comment-blocks segments from number))
    (when (dyn :verbose)
      (eprint "first comment block found was: " (first comment-blocks)))
    # output rewritten content if appropriate
    (if (not (empty? comment-blocks))
      (print (rewrite-with-verify comment-blocks))
      (print nil))))

(comment

 (setdyn :args ["jg" "judge-gen.janet"])
 # => ["jg" "judge-gen.janet"]

 (main)

 )
