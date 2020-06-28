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
        # check if jg is accessible
        (when (not= 0 (os/shell "jg --version"))
          (eprint "failed to find jg in PATH")
          (break))
        # remove old judge directory
        (print (string "cleaning out: " judge-root))
        (rm judge-root)
        # copy source files
        (copy (path/join src-root "") judge-root)
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
        (defn print-dashes [] (print (string/repeat "-" 60)))
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
        (eachp [fpath details] results
               (print (path/basename fpath))
               (print details)
               (print-dashes))
        (print "all judgements made."))

)
