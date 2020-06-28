# XXX: consider whether the "judge" directory should live under /tmp
#      might be safer than removing something within the project
#      directory.  however, this could be a problem if the source
#      assumes it is living within the project directory
#      (e.g. referencing via relative paths, some kind of data files
#      that are stored within the project directory)

# XXX: transition body of code for the judge phony target to some
#      place such that it can be used as a dependency say in the form
#      of a function.  note that use of post-deps would likely be
#      necessary.  this should greatly reduce the amount of work
#      required when modifying a project.janet to be able to use
#      judge-gen.

(post-deps
  (import path))

(declare-project
  :name "judge-gen"
  :url "https://github.com/sogaiu/judge-gen"
  :repo "git+https://github.com/sogaiu/judge-gen.git"
  :dependencies [
    "https://github.com/janet-lang/argparse"
    "https://github.com/janet-lang/path.git" # only in this file
    "https://github.com/sogaiu/janet-peg-grammar"
  ])

(post-deps

 (def proj-root
   (os/cwd))

 (def src-root
   (path/join proj-root "judge-gen"))

 # XXX: if you need to have a subdirectory of your project root have the
 #      name "judge", change the following to a name you don't need to use
 (def judge-root
   (path/join proj-root "judge"))

 # XXX: if you need to use "judge-" at the beginning of a source file name,
 #      change the value below to something you don't need to use
 (def judge-file-prefix
   "judge-")

 (declare-executable
  :name "jg"
  :entry (path/join src-root "jg.janet"))

 (phony "netrepl" []
        (os/execute
         ["janet" "-e" (string "(os/cd \"" src-root "\")"
                               "(import spork/netrepl)"
                               "(netrepl/server)")] :p))

 # XXX: the following can be used to arrange for the overriding of the
 #      "test" phony target -- thanks to rduplain and bakpakin
 #
 #(put (dyn :rules) "test" nil)
 #(phony "test" ["build"]
 # etc.

 (phony "judge" ["build"]
        (defn dashes
          [&opt n]
          (default n 60)
          (string/repeat "-" n))
        (defn print-dashes
          [&opt n]
          (print (dashes n)))
        # check if jg is accessible
        (when (not= 0 (os/shell "jg --version"))
          (eprint "failed to find jg in PATH")
          (break))
        # remove old judge directory
        (print (string "cleaning out: " judge-root))
        (rm judge-root)
        # copy source files
        (copy (path/join src-root "") judge-root)
        (print-dashes)
        # create judge files
        (defn make-judges
          [dir subdirs]
          (each path (os/dir dir)
            (def fpath (path/join dir path))
            (case (os/stat fpath :mode)
              :directory (do
                           (make-judges fpath (array/push subdirs path))
                           (array/pop subdirs))
              :file (os/execute
                     ["jg"
                      "--prepend"
                      "--number" "0"
                      "--output" (path/join judge-root
                                            ;subdirs
                                            (string
                                             judge-file-prefix path))
                                 fpath] :p))))
        (make-judges src-root @[])
        # judge
        (print "judging...")
        # XXX: from jpm
        (defn pslurp
          [cmd]
          (string/trim (with [f (file/popen cmd)]
                             (:read f :all))))
        (def results @{})
        (defn judge
          [dir]
          (each path (os/dir dir)
            (def fpath (path/join dir path))
            (case (os/stat fpath :mode)
              :directory (judge fpath)
              :file (when (and (string/has-prefix? judge-file-prefix path)
                               (string/has-suffix? ".janet" fpath))
                      (print path)
                      (def command (string/join
                                    [(dyn :executable "janet") "-e"
                                     (string "'(os/cd \"" judge-root "\")'")
                                     fpath]
                                    " "))
                      (put results fpath (pslurp command))))))
        (judge judge-root)
        (print-dashes)
        # summarize results
        # XXX: mixing of pr* and file/write...ok?
        (defn print-blue
          [msg]
          (file/write stdout (string "\e[34m" msg "\e[0m")))
        (defn print-green
          [msg]
          (file/write stdout (string "\e[32m" msg "\e[0m")))
        (defn print-red
          [msg]
          (file/write stdout (string "\e[31m" msg "\e[0m")))
        (var total-tests 0)
        (var total-passed 0)
        (def failures @{})
        (eachp [fpath details] results
               (def name (path/basename fpath))
               (def p (parser/new))
               # XXX: error-handling...
               (parser/consume p details)
               (var passed 0)
               (def test-results (parser/produce p))
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
                 (put failures fpath fails)))
        (eachp [fpath failed-tests] failures
               (print fpath)
               (each fail failed-tests
                 (def {:test-value test-value
                       :name test-name
                       :passed test-passed
                       :test-form test-form} fail)
                 (print-red "failed")
                 (print ": " test-name)
                 (print-red "form")
                 (printf ": %M" test-form)
                 (print-red "value")
                 (print ":")
                 (printf "%M" test-value)))
        (if (not= total-passed total-tests)
          (do
            (print-dashes)
            (print-red total-passed))
          (print-green total-passed))
        (prin " of ")
        (print-green total-tests)
        (print " passed")
        (print-dashes)
        (print "all judgements made."))

)
