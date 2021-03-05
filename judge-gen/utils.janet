(defn utils/rand-string
  [n]
  (->> (os/cryptorand n)
       (map |(string/format "%02x" $))
       (string/join)))

(comment

  (let [len 8
        res (utils/rand-string len)]
    (truthy? (and (= (length res) (* 2 len))
                  # only uses hex
                  (all |(peg/find '(range "09" "af" "AF") # :h
                                  (string/from-bytes $))
                       res))))
  # => true

  )

(defn utils/no-ext
  [file-path]
  (when file-path
    (when-let [rev (string/reverse file-path)
               dot (string/find "." rev)]
      (string/reverse (string/slice rev (inc dot))))))

(comment

  (utils/no-ext "fun.janet")
  # => "fun"

  (utils/no-ext "/etc/man_db.conf")
  # => "/etc/man_db"

  )
