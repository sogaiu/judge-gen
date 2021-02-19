(import ./vendor/argparse)

(def params
  ["Rewrite comment blocks as tests."
   "debug" {:help "Debug output."
            :kind :flag
            :short "d"}
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
      (argparse/argparse ;params))
    #
    @{"version" false
      "output" ""
      :order @[:default]
      :default file-path}) # => true

  )

(defn parse
  []
  (when-let [res (argparse/argparse ;params)]
    (let [input (res :default)
          # XXX: overwrites...dangerous?
          output (res "output")
          version (res "version")]
      (setdyn :debug (res "debug"))
      (assert input "Input should be filepath or -")
      {:input input
       :output output
       :version version})))
