(import ./argparse :prefix "")

(def args/params
  ["Rewrite comment blocks as tests."
   "debug" {:help "Debug output."
            :kind :flag
            :short "d"}
   "lint" {:default false
           :help "Whether to lint input."
           :kind :flag
           :short "l"}
   "output" {:default ""
             :help "Path to store output to."
             :kind :option
             :short "o"}
   "version" {:default false
              :help "Version output."
              :kind :flag
              :short "v"}
   :default {:default "-"
             :help "Source path or - for STDIN."
             :kind :option}])

(comment

  (def file-path "./jg.janet")

  (deep=
    (do
      (setdyn :args ["jg" file-path])
      (argparse/argparse ;args/params))
    #
    @{"version" false
      "lint" false
      "output" ""
      :order @[:default]
      :default file-path}) # => true

  )

(defn args/parse
  []
  (when-let [res (argparse/argparse ;args/params)]
    (let [input (res :default)
          lint (res "lint")
          # XXX: overwrites...dangerous?
          output (res "output")
          version (res "version")]
      (setdyn :debug (res "debug"))
      (assert input "Input should be filepath or -")
      {:input input
       :lint lint
       :output output
       :version version})))
