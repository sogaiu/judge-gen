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

# Only change if trying to prevent collision with an existing direct
# subdirectory of the project directory.
(def judge-dir-suffix
  "")

# Only change if trying to prevent collision with source files that have
# names that begin with "judge-".
(def judge-file-prefix
  "judge-")

# End of Configuration

