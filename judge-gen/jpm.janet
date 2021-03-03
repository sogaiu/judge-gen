# some bits from jpm

### Copyright 2019 © Calvin Rose

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

(def- jpm/is-win (= (os/which) :windows))
(def- jpm/is-mac (= (os/which) :macos))
(def- jpm/sep (if jpm/is-win "\\" "/"))

(defn jpm/rm
  "Remove a directory and all sub directories."
  [path]
  (case (os/lstat path :mode)
    :directory (do
      (each subpath (os/dir path)
        (jpm/rm (string path jpm/sep subpath)))
      (os/rmdir path))
    nil nil # do nothing if file does not exist
    # Default, try to remove
    (os/rm path)))

(def- jpm/path-splitter
  "split paths on / and \\."
  (peg/compile ~(any (* '(any (if-not (set `\/`) 1)) (+ (set `\/`) -1)))))

(defn jpm/shell
  "Do a shell command"
  [& args]
  (if (dyn :verbose)
    (print ;(interpose " " args)))
  (os/execute args :px))

(defn jpm/copy
  "Copy a file or directory recursively from one location to another."
  [src dest]
  (print "copying " src " to " dest "...")
  (if jpm/is-win
    (let [end (last (peg/match jpm/path-splitter src))
          isdir (= (os/stat src :mode) :directory)]
      (jpm/shell "C:\\Windows\\System32\\xcopy.exe"
                 (string/replace "/" "\\" src)
                 (string/replace "/" "\\" (if isdir (string dest "\\" end) dest))
                 "/y" "/s" "/e" "/i"))
    (jpm/shell "cp" "-rf" src dest)))

(defn jpm/pslurp
  [cmd]
  (string/trim (with [f (file/popen cmd)]
                     (:read f :all))))

(defn jpm/create-dirs
  "Create all directories needed for a file (mkdir -p)."
  [dest]
  (def segs (peg/match jpm/path-splitter dest))
  (for i 1 (length segs)
    (def path (string/join (slice segs 0 i) jpm/sep))
    (unless (empty? path) (os/mkdir path))))

