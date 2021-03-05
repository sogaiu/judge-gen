(import ./generate :prefix "")
(import ./jpm :prefix "")
(import ./name :prefix "")
(import ./path :prefix "")
(import ./utils :prefix "")

(defn judges/make-judges
  [src-root judge-root]
  (def subdirs @[])
  (defn helper
    [src-root subdirs judge-root]
    (each path (os/dir src-root)
      (def fpath (path/join src-root path))
      (case (os/stat fpath :mode)
        :directory
        (do
          (helper fpath (array/push subdirs path)
                  judge-root)
          (array/pop subdirs))
        #
        :file
        (when (string/has-suffix? ".janet" fpath)
          (def judge-file-name
            (string (utils/no-ext path) ".judge"))
          (unless (generate/handle-one
                    {:input fpath
                     :output (path/join judge-root
                                        ;subdirs
                                        judge-file-name)})
            (eprintf "Test generation failed for: %s" fpath)
            (eprintf "Please confirm validity of source file: %s" fpath)
            (error nil))))))
  #
  (helper src-root subdirs judge-root))

# since there are no tests in this comment block, nothing will execute
(comment

  (def proj-root
    (path/join (os/getenv "HOME")
               "src" name/prog-name))

  (def judge-root
    (path/join proj-root name/dot-dir-name))

  (def src-root
    (path/join proj-root name/prog-name))

  (os/mkdir judge-root)

  (judges/make-judges src-root judge-root)

  )

(defn judges/find-judge-files
  [dir]
  (def file-paths @[])
  (defn helper
    [dir file-paths]
    (each path (os/dir dir)
      (def full-path (path/join dir path))
      (case (os/stat full-path :mode)
        :directory
        (helper full-path file-paths)
        #
        :file
        (when (string/has-suffix? ".judge" path)
          (array/push file-paths [full-path path]))))
    file-paths)
  #
  (helper dir file-paths))

(defn judges/execute-command
  [opts]
  (def {:command command
        :count count
        :judge-file-rel-path jf-rel-path
        :results-dir results-dir
        :results-full-path results-full-path} opts)
  (when (dyn :debug)
    (eprintf "command: %p" command))
  (let [jf-rel-no-ext (utils/no-ext jf-rel-path)
        err-path
        (path/join results-dir
                   (string "stderr-" count "-" jf-rel-no-ext ".txt"))
        out-path
        (path/join results-dir
                   (string "stdout-" count "-" jf-rel-no-ext ".txt"))]
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

(defn judges/make-results-dir-path
  [judge-root]
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
    (judges/make-results-dir-path ""))
  # => @[]

  )

(defn judges/ensure-results-full-path
  [results-dir fname i]
  (let [fpath (path/join results-dir
                         (string i "-" (utils/no-ext fname) ".jimage"))]
    # note: create-dirs expects a path ending in a filename
    (jpm/create-dirs fpath)
    (unless (os/stat results-dir)
      (eprintf "Failed to create dir for path: %s" fpath)
      (error nil))
    fpath))

(defn judges/judge-all
  [judge-root]
  (def results @{})
  (def file-paths
    (sort (judges/find-judge-files judge-root)))
  (var count 0)
  (def results-dir (judges/make-results-dir-path judge-root))
  #
  (each [jf-full-path jf-rel-path] file-paths
    (print "  " jf-rel-path)
    (def results-full-path
      (judges/ensure-results-full-path results-dir jf-rel-path count))
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
        (judges/execute-command
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
