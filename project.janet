(import ./judge-gen/vendor/path)

(declare-project
  :name "judge-gen"
  :url "https://github.com/sogaiu/judge-gen"
  :repo "git+https://github.com/sogaiu/judge-gen.git")

(def proj-root
  (os/cwd))

(def src-root
  (path/join proj-root "judge-gen"))

(declare-executable
 :name "jg"
 :entry (path/join src-root "jg.janet")
 :install true)

(declare-executable
 :name "jg-verdict"
 :entry (path/join src-root "jg-verdict.janet")
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
       (os/execute ["jg-verdict"
                    "-p" proj-root
                    "-s" src-root] :p))

(phony "judge" ["build"]
       (os/execute ["jg-verdict"
                    "-p" proj-root
                    "-s" src-root] :p))
