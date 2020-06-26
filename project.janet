(declare-project
  :name "judge-gen"
  :url "https://github.com/sogaiu/judge-gen"
  :repo "git+https://github.com/sogaiu/judge-gen.git"
  :dependencies [
    "https://github.com/janet-lang/argparse"
    "https://github.com/sogaiu/janet-peg-grammar"
  ])

(declare-executable
  :name "jg"
  :entry "judge-gen/jg.janet")

(phony "netrepl" []
       (os/execute
        ["janet" "-e"
``
         (os/cd "judge-gen")
         (import spork/netrepl)
         (netrepl/server)
``      ] :p))
