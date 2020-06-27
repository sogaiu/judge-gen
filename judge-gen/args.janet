(import argparse)

(def params
  ["Rewrite comment blocks as tests."
   # vim, vscode
   # emacs uses 0 for beginning of line
   #"column" {:default "1"
   #          :help "Column number, 1-based."
   #          :kind :option
   # emacs, vim, vscode
   "debug" {:help "Debug output."
            :kind :flag
            :short "d"}
   "line" {:default "1"
           :help "Line number to start search near, 1-based."
           :kind :option
           :short "l"}
   "number" {:default "1"
             :help "Number of comment blocks to select, 0 for all remaining."
             :kind :option
             :short "n"}
   "output" {:default ""
             :help "Path to store output to."
             :kind :option
             :short "o"}
   # XXX: "include" -> prepend or unwrap comment blocks in place?
   "prepend" {:default false
              :help "Prepend original source code."
              :kind :flag
              :short "p"}
   "version" {:default false
              :help "Version output."
              :kind :flag
              :short "v"}
   :default {:default "-"
             :help "Source path or - for STDIN."
             :kind :option}])

(comment

 (def file-path "./jg.janet")

 (do
   (setdyn :args ["jg" file-path])
   (argparse/argparse ;params))
`
@{"version" false
  "line" "1"
  "output" ""
  :order @[:default]
  "prepend" false
  "number" "1"
  :default file-path}
`

 (do
   (setdyn :args ["jg" file-path "-p"])
   (argparse/argparse ;params))
`
@{"version" false
  "line" "1"
  "output" ""
  :order @[:default "prepend"]
  "prepend" true
  "number" "1"
  :default file-path}
`

 )

(defn parse
  []
  (let [res (argparse/argparse ;params)
        #column (scan-number (res "column"))
        input (res :default)
        line (scan-number (res "line"))
        number (scan-number (res "number"))
        # XXX: overwrites...dangerous?
        output (res "output")
        prepend (res "prepend")
        version (res "version")]
    (setdyn :debug (res "debug"))
    (assert input "Input should be filepath or -")
    #(assert (<= 1 column) "Column should be 1 or greater.")
    (assert (<= 1 line) "Line should be 1 or greater.")
    (assert (<= 0 number) "Number should be 0 or greater.")
    (when (dyn :debug)
      (eprint "line number (cursor at): " line))
    {:input input
     :line line
     :number number
     :output output
     :prepend prepend
     :version version}))
