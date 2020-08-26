# XXX: useful bits from jpm

(def- is-win (= (os/which) :windows))
(def- is-mac (= (os/which) :macos))
(def- sep (if is-win "\\" "/"))

(defn rm
  "Remove a directory and all sub directories."
  [path]
  (case (os/lstat path :mode)
    :directory (do
      (each subpath (os/dir path)
        (rm (string path sep subpath)))
      (os/rmdir path))
    nil nil # do nothing if file does not exist
    # Default, try to remove
    (os/rm path)))

(def- path-splitter
  "split paths on / and \\."
  (peg/compile ~(any (* '(any (if-not (set `\/`) 1)) (+ (set `\/`) -1)))))

(defn shell
  "Do a shell command"
  [& args]
  (if (dyn :verbose)
    (print ;(interpose " " args)))
  (def res (os/execute args :p))
  (unless (zero? res)
    (error (string "command exited with status " res))))

(defn copy
  "Copy a file or directory recursively from one location to another."
  [src dest]
  (print "copying " src " to " dest "...")
  (if is-win
    (let [end (last (peg/match path-splitter src))
          isdir (= (os/stat src :mode) :directory)]
      (shell "C:\\Windows\\System32\\xcopy.exe"
             (string/replace "/" "\\" src) (string/replace "/" "\\" (if isdir (string dest "\\" end) dest))
             "/y" "/s" "/e" "/i"))
    (shell "cp" "-rf" src dest)))

(defn pslurp
  [cmd]
  (string/trim (with [f (file/popen cmd)]
                     (:read f :all))))

(defn create-dirs
  "Create all directories needed for a file (mkdir -p)."
  [dest]
  (def segs (peg/match path-splitter dest))
  (for i 1 (length segs)
    (def path (string/join (slice segs 0 i) sep))
    (unless (empty? path) (os/mkdir path))))
