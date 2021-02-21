(import ./argparse :prefix "")

(def args-runner/params
  ["Comment block test runner."
   "debug" {:help "Debug output."
            :kind :flag
            :short "d"}
   "judge-file-prefix" {:default "judge-"
                        :help "Prefix for test files."
                        :kind :option
                        :short "f"}
   "judge-dir-name" {:default "judge"
                     :help "Name of judge directory."
                     :kind :option
                     :short "j"}
   "project-root" {:help "Project root."
                   :kind :option
                   :short "p"}
   "source-root" {:help "Source root."
                  :kind :option
                  :short "s"}])

(comment

  (deep=
    (do
      (setdyn :args ["jg-runner"
                     "-p" ".."
                     "-s" "."])
      (argparse/argparse ;args-runner/params))

    @{"judge-file-prefix" "judge-"
      "judge-dir-name" "judge"
      :order @["project-root" "source-root"]
      "project-root" ".."
      "source-root" "."}) # => true

  )

(defn args-runner/parse
  []
  (def res (argparse/argparse ;args-runner/params))
  (unless res
    (break nil))
  (let [judge-dir-name (res "judge-dir-name")
        judge-file-prefix (res "judge-file-prefix")
        proj-root (or (res "project-root") "")
        src-root (or (res "source-root") "")]
    (setdyn :debug (res "debug"))
    (assert (os/stat proj-root)
            (string "Project root not detected: " proj-root))
    (assert (os/stat src-root)
            (string "Source root not detected: " src-root))
    {:judge-dir-name judge-dir-name
     :judge-file-prefix judge-file-prefix
     :proj-root proj-root
     :src-root src-root}))
