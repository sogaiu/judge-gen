(import ./utils :prefix "")
(import ./jg :prefix "")
(import ./args-runner :prefix "")
(import ./jpm :prefix "")
(import ./path :prefix "")

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
          (jg/handle-one {:input fpath
                          :lint true # XXX: make optional?
                          :output (path/join judge-root
                                             ;subdirs
                                             (string
                                               judge-file-prefix path))})))))
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

  (jg-runner/make-judges src-root judge-root "judge-")

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

(defn jg-runner/judge
  [judge-root judge-file-prefix]
  (def results @{})
  (def file-paths
    (jg-runner/find-judge-files judge-root judge-file-prefix))
  (var count 0)
  (def results-dir
    # XXX: what about windows...
    (path/join judge-root
               (string "."
                       (os/time) "-"
                       (utils/rand-string 8) "-"
                       "judge-gen")))
  (defn make-results-fpath
    [fname i]
    (let [fpath (path/join results-dir
                           (string i "-" fname))]
      # note: create-dirs expects a path ending in a filename
      (try
        (jpm/create-dirs fpath)
        ([err]
          (errorf "failed to create dir for path: " fpath)))
      fpath))
  #
  (each [full-path path] file-paths
    (print "  " path)
    (def results-fpath
      (make-results-fpath path count))
    # XXX
    #(eprintf "results path: %s" results-fpath)
    # using backticks below seemed to help make things work on multiple
    # platforms
    (def command [(dyn :executable "janet")
                  "-e"
                  (string "(os/cd `" judge-root "`)")
                  "-e"
                  (string "(do "
                          "  (setdyn :judge-gen/test-out "
                          "          `" results-fpath "`) "
                          "  (dofile `" full-path "`) "
                          ")")])
    # XXX
    #(eprintf "command: %p" command)
    (let [out-path
          (path/join results-dir
                     (string "stdout-" count "-" path ".txt"))]
      (try
        (with [f (file/open out-path :w)]
          (os/execute command :px {:out f})
          (file/flush f))
        ([err]
          (eprint err)
          (errorf "command failed: %p" command))))
    (def marshalled-results
      (try
        (slurp results-fpath)
        ([err]
          (eprint err)
          (errorf "failed to read in marshalled results from: %s"
                  results-fpath))))
    (def results-for-path
      (try
        (unmarshal (buffer marshalled-results))
        ([err]
          (eprintf err)
          (errorf "failed to unmarshal content from: %s"
                  results-fpath))))
    (put results
         full-path results-for-path)
    (++ count))
  results)

(defn jg-runner/summarize
  [results]
  (when (empty? results)
    # XXX: somehow messes things up?
    #(print "No test results")
    (break))
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
  (eachp [fpath failed-tests] failures
    (print fpath)
    (each fail failed-tests
      (def {:test-value test-value
            :expected-value expected-value
            :name test-name
            :passed test-passed
            :test-form test-form} fail)
      (utils/print-color "  failed" :red)
      (print ": " test-name)
      (utils/print-color "    form" :red)
      (printf ": %M" test-form)
      (utils/print-color "expected" :red)
      # XXX: this could use some work...
      (if (< 30 (length (describe expected-value)))
        (print ":")
        (prin ": "))
      (printf "%M" expected-value)
      (utils/print-color "  actual" :red)
      # XXX: this could use some work...
      (if (< 30 (length (describe test-value)))
        (print ":")
        (prin ": "))
      (printf "%M" test-value)))
  (when (= 0 total-tests)
    (print "No tests found, so no judgements made.")
    (break))
  (if (not= total-passed total-tests)
    (do
      (utils/print-dashes)
      (utils/print-color total-passed :red))
    (utils/print-color total-passed :green))
  (prin " of ")
  (utils/print-color total-tests :green)
  (print " passed")
  (utils/print-dashes)
  (print "all judgements made.")
  (= total-passed total-tests))

# XXX: since there are no tests in this comment block, nothing will execute
(comment

  (jg-runner/summarize @{})

  )

# XXX: consider `(break false)` instead of just `assert`?
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
      # remove old judge directory
      (prin "cleaning out: " judge-root " ... ")
      (jpm/rm judge-root)
      # make a fresh judge directory
      (os/mkdir judge-root)
      (print "done")
      # copy source files
      (prin "copying source files... ")
      # shhhhh
      (with-dyns [:out @""]
        # each item copied separately for platform consistency
        (each item (os/dir src-root)
          (def full-path (path/join src-root item))
          (jpm/copy full-path judge-root)))
      (print "done")
      # create judge files
      (prin "creating tests files... ")
      (jg-runner/make-judges src-root judge-root judge-file-prefix)
      (print "done")
      #
      (utils/print-dashes)
      # judge
      (print "judging...")
      (def results
        (jg-runner/judge judge-root judge-file-prefix))
      (utils/print-dashes)
      (print)
      # summarize results
      (jg-runner/summarize results))
    #
    ([err]
      (eprint "judge-gen runner failed")
      (eprint err)
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
