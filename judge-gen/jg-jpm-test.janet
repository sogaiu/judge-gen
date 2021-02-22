(import ./path :prefix "")
(import ./jg-runner :prefix "")
(import ./config :prefix "")

# from the perspective of `jpm test`
(def proj-root
  (path/abspath "."))

(defn src-root
  [src-dir-name]
  (path/join proj-root src-dir-name))

(defn base-no-ext
  [file-path]
  (when file-path
    (when-let [base (path/basename file-path)
               rev (string/reverse base)
               dot (string/find "." rev)]
      (string/reverse (string/slice rev (inc dot))))))

(defn deduce-src-root
  [src-dir-name]
  (when (not= src-dir-name "")
    (break src-dir-name))
  (let [current-file (dyn :current-file)]
    (assert current-file
            "src-dir-name is empty but :current-file is nil")
    (when-let [cand-name (base-no-ext current-file)]
      (assert (and cand-name
                   (not= cand-name ""))
              (string "failed to deduce name for: "
                      current-file))
      cand-name)))

(let [all-passed
      (jg-runner/handle-one
        {:judge-dir-name judge-dir-name
         :judge-file-prefix judge-file-prefix
         :proj-root proj-root
         :src-root (deduce-src-root src-dir-name)})]
  (when (not all-passed)
    (os/exit 1))
  (when silence-jpm-test
    (os/exit 1)))
