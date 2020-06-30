(import ./args-verdict :refresh true)
(import ../vendor/jpm)
(import ../vendor/path)

(defn print-color
  [msg color]
  (let [color-num (match color
                    :black 30
                    :blue 34
                    :cyan 36
                    :green 32
                    :magenta 35
                    :red 31
                    :white 37
                    :yellow 33)]
    (prin (string "\e[" color-num "m"
                  msg
                  "\e[0m"))))

(defn dashes
  [&opt n]
  (default n 60)
  (string/repeat "-" n))

(defn print-dashes
  [&opt n]
  (print (dashes n)))

(defn make-judges
  [dir subdirs judge-root judge-file-prefix]
  (each path (os/dir dir)
    (def fpath (path/join dir path))
    (case (os/stat fpath :mode)
      :directory (do
                   (make-judges fpath (array/push subdirs path)
                                judge-root judge-file-prefix)
                   (array/pop subdirs))
      :file (os/execute
             ["jg"
              "--prepend"
              "--number" "0"
              "--output" (path/join judge-root
                                    ;subdirs
                                    (string
                                     judge-file-prefix path))
              fpath] :p))))

(comment

 (def proj-root
   (path/join (os/getenv "HOME")
              "src" "judge-gen"))

 (def judge-root
   (path/join proj-root "judge"))

 (def src-root
   (path/join proj-root "judge-gen"))

 #(os/mkdir judge-root)

 #(make-judges src-root @[] judge-root "judge-")

 )

(defn judge
  [dir results judge-root judge-file-prefix]
  (each path (os/dir dir)
    (def fpath (path/join dir path))
    (case (os/stat fpath :mode)
      :directory (judge fpath results judge-root judge-file-prefix)
      :file (when (and (string/has-prefix? judge-file-prefix path)
                       (string/has-suffix? ".janet" fpath))
              # XXX
              (print path)
              (def command (string/join
                            [(dyn :executable "janet")
                             "-e"
                             (string "'(os/cd \"" judge-root "\")'")
                             "-e"
                             (string "'(dofile \"" fpath "\")'")] # avoid `main`
                            " "))
              (put results fpath (jpm/pslurp command))))))

(defn summarize
  [results]
  (when (empty? results)
    # XXX: somehow messes things up?
    #(print "No test results")
    (break))
  (var total-tests 0)
  (var total-passed 0)
  (def failures @{})
  (eachp [fpath details] results
         (def name (path/basename fpath))
         (when (not= "" details) # XXX: sign of a problem?
           (def p (parser/new))
           # XXX: error-handling...
           (parser/consume p details)
           (var passed 0)
           (def test-results (parser/produce p))
           (var num-tests (length test-results))
           (var fails @[])
           (each test-result test-results
             (++ total-tests)
             (def {:passed test-passed} test-result)
             (if test-passed
               (do
                 (++ passed)
                 (++ total-passed))
               (array/push fails test-result)))
           (when (not (empty? fails))
             (put failures fpath fails))))
  (eachp [fpath failed-tests] failures
         (print fpath)
         (each fail failed-tests
           (def {:test-value test-value
                 :name test-name
                 :passed test-passed
                 :test-form test-form} fail)
           (print-color "failed" :red)
           (print ": " test-name)
           (print-color "form" :red)
           (printf ": %M" test-form)
           (print-color "value" :red)
           # XXX: this could use some work...
           (if (< 30 (length (describe test-value)))
             (print ":")
             (prin ": "))
           (printf "%M" test-value)))
  (when (= 0 total-tests)
    (print "No tests found, so no judgements made.")
    (break))
  (if (not= total-passed total-tests)
    (do
      (print-dashes)
        (print-color total-passed :red))
    (print-color total-passed :green))
  (prin " of ")
  (print-color total-tests :green)
  (print " passed")
  (print-dashes)
  (print "all judgements made."))

(comment

 #(summarize @{})

 )

# XXX: consider `(break false)` instead of just `assert`?
(defn handle-one
  [opts]
  (def {:judge-dir-name judge-dir-name
        :judge-file-prefix judge-file-prefix
        :proj-root proj-root
        :src-root src-root
        :version version} opts)
  # XXX: review
  (when version
    (break true))
  (def judge-root
    (path/join proj-root judge-dir-name))
  # check if jg is accessible
  (when (not= 0 (os/shell "jg --version"))
    (eprint "failed to find jg in PATH")
    (break))
  # remove old judge directory
  (print (string "cleaning out: " judge-root))
  (jpm/rm judge-root)
  # XXX
  (print "removed judge dir")
  # copy source files
  (jpm/copy src-root judge-root)
  (print-dashes)
  # create judge files
  (make-judges src-root @[] judge-root judge-file-prefix)
  # judge
  (print "judging...")
  (var results @{})
  (judge judge-root results judge-root judge-file-prefix)
  (print-dashes)
  (print)
  # summarize results
  (summarize results))

(comment

 (def proj-root
   (path/join (os/getenv "HOME")
              "src" "judge-gen"))

 (def src-root
   (path/join proj-root "judge-gen"))

 (comment
  # XXX: this kind of expression isn't handled properly by jg
  (handle-one {:judge-dir-name "judge"
               :judge-file-prefix "judge-"
               :proj-root proj-root
               :src-root src-root})
  )

 )

(defn main
  [& args]
  (when (not (handle-one (args-verdict/parse)))
    (os/exit 1)))
