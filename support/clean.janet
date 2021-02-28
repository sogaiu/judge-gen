(import ./common)

# relative to the project root
(def out-path
  (string "./" common/out-path))

(when (os/stat out-path)
  (os/rm out-path))
