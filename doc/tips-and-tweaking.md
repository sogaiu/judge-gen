# Tips and Tweaking

## Tips

* Use `[]` instead of `()` in some places to express return values, e.g.

  ```
  # => [:hi 1]
  ```

  not:

  ```
  # => (:hi 1)
  ```

* Express return values that span multiple lines by using long strings

  ```
  (comment

    (put (table :alpha "first" :beta "second") :gamma "third")
    `
    {:alpha "first"
     :beta "second"
     :gamma "third"}
    `

  )
  ```

* Expected errors may also be expressed using an appropriate single
  line comment, e.g.:

  ```
  (error "this is an error")
  # !
  ```

  Note the use of `!`.

* More than one expression + expected value info pair can be placed in
  a comment block.  It's also fine to put other forms in the comment
  block that don't have expected value info appearing after them, all
  forms in comment blocks will be included in tests.

## Tweaking

There are two related things to be aware of:

* The directory housing the tests has a default name of `judge` and
  lives within one's project directory.  If that name is a problem
  (e.g. your project is already using it or wants to use it), there is
  a way to select a different name.

* The generated test files all start with the prefix `judge-`.  A file
  that starts with that prefix is treated as a test file.  The prefix
  may be configured to be something else though, so if any of your
  source files uses that prefix, please choose a prefix that is not
  used by any of your source files.

See [jg-verdict](jg-verdict.md) for the command line parameters that
enable selection of these things.
