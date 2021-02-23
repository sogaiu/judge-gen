# Configuration

# If non-empty, should be the name of a direct subdirectory of the
# project directory.  Leaving the value as an empty string should lead
# to the name (non-extension portion) of this runner file being used
# to determine which direct subdirectory of the project directory to
# copy source files from.
#
# This takes precendence over the file name if non-empty.
(def src-dir-name
  "")

# If true, janet's built-in linting will be attempted before trying to
# transform source files into test files.  Unfortunately, some valid
# source can fail to lint.
(def lint-source
  false)

# Only change if trying to prevent collision with an existing direct
# subdirectory of the project directory.
(def judge-dir-name
  ".judge")

# Only change if trying to prevent collision with source files that have
# names that begin with "judge-".
(def judge-file-prefix
  "judge-")

# Only change if you really know what you are doing.
#
# Disable "All tests passed." message from `jpm test` if true.  This is
# achieved by making this test runner exit with error code 1.  That
# communicates to `jpm test` that the runner itself has failed.  It is a hack.
#
# Changing this to true may cause some tests in the `test` directory (e.g.
# non-judge-gen tests) to not execute.
(def silence-jpm-test
  false)

# End of Configuration

