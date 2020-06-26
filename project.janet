# XXX: lots of platform-specific path manipulation here...

# XXX: things from jpm
(def- is-win (= (os/which) :windows))
(def- is-mac (= (os/which) :macos))
(def- sep (if is-win "\\" "/"))

(def proj-root
  (os/cwd))

(def src-root
  (string proj-root sep "judge-gen"))

(def judge-root
  (string proj-root sep "judge"))

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

# XXX: jg needs to be in PATH
(phony "judge" ["build"]
       (defn print-dashes
         []
         (print (string/repeat "-" 60)))
       # XXX: work on platform independent version at some point?
       #      macos' cp doesn't support the necessary options and
       #      windows doesn't have cp
       # XXX: doesn't work well if there is already a "judge" directory
       (when (not (os/stat judge-root))
         (print (string "Creating symlink mirror of source at: "
                        judge-root))
         (os/execute
          ["cp" "--archive" "--symbolic-link"
           (string src-root sep) judge-root] :p))
       # XXX: make a recursive traversal version
       (each path (os/dir src-root)
         (def fpath (string src-root sep path))
         (case (os/stat fpath :mode)
           :file (os/execute ["jg"
                              "--prepend"
                              "--number" "0"
                              "--output" (string judge-root sep "judge-" path)
                              fpath] :p)
           :directory (print "Sorry, no recursion yet.")))
       (print "Judging...")
       # XXX: adapted from jpm's "test" phony target
       (defn dodir
         [dir]
         (each sub (sort (os/dir dir))
           (def ndir (string dir sep sub))
           (case (os/lstat ndir :mode)
             :directory (dodir ndir)
             :file (when (string/has-suffix? ".janet" ndir)
                     (print-dashes)
                     (print "Running " ndir " ...")
                     (def result
                       (os/execute [(dyn :executable "janet")
                                    "-e" (string "(os/cd "
                                                 "\"" judge-root "\""
                                                 ")")
                                    ndir] :p)))
             # XXX: kind of a hack and limiting, but possibly worth it
             #      could decide whether test according to naming convention...
             :link (print "Skipping non-test " ndir))))
       (dodir judge-root)
       (print-dashes)
       (print "All judgements made."))
