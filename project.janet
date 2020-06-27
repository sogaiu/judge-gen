# XXX: consider whether the "judge" directory should live under /tmp
#      might be safer than removing something within the project directory

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
        (prin "looking for jg... ")
        (flush)
        # XXX: platform-specific
        (when (not= 0 (os/shell "which jg"))
          (eprint "not found in PATH")
          (break))
        # remove old judge directory
        (print (string "cleaning out: " judge-root))
        (rm judge-root)
        # copy source files
        (copy (path/join src-root "") judge-root)
        # create judge files
        (defn make-judges
          [dir rels]
          (each path (os/dir dir)
            (def fpath (path/join dir path))
            (case (os/stat fpath :mode)
              :directory (do
                           (make-judges fpath (array/push rels path))
                           (array/pop rels))
              :file (os/execute
                     ["jg"
                      "--prepend"
                      "--number" "0"
                      "--output" (path/join judge-root
                                            ;rels
                                            (string
                                             judge-file-prefix path))
                                 fpath] :p))))
        (make-judges src-root @[])
        # judge
        (print "judging...")
        (defn print-dashes [] (print (string/repeat "-" 60)))
        (defn judge
          [dir]
          (each path (os/dir dir)
            (def fpath (path/join dir path))
            (case (os/stat fpath :mode)
              :directory (judge fpath)
              :file (when (and (string/has-prefix? judge-file-prefix path)
                               (string/has-suffix? ".janet" fpath))
                      (print-dashes)
                      (print path)
                      (os/execute [(dyn :executable "janet")
                                   "-e" (string "(os/cd "
                                                "\"" judge-root "\""
                                                ")")
                                   fpath] :p)))))
        (judge judge-root)
        (print-dashes)
        (print "all judgements made."))

)
