(import ./display :prefix "")
(import ./jpm :prefix "")
(import ./judges :prefix "")
(import ./name :prefix "")
(import ./path :prefix "")
(import ./summary :prefix "")
(import ./utils :prefix "")

(defn runner/handle-one
  [opts]
  (def {:judge-dir-name judge-dir-name
        :proj-root proj-root
        :src-root src-root} opts)
  (def judge-root
    (path/join proj-root judge-dir-name))
  (try
    (do
      (display/print-dashes)
      (print)
      (print (string name/prog-name " is starting..."))
      (print)
      (display/print-dashes)
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
      (judges/make-judges src-root judge-root)
      (print "done")
      # judge
      (print "Judging...")
      (def results
        (judges/judge-all judge-root))
      (display/print-dashes)
      # summarize results
      (def all-passed
        (summary/report results))
      (print)
      # XXX: if detecting that being run via `jpm test` is possible,
      #      may be can show following only when run from `jpm test`
      (print (string name/prog-name
                     " is done, later output may be from `jpm test`"))
      (print)
      (display/print-dashes)
      all-passed)
    #
    ([err]
      (when err
        (eprint "Unexpected error:\n")
        (eprintf "\n%p" err))
      (eprint "Runner stopped")
      nil)))

# since there are no tests in this comment block, nothing will execute
(comment

  (def proj-root
    (path/join (os/getenv "HOME")
               "src" name/prog-name))

  (def src-root
    (path/join proj-root name/prog-name))

  (runner/handle-one {:judge-dir-name name/dot-dir-name
                      :proj-root proj-root
                      :src-root src-root})

  )
