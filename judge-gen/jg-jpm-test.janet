(import ./path :prefix "")
(import ./jg-runner :prefix "")
(import ./config :prefix "")

# from the perspective of `jpm test`
(def proj-root
  (path/abspath "."))

(defn src-root
  [src-dir-name]
  (path/join proj-root src-dir-name))

(jg-runner/handle-one
  {:judge-dir-name judge-dir-name
   :judge-file-prefix judge-file-prefix
   :proj-root proj-root
   :src-root (src-root src-dir-name)})

(when silence-jpm-test
  (os/exit 1))
