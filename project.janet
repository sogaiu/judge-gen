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
 (import jg-chambers/phony-judge)
 (import path))

(declare-project
  :name "judge-gen"
  :url "https://github.com/sogaiu/judge-gen"
  :repo "git+https://github.com/sogaiu/judge-gen.git"
  :dependencies [
    "https://github.com/janet-lang/argparse"
    "https://github.com/sogaiu/janet-peg-grammar"
    # below here, just for project.janet
    "https://github.com/janet-lang/path.git"
    "https://github.com/sogaiu/jg-chambers.git"
  ])

(post-deps

 (def proj-root
   (os/cwd))

 (def src-root
   (path/join proj-root "judge-gen"))

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
 (put (dyn :rules) "test" nil)
 (phony "test" ["build"]
        (phony-judge/execute proj-root src-root))

 (phony "judge" ["build"]
        (phony-judge/execute proj-root src-root))

)
