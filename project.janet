(import ./support/vendor/path)

(declare-project
  :name "judge-gen"
  :url "https://codeberg.org/sogaiu/judge-gen"
  :repo "git+https://codeberg.org/sogaiu/judge-gen.git")

(def proj-root
  (os/cwd))

(def src-root
  (path/join proj-root "judge-gen"))

(phony "netrepl" []
       (os/execute
        ["janet" "-e" (string "(os/cd \"" src-root "\")"
                              "(import spork/netrepl)"
                              "(netrepl/server)")] :p))

