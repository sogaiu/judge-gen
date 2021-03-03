(defn display/print-color
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

(defn display/dashes
  [&opt n]
  (default n 60)
  (string/repeat "-" n))

(defn display/print-dashes
  [&opt n]
  (print (display/dashes n)))
