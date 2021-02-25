# execute this from judge-gen's project directory to build judge-gen.janet

(def src-root
  "judge-gen")

(def inputs
  ["config.janet"
   "path.janet"
   "jpm.janet"
   "grammar.janet"
   "validate.janet"
   "pegs.janet"
   "segments.janet"
   "rewrite.janet"
   "input.janet"
   "jg.janet"
   "utils.janet"
   "jg-runner.janet"
   "jg-jpm-test.janet"])

(def out-path
  "../judge-gen.janet")

(try
  (do
    (os/cd src-root)
    #
    (with [out-file (file/open out-path :w)]
      (each in-path inputs
        (with [in-file (file/open in-path :r)]
          (loop [line :iterate (file/read in-file :line)]
            # XXX: hacky and slightly brittle
            (unless (string/has-prefix? "(import" line)
              (file/write out-file line)))))
      (file/flush out-file)))
  ([err]
    (eprint "building failed")
    (error err)))
