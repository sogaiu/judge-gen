(declare-project
  :name "judge-gen"
  :url "https://codeberg.org/sogaiu/judge-gen"
  :repo "git+https://codeberg.org/sogaiu/judge-gen.git")

# XXX: not sure if doing this is a good idea...

(put (dyn :rules) "build" nil)
(phony "build" []
       (os/execute ["janet"
                    "build.janet"] :p))

(put (dyn :rules) "clean" nil)
(phony "clean" []
       (os/execute ["janet"
                    "clean.janet"] :p))
