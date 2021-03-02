(defn utils/print-color
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

(defn utils/dashes
  [&opt n]
  (default n 60)
  (string/repeat "-" n))

(defn utils/print-dashes
  [&opt n]
  (print (utils/dashes n)))

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
                  (all |(peg/find '(range "09" "af" "AF")
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

  (utils/no-ext "test/judge-gen.janet")
  # => "test/judge-gen"

  )
