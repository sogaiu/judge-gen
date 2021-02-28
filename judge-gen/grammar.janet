# adapted from:
#   https://janet-lang.org/docs/syntax.html

# approximation of janet's grammar
(def grammar/jg
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
    (peg/match grammar/jg "\"\\u001\"")
    ([e] e))
  # => "bad escape"

  (peg/match grammar/jg "\"\\u0001\"")
  # => @[]

  (peg/match grammar/jg "(def a 1)")
  # => @[]

  (try
    (peg/match grammar/jg "[:a :b)")
    ([e] e))
  # => "match error at line 1, column 7"

  (peg/match grammar/jg "(def a # hi\n 1)")
  # => @[]

  (try
    (peg/match grammar/jg "(def a # hi 1)")
    ([e] e))
  # => "match error at line 1, column 15"

  (peg/match grammar/jg "[1]")
  # => @[]

  (peg/match grammar/jg "# hello")
  # => @[]

  (peg/match grammar/jg "``hello``")
  # => @[]

  (peg/match grammar/jg "8")
  # => @[]

  (peg/match grammar/jg "[:a :b]")
  # => @[]

  (peg/match grammar/jg "[:a :b] 1")
  # => @[]

 )

# make a version of jg that matches a single form
(def grammar/jg-one
  (->
   # jg is a struct, need something mutable
   (table ;(kvs grammar/jg))
   # just recognize one form
   (put :main :root0)
   # tried using a table with a peg but had a problem, so use a struct
   table/to-struct))

(comment

  (try
    (peg/match grammar/jg-one "\"\\u001\"")
    ([e] e))
  # => "bad escape"

  (peg/match grammar/jg-one "\"\\u0001\"")
  # => @[]

  (peg/match grammar/jg-one "(def a 1)")
  # => @[]

  (try
    (peg/match grammar/jg-one "[:a :b)")
    ([e] e))
  # => "match error at line 1, column 7"

  (peg/match grammar/jg-one "(def a # hi\n 1)")
  # => @[]

  (try
    (peg/match grammar/jg-one "(def a # hi 1)")
    ([e] e))
  # => "match error at line 1, column 15"

  (peg/match grammar/jg-one "[1]")
  # => @[]

  (peg/match grammar/jg-one "# hello")
  # => @[]

  (peg/match grammar/jg-one "``hello``")
  # => @[]

  (peg/match grammar/jg-one "8")
  # => @[]

  (peg/match grammar/jg-one "[:a :b]")
  # => @[]

  (peg/match grammar/jg-one "[:a :b] 1")
  # => @[]

 )

# make a capturing version of jg
(def grammar/jg-capture
  (->
   # jg is a struct, need something mutable
   (table ;(kvs grammar/jg))
   # capture recognized bits
   (put :main '(capture :root))
   # tried using a table with a peg but had a problem, so use a struct
   table/to-struct))

(comment

  (peg/match grammar/jg-capture "nil")
  # => @["nil"]

  (peg/match grammar/jg-capture "true")
  # => @["true"]

  (peg/match grammar/jg-capture "false")
  # => @["false"]

  (peg/match grammar/jg-capture "symbol")
  # => @["symbol"]

  (peg/match grammar/jg-capture "kebab-case-symbol")
  # => @["kebab-case-symbol"]

  (peg/match grammar/jg-capture "snake_case_symbol")
  # => @["snake_case_symbol"]

  (peg/match grammar/jg-capture "my-module/my-function")
  # => @["my-module/my-function"]

  (peg/match grammar/jg-capture "*****")
  # => @["*****"]

  (peg/match grammar/jg-capture "!%$^*__--__._+++===~-crazy-symbol")
  # => @["!%$^*__--__._+++===~-crazy-symbol"]

  (peg/match grammar/jg-capture "*global-var*")
  # => @["*global-var*"]

  (peg/match grammar/jg-capture "你好")
  # => @["\xE4\xBD\xA0\xE5\xA5\xBD"]

  (peg/match grammar/jg-capture ":keyword")
  # => @[":keyword"]

  (peg/match grammar/jg-capture ":range")
  # => @[":range"]

  (peg/match grammar/jg-capture ":0x0x0x0")
  # => @[":0x0x0x0"]

  (peg/match grammar/jg-capture ":a-keyword")
  # => @[":a-keyword"]

  (peg/match grammar/jg-capture "::")
  # => @["::"]

  (peg/match grammar/jg-capture ":")
  # => @[":"]

  (peg/match grammar/jg-capture "0")
  # => @["0"]

  (peg/match grammar/jg-capture "12")
  # => @["12"]

  (peg/match grammar/jg-capture "-65912")
  # => @["-65912"]

  (peg/match grammar/jg-capture "1.3e18")
  # => @["1.3e18"]

  (peg/match grammar/jg-capture "-1.3e18")
  # => @["-1.3e18"]

  (peg/match grammar/jg-capture "18r123C")
  # => @["18r123C"]

  (peg/match grammar/jg-capture "11raaa&a")
  # => @["11raaa&a"]

  (peg/match grammar/jg-capture "1_000_000")
  # => @["1_000_000"]

  (peg/match grammar/jg-capture "0xbeef")
  # => @["0xbeef"]

  (try
    (peg/match grammar/jg-capture "\"\\u001\"")
    ([e] e))
  # => "bad escape"

  (peg/match grammar/jg-capture "\"\\u0001\"")
  # => @["\"\\u0001\""]

  (peg/match grammar/jg-capture "\"\\U000008\"")
  # => @["\"\\U000008\""]

  (peg/match grammar/jg-capture "(def a 1)")
  # => @["(def a 1)"]

  (try
    (peg/match grammar/jg-capture "[:a :b)")
    ([e] e))
  # => "match error at line 1, column 7"

  (peg/match grammar/jg-capture "(def a # hi\n 1)")
  # => @["(def a # hi\n 1)"]

  (try
    (peg/match grammar/jg-capture "(def a # hi 1)")
    ([e] e))
  # => "match error at line 1, column 15"

  (peg/match grammar/jg-capture "[1]")
  # => @["[1]"]

  (peg/match grammar/jg-capture "# hello")
  # => @["# hello"]

  (peg/match grammar/jg-capture "``hello``")
  # => @["``hello``"]

  (peg/match grammar/jg-capture "8")
  # => @["8"]

  (peg/match grammar/jg-capture "[:a :b]")
  # => @["[:a :b]"]

  (peg/match grammar/jg-capture "[:a :b] 1")
  # => @["[:a :b] 1"]

  (def sample-source
    (string "# \"my test\"\n"
            "(+ 1 1)\n"
            "# => 2\n"))

  (peg/match grammar/jg-capture sample-source)
  # => @["# \"my test\"\n(+ 1 1)\n# => 2\n"]

  )

# make a version of jg that captures a single form
(def grammar/jg-capture-one
  (->
   # jg is a struct, need something mutable
   (table ;(kvs grammar/jg))
   # capture just one form
   (put :main '(capture :root0))
   # tried using a table with a peg but had a problem, so use a struct
   table/to-struct))

(comment

  (def sample-source
    (string "# \"my test\"\n"
            "(+ 1 1)\n"
            "# => 2\n"))

  (peg/match grammar/jg-capture-one sample-source)
  # => @["# \"my test\"\n"]

  (peg/match grammar/jg-capture-one sample-source 11)
  # => @["\n(+ 1 1)\n"]

  (peg/match grammar/jg-capture-one sample-source 20)
  # => @["# => 2\n"]

  )
