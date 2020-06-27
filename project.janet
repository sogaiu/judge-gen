# XXX: begin -- things from jpm

(def- is-win (= (os/which) :windows))
(def- is-mac (= (os/which) :macos))
(def- sep (if is-win "\\" "/"))

# XXX: end -- things from jpm

(def proj-root
  (os/cwd))

(def src-root
  (string proj-root sep "judge-gen"))

(def judge-root
  (string proj-root sep "judge"))

(def judge-file-prefix
  "judge-")

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
  :entry (string src-root sep "jg.janet"))

(phony "netrepl" []
       (os/execute
        ["janet" "-e" (string "(os/cd \"" src-root "\")"
``
         (import spork/netrepl)
         (netrepl/server)
``      )] :p))

(phony "judge" ["build"]
       # XXX: platform-specific
       (when (not= 0 (os/shell "which jg"))
         (eprint "jg not found in PATH")
         (break))
       # doesn't work well if there is already a "judge" directory
       (print (string "Cleaning out: " judge-root))
       (rm judge-root)
       #
       # XXX: work on platform independent version at some point?
       #      windows doesn't have cp
       (when (not (os/stat judge-root))
         (print (string "Copying source tree to: " judge-root))
         (os/execute
          ["cp" "-p" "-R" (string src-root sep) judge-root] :p))
       # XXX: make a recursive traversal version
       (each path (os/dir src-root)
         (def fpath (string src-root sep path))
         (case (os/stat fpath :mode)
           :file (os/execute ["jg"
                              "--prepend"
                              "--number" "0"
                              "--output" (string judge-root sep
                                                 judge-file-prefix path)
                              fpath] :p)
           # XXX: implement this part
           :directory (print "Sorry, no recursion yet.")))
       (print "Judging...")
       # XXX: adapted from jpm's "test" phony target
       (defn print-dashes [] (print (string/repeat "-" 60)))
       (defn dodir
         [dir]
         (each sub (sort (os/dir dir))
           (def ndir (string dir sep sub))
           (case (os/stat ndir :mode)
             :directory (dodir ndir)
             :file (when (and (string/has-prefix? judge-file-prefix sub)
                              (string/has-suffix? ".janet" ndir))
                     (print-dashes)
                     (print "Running " ndir " ...")
                     (def result
                       (os/execute [(dyn :executable "janet")
                                    "-e" (string "(os/cd "
                                                 "\"" judge-root "\""
                                                 ")")
                                    ndir] :p))))))
       (dodir judge-root)
       (print-dashes)
       (print "All judgements made."))
