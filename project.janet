(declare-project
  :name "judge-gen"
  :url "https://codeberg.org/sogaiu/judge-gen"
  :repo "git+https://codeberg.org/sogaiu/judge-gen.git")

# XXX: not sure if doing this is a good idea...

(put (dyn :rules) "build" nil)
(phony "build" []
       (os/execute ["janet"
                    "support/build.janet"] :p))

(put (dyn :rules) "clean" nil)
(phony "clean" []
       (os/execute ["janet"
                    "support/clean.janet"] :p))

# XXX: want better way to remove "build" dep from "test"
(defn remove-dep
  "Remove a dependency from an existing rule. Useful for changing phony
  rules or modifying the dependency graph of existing rules."
  [target dep]
  # from jpm
  (defn- getrules []
    (if-let [rules (dyn :rules)] rules (setdyn :rules @{})))
  # from jpm
  (defn- gettarget [target]
    (def item ((getrules) target))
    (unless item (error (string "No rule for target " target)))
    item)
  #
  (def [deps] (gettarget target))
  (loop [i :down-to [(dec (length deps)) 0]]
    (when (= dep (get deps i))
      (array/remove deps i))))

(remove-dep "test" "build")
