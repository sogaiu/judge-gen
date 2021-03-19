(defn validate/valid-code?
  [form-bytes]
  (let [p (parser/new)
        p-len (parser/consume p form-bytes)]
    (when (parser/error p)
      (break false))
    (parser/eof p)
    (and (= (length form-bytes) p-len)
         (nil? (parser/error p)))))

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
