(defn validate/valid-code?
  [form-bytes]
  (let [p (parser/new)
        p-len (parser/consume p form-bytes)]
    (when (parser/error p)
      (break false))
    (let [_ (parser/eof p)
          p-err (parser/error p)]
      (and (= (length form-bytes) p-len)
           (nil? p-err)))))

(comment

  (validate/valid-code? "true")
  # => true

  (validate/valid-code? "(")
  # => false

  (validate/valid-code? "()")
  # => true

  (validate/valid-code? "(]")
  # => false

  )
