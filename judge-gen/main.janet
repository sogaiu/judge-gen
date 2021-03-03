(import ./path :prefix "")
(import ./runner :prefix "")
(import ./utils :prefix "")

# from the perspective of `jpm test`
(def proj-root
  (path/abspath "."))

(defn base-no-ext
  [file-path]
  (when file-path
    (when-let [base (path/basename file-path)
               rev (string/reverse base)
               dot (string/find "." rev)]
      (string/reverse (string/slice rev (inc dot))))))

(comment

  (base-no-ext "test/judge-gen.janet")
  # => "judge-gen"

  )

(defn deduce-src-root
  []
  (let [current-file (dyn :current-file)]
    (assert current-file
            ":current-file is nil")
    (let [cand-name (base-no-ext current-file)]
      (assert (and cand-name
                   (not= cand-name ""))
              (string "failed to deduce name for: "
                      current-file))
      cand-name)))

(defn suffix-for-judge-dir-name
  [runner-path]
  (assert (string/has-prefix? "test/" runner-path)
          (string "path must start with `test/`: " runner-path))
  (let [path-no-ext (utils/no-ext runner-path)]
    (assert (and path-no-ext
                 (not= path-no-ext ""))
            (string "failed to deduce name for: "
                    runner-path))
    (def rel-to-test
      (string/slice path-no-ext (length "test/")))
    (def comma-escaped
      (string/replace-all "," ",," rel-to-test))
    (def all-escaped
      (string/replace-all "/" "," comma-escaped))
    all-escaped))

(defn deduce-judge-dir-name
  []
  (let [current-file (dyn :current-file)]
    (assert current-file
            ":current-file is nil")
    (let [suffix (suffix-for-judge-dir-name current-file)]
      (assert suffix
              (string "failed to determine suffix for: "
                      current-file))
      (string ".judge_" suffix))))

# XXX: hack to prevent from running when testing
(when (nil? (dyn :judge-gen/test-out))
  (let [all-passed
        (runner/handle-one
          {:judge-dir-name (deduce-judge-dir-name)
           :proj-root proj-root
           :src-root (deduce-src-root)})]
    (when (not all-passed)
      (os/exit 1))))
