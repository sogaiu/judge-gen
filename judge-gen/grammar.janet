# adapted from:
#   https://janet-lang.org/docs/syntax.html

# approximation of janet's grammar
(def grammar/janet
  ~{:main :root
    #
    :root (any :root0)
    #
    :root0 (choice :value :comment)
    #
    :value (sequence
            (any (choice :s :readermac))
            :raw-value
            (any :s))
    #
    :readermac (set "',;|~")
    #
    :raw-value (choice
                :constant :number
                :symbol :keyword
                :string :buffer
                :long-string :long-buffer
                :parray :barray
                :ptuple :btuple
                :struct :table)
    #
    :comment (sequence (any :s)
                       "#"
                       (any (if-not (choice "\n" -1) 1))
                       (any :s))
    #
    :constant (choice "false" "nil" "true")
    #
    :number (drop (cmt
                   (capture :token)
                   ,scan-number))
    #
    :token (some :symchars)
    #
    :symchars (choice
               (range "09" "AZ" "az" "\x80\xFF")
               # XXX: see parse.c's is_symbol_char which mentions:
               #
               #        \, ~, and |
               #
               #      but tools/symcharsgen.c does not...
               (set "!$%&*+-./:<?=>@^_"))
    #
    :keyword (sequence ":" (any :symchars))
    #
    :string :bytes
    #
    :bytes (sequence "\""
                     (any (choice :escape (if-not "\"" 1)))
                     "\"")
    #
    :escape (sequence "\\"
                      (choice (set "0efnrtvz\"\\")
                              (sequence "x" [2 :hex])
                              (sequence "u" [4 :d])
                              (sequence "U" [6 :d])
                              (error (constant "bad escape"))))
    #
    :hex (range "09" "af" "AF")
    #
    :buffer (sequence "@" :bytes)
    #
    :long-string :long-bytes
    #
    :long-bytes {:main (drop (sequence
                              :open
                              (any (if-not :close 1))
                              :close))
                 :open (capture :delim :n)
                 :delim (some "`")
                 :close (cmt (sequence
                              (not (look -1 "`"))
                              (backref :n)
                              (capture :delim))
                             ,=)}
    #
    :long-buffer (sequence "@" :long-bytes)
    #
    :parray (sequence "@" :ptuple)
    #
    :ptuple (sequence "("
                      :root
                      (choice ")" (error "")))
    #
    :barray (sequence "@" :btuple)
    #
    :btuple (sequence "["
                      :root
                      (choice "]" (error "")))
    # XXX: constraining to an even number of values doesn't seem
    #      worth the work when considering that comments can also
    #      appear in a variety of locations...
    :struct (sequence "{"
                      :root
                      (choice "}" (error "")))
    #
    :table (sequence "@" :struct)
    #
    :symbol :token
    })

(comment

  (try
    (peg/match grammar/janet "\"\\u001\"")
    ([e] e))
  # => "bad escape"

  (peg/match grammar/janet "\"\\u0001\"")
  # => @[]

  (peg/match grammar/janet "(def a 1)")
  # => @[]

  (try
    (peg/match grammar/janet "[:a :b)")
    ([e] e))
  # => "match error at line 1, column 7"

  (peg/match grammar/janet "(def a # hi\n 1)")
  # => @[]

  (try
    (peg/match grammar/janet "(def a # hi 1)")
    ([e] e))
  # => "match error at line 1, column 15"

  (peg/match grammar/janet "[1]")
  # => @[]

  (peg/match grammar/janet "# hello")
  # => @[]

  (peg/match grammar/janet "``hello``")
  # => @[]

  (peg/match grammar/janet "8")
  # => @[]

  (peg/match grammar/janet "[:a :b]")
  # => @[]

  (peg/match grammar/janet "[:a :b] 1")
  # => @[]

 )
