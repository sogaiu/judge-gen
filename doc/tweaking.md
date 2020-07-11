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
