(import ./jg :prefix "")
(import ./jpm :prefix "")
(import ./path :prefix "")
(import ./utils :prefix "")

(defn jg-runner/make-judges
  [src-root judge-root judge-file-prefix]
  (def subdirs @[])
  (defn helper
    [src-root subdirs judge-root judge-file-prefix]
    (each path (os/dir src-root)
      (def fpath (path/join src-root path))
      (case (os/stat fpath :mode)
        :directory
        (do
          (helper fpath (array/push subdirs path)
                  judge-root judge-file-prefix)
          (array/pop subdirs))
        #
        :file
        (when (string/has-suffix? ".janet" fpath)
          (unless (jg/handle-one
                    {:input fpath
                     :output (path/join judge-root
                                        ;subdirs
                                        (string
                                          judge-file-prefix path))})
            (eprintf "Test generation failed for: %s" fpath)
            (eprintf "Please confirm validity of source file: %s" fpath)
            (error nil))))))
  #
  (helper src-root subdirs judge-root judge-file-prefix))

# XXX: since there are no tests in this comment block, nothing will execute
(comment

  (def proj-root
    (path/join (os/getenv "HOME")
               "src" "judge-gen"))

  (def judge-root
    (path/join proj-root "judge"))

  (def src-root
    (path/join proj-root "judge-gen"))

  (os/mkdir judge-root)

  (jg-runner/make-judges src-root judge-root "judge-" true)

  )

(defn jg-runner/find-judge-files
  [dir judge-file-prefix]
  (def file-paths @[])
  (defn helper
    [dir judge-file-prefix file-paths]
    (each path (os/dir dir)
      (def full-path (path/join dir path))
      (case (os/stat full-path :mode)
        :directory
        (helper full-path judge-file-prefix file-paths)
        #
        :file
        (when (and (string/has-prefix? judge-file-prefix path)
                   (string/has-suffix? ".janet" path))
          (array/push file-paths [full-path path]))))
    file-paths)
  #
  (helper dir judge-file-prefix file-paths))

(defn jg-runner/execute-command
  [opts]
  (def {:command command
        :count count
        :judge-file-rel-path jf-rel-path
        :results-dir results-dir
        :results-full-path results-full-path} opts)
  (when (dyn :debug)
    (eprintf "command: %p" command))
  (let [err-path
        (path/join results-dir
                   (string "stderr-" count "-" jf-rel-path ".txt"))
        out-path
        (path/join results-dir
                   (string "stdout-" count "-" jf-rel-path ".txt"))]
    (try
      (with [ef (file/open err-path :w)]
        (with [of (file/open out-path :w)]
          (os/execute command :px {:err ef
                                   :out of})
          (file/flush ef)
          (file/flush of)))
      ([_]
        (error {:out-path out-path
                :err-path err-path
                :type :command-failed}))))
  (def marshalled-results
    (try
      (slurp results-full-path)
      ([err]
        (eprintf "Failed to read in marshalled results from: %s"
                 results-full-path)
        (error nil))))
  # resurrect the results
  (try
    (unmarshal (buffer marshalled-results))
    ([err]
      (eprintf "Failed to unmarshal content from: %s"
               results-full-path)
      (error nil))))

(defn jg-runner/make-results-dir-path
  [judge-root]
  # XXX: what about windows...
  (path/join judge-root
             (string "." (os/time) "-"
                     (utils/rand-string 8) "-"
                     "judge-gen")))

(comment

  (peg/match ~(sequence (choice "/" "\\")
                        "."
                        (some :d)
                        "-"
                        (some :h)
                        "-"
                        "judge-gen")
    (jg-runner/make-results-dir-path ""))
  # => @[]

  )

(defn jg-runner/ensure-results-full-path
  [results-dir fname i]
  (let [fpath (path/join results-dir (string i "-" fname))]
    # note: create-dirs expects a path ending in a filename
    (jpm/create-dirs fpath)
    (unless (os/stat results-dir)
      (eprintf "Failed to create dir for path: %s" fpath)
      (error nil))
    fpath))

(defn jg-runner/judge
  [judge-root judge-file-prefix]
  (def results @{})
  (def file-paths
    (sort (jg-runner/find-judge-files judge-root judge-file-prefix)))
  (var count 0)
  (def results-dir (jg-runner/make-results-dir-path judge-root))
  #
  (each [jf-full-path jf-rel-path] file-paths
    (print "  " jf-rel-path)
    (def results-full-path
      (jg-runner/ensure-results-full-path results-dir jf-rel-path count))
    (when (dyn :debug)
      (eprintf "results path: %s" results-full-path))
    # backticks below for cross platform compatibility
    (def command [(dyn :executable "janet")
                  "-e" (string "(os/cd `" judge-root "`)")
                  "-e" (string "(do "
                               "  (setdyn :judge-gen/test-out "
                               "          `" results-full-path "`) "
                               "  (dofile `" jf-full-path "`) "
                               ")")])
    (when (dyn :debug)
      (eprintf "command: %p" command))
    (def results-for-path
      (try
        (jg-runner/execute-command
          {:command command
           :count count
           :judge-file-rel-path jf-rel-path
           :results-dir results-dir
           :results-full-path results-full-path})
        ([err]
          (when err
            (if-let [err-type (err :type)]
              # XXX: if more errors need to be handled, check err-type
              (let [{:out-path out-path
                     :err-path err-path} err]
                (eprintf "Command failed:\n  %p" command)
                (eprint "Potentially relevant paths:")
                (eprintf "  %s" results-full-path)
                (eprintf "  %s" out-path)
                (eprintf "  %s" err-path)
                (eprintf "  %s" jf-full-path))
              (eprintf "Unknown error:\n %p" err)))
          (error nil))))
    (put results
         jf-full-path results-for-path)
    (++ count))
  results)

(defn jg-runner/summarize
  [results]
  (when (empty? results)
    (eprint "No test results")
    (break true))
  (var total-tests 0)
  (var total-passed 0)
  (def failures @{})
  (eachp [fpath test-results] results
    (def name (path/basename fpath))
    (when test-results
      (var passed 0)
      (var num-tests (length test-results))
      (var fails @[])
      (each test-result test-results
        (++ total-tests)
        (def {:passed test-passed} test-result)
        (if test-passed
          (do
            (++ passed)
            (++ total-passed))
          (array/push fails test-result)))
      (when (not (empty? fails))
        (put failures fpath fails))))
  (when (pos? (length failures))
    (print))
  (eachp [fpath failed-tests] failures
    (print fpath)
    (each fail failed-tests
      (def {:test-value test-value
            :expected-value expected-value
            :name test-name
            :passed test-passed
            :test-form test-form} fail)
      (print)
      (utils/print-color (string "  failed: " test-name) :red)
      (print)
      (printf "    form: %M" test-form)
      (prin "expected")
      # XXX: this could use some work...
      (if (< 30 (length (describe expected-value)))
        (print ":")
        (prin ": "))
      (printf "%m" expected-value)
      (prin "  actual")
      # XXX: this could use some work...
      (if (< 30 (length (describe test-value)))
        (print ":")
        (prin ": "))
      (utils/print-color (string/format "%m" test-value) :blue)
      (print)))
  (when (zero? (length failures))
    (print)
    (print "No tests failed."))
  (print)
  (utils/print-dashes)
  (when (= 0 total-tests)
    (print "No tests found, so no judgements made.")
    (break true))
  (if (not= total-passed total-tests)
    (utils/print-color total-passed :red)
    (utils/print-color total-passed :green))
  (prin " of ")
  (utils/print-color total-tests :green)
  (print " passed")
  (utils/print-dashes)
  (= total-passed total-tests))

# XXX: since there are no tests in this comment block, nothing will execute
(comment

  (jg-runner/summarize @{})

  )

(defn jg-runner/handle-one
  [opts]
  (def {:judge-dir-name judge-dir-name
        :judge-file-prefix judge-file-prefix
        :proj-root proj-root
        :src-root src-root} opts)
  (def judge-root
    (path/join proj-root judge-dir-name))
  (try
    (do
      (utils/print-dashes)
      (print)
      (print "judge-gen is starting...")
      (print)
      (utils/print-dashes)
      # remove old judge directory
      (prin "Cleaning out: " judge-root " ... ")
      (jpm/rm judge-root)
      # make a fresh judge directory
      (os/mkdir judge-root)
      (print "done")
      # copy source files
      (prin "Copying source files... ")
      # shhhhh
      (with-dyns [:out @""]
        # each item copied separately for platform consistency
        (each item (os/dir src-root)
          (def full-path (path/join src-root item))
          (jpm/copy full-path judge-root)))
      (print "done")
      # create judge files
      (prin "Creating tests files... ")
      (flush)
      (jg-runner/make-judges src-root judge-root judge-file-prefix)
      (print "done")
      # judge
      (print "Judging...")
      (def results
        (jg-runner/judge judge-root judge-file-prefix))
      (utils/print-dashes)
      # summarize results
      (def all-passed
        (jg-runner/summarize results))
      (print)
      # XXX: if detecting that being run via `jpm test` is possible,
      #      may be can show following only when run from `jpm test`
      (print "judge-gen is done, later output may be from `jpm test`")
      (print)
      (utils/print-dashes)
      all-passed)
    #
    ([err]
      (when err
        (eprint "Unexpected error:\n")
        (eprintf "\n%p" err))
      (eprint "Runner stopped")
      nil)))

# XXX: since there are no tests in this comment block, nothing will execute
(comment

  (def proj-root
    (path/join (os/getenv "HOME")
               "src" "judge-gen"))

  (def src-root
    (path/join proj-root "judge-gen"))

  (jg-runner/handle-one {:judge-dir-name "judge"
                         :judge-file-prefix "judge-"
                         :proj-root proj-root
                         :src-root src-root})

  )
