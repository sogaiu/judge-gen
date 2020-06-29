(post-deps
 (import jg-verdict/phony-judge)
 (import path))

(declare-project
  :name "judge-gen"
  :url "https://github.com/sogaiu/judge-gen"
  :repo "git+https://github.com/sogaiu/judge-gen.git"
  :dependencies [
    "https://github.com/janet-lang/argparse"
    # just for project.janet
    "https://github.com/sogaiu/jg-verdict.git"
    # XXX: it may be that this needs to be listed after jg-verdict
    "https://github.com/sogaiu/janet-peg-grammar"
    # just for project.janet
    "https://github.com/janet-lang/path.git"
  ])

(post-deps

 (def proj-root
   (os/cwd))

 (def src-root
   (path/join proj-root "judge-gen"))

 (declare-executable
  :name "jg"
  :entry (path/join src-root "jg.janet")
  :install true)

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
