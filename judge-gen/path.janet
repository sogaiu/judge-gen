### path.janet
###
### A library for path manipulation.
###
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

#
# Common
#

(def- path/ext-peg
  (peg/compile ~{:back (> -1 (+ (* ($) (set "\\/.")) :back))
                 :main :back}))

(defn path/ext
  "Get the file extension for a path."
  [path]
  (if-let [m (peg/match path/ext-peg path (length path))]
    (let [i (m 0)]
      (if (= (path i) 46)
        (string/slice path (m 0) -1)))))

(defn- path/redef
  "Redef a value, keeping all metadata."
  [from to]
  (setdyn (symbol to) (dyn (symbol from))))

#
# Generating Macros
#

(defmacro- path/decl-sep [pre sep] ~(def ,(symbol pre "/sep") ,sep))
(defmacro- path/decl-delim [pre d] ~(def ,(symbol pre "/delim") ,d))

(defmacro- path/decl-last-sep
  [pre sep]
  ~(def- ,(symbol pre "/last-sep-peg")
    (peg/compile '{:back (> -1 (+ (* ,sep ($)) :back))
                   :main (+ :back (constant 0))})))

(defmacro- path/decl-dirname
  [pre]
  ~(defn ,(symbol pre "/dirname")
     "Gets the directory name of a path."
     [path]
     (if-let [m (peg/match
                  ,(symbol pre "/last-sep-peg")
                  path
                  (length path))]
       (let [[p] m]
         (if (zero? p) "./" (string/slice path 0 p)))
       path)))

(defmacro- path/decl-basename
  [pre]
  ~(defn ,(symbol pre "/basename")
     "Gets the base file name of a path."
     [path]
     (if-let [m (peg/match
                  ,(symbol pre "/last-sep-peg")
                  path
                  (length path))]
       (let [[p] m]
         (string/slice path p -1))
       path)))

(defmacro- path/decl-parts
  [pre sep]
  ~(defn ,(symbol pre "/parts")
     "Split a path into its parts."
     [path]
     (string/split ,sep path)))

(defmacro- path/decl-normalize
  [pre sep sep-pattern lead]
  (defn capture-lead
    [& xs]
    [:lead (xs 0)])
  (def grammar
    ~{:span (some (if-not ,sep-pattern 1))
      :sep (some ,sep-pattern)
      :main (* (? (* (replace ',lead ,capture-lead) (any ,sep-pattern)))
               (? ':span)
               (any (* :sep ':span))
               (? (* :sep (constant ""))))})
  (def peg (peg/compile grammar))
  ~(defn ,(symbol pre "/normalize")
     "Normalize a path. This removes . and .. in the
     path, as well as empty path elements."
     [path]
     (def accum @[])
     (def parts (peg/match ,peg path))
     (var seen 0)
     (var lead nil)
     (each x parts
       (match x
         [:lead what] (set lead what)
         "." nil
         ".." (if (= 0 seen)
                (array/push accum x)
                (do (-- seen) (array/pop accum)))
         (do (++ seen) (array/push accum x))))
     (def ret (string (or lead "") (string/join accum ,sep)))
     (if (= "" ret) "." ret)))

(defmacro- path/decl-join
  [pre sep]
  ~(defn ,(symbol pre "/join")
     "Join path elements together."
     [& els]
     (,(symbol pre "/normalize") (string/join els ,sep))))

(defmacro- path/decl-abspath
  [pre]
  ~(defn ,(symbol pre "/abspath")
     "Coerce a path to be absolute."
     [path]
     (if (,(symbol pre "/abspath?") path)
       (,(symbol pre "/normalize") path)
       (,(symbol pre "/join") (or (dyn :path-cwd) (os/cwd)) path))))

#
# Posix
#

(defn path/posix/abspath?
  "Check if a path is absolute."
  [path]
  (string/has-prefix? "/" path))

(path/redef "path/ext" "path/posix/ext")
(path/decl-sep "path/posix" "/")
(path/decl-delim "path/posix" ":")
(path/decl-last-sep "path/posix" "/")
(path/decl-basename "path/posix")
(path/decl-dirname "path/posix")
(path/decl-parts "path/posix" "/")
(path/decl-normalize "path/posix" "/" "/" "/")
(path/decl-join "path/posix" "/")
(path/decl-abspath "path/posix")

#
# Windows
#

(def- path/abs-pat '(* (? (* (range "AZ" "az") `:`)) `\`))
(def- path/abs-peg (peg/compile path/abs-pat))
(defn path/win32/abspath?
  "Check if a path is absolute."
  [path]
  (not (not (peg/match path/abs-peg path))))

(path/redef "path/ext" "path/win32/ext")
(path/decl-sep "path/win32" "\\")
(path/decl-delim "path/win32" ";")
(path/decl-last-sep "path/win32" "\\")
(path/decl-basename "path/win32")
(path/decl-dirname "path/win32")
(path/decl-parts "path/win32" "\\")
(path/decl-normalize "path/win32" `\` (set `\/`) (* (? (* (range "AZ" "az") `:`)) `\`))
(path/decl-join "path/win32" "\\")
(path/decl-abspath "path/win32")

#
# Satisfy linter
#

(defn path/sep [pre sep] nil)
(defn path/delim [pre d] nil)
(defn path/dirname [pre] nil)
(defn path/basename [pre] nil)
(defn path/parts [pre sep] nil)
(defn path/normalize [pre sep sep-pattern lead] nil)
(defn path/join [pre sep] nil)
(defn path/abspath [pre] nil)
(defn path/abspath? [path] nil)

#
# Specialize for current OS
#

(def- path/syms
  ["ext"
   "sep"
   "delim"
   "basename"
   "dirname"
   "abspath?"
   "abspath"
   "parts"
   "normalize"
   "join"])
(let [pre (if (= :windows (os/which)) "path/win32" "path/posix")]
  (each sym path/syms
    (path/redef (string pre "/" sym) (string "path/" sym))))

