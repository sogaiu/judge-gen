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

 (phony "judge" ["build"]
        # XXX: platform-specific
        (when (not= 0 (os/shell "which jg"))
          (eprint "jg not found in PATH")
          (break))
        # doesn't work well if there is already a "judge" directory
        (print (string "Cleaning out: " judge-root))
        (rm judge-root)
        #
        (copy (path/join src-root "") judge-root)
        # XXX: make a recursive traversal version
        (each path (os/dir src-root)
          (def fpath (path/join src-root path))
          (case (os/stat fpath :mode)
            :file (os/execute ["jg"
                               "--prepend"
                               "--number" "0"
                               "--output" (path/join judge-root
                                                     (string
                                                      judge-file-prefix path))
                               fpath] :p)
            # XXX: implement this part
            :directory (print "Sorry, no recursion yet.")))
        (print "Judging...")
        # XXX: adapted from jpm's "test" phony target
        (defn print-dashes [] (print (string/repeat "-" 60)))
        (defn dodir
          [dir]
          (each sub (sort (os/dir dir))
            (def ndir (path/join dir sub))
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

)
