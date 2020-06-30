# judge-gen

## Aims

* Make simple testing low-cost and automatable especially during
  exploratory coding when using Janet.

  > Think: "don't have to create a separate file with specially
  > formatted tests initially"

* Provide a canonical location for illustrative examples to help
  potential users form appropriate mental models.

  > Think: "place a few useful examples of calling a function in a
  > comment block immediately after a function's definition"

## Status and Warnings

This is an early stage project.  The author uses it in a number of
projects though.

_WARNING_: The automation portion of this project involves generating
test files from source files.  In order to keep these up-to-date, the
generation process erases the directory that files are copied /
generated into (as well as the content of the directory).

There are two related things to be aware of:

* This directory has a default name of `judge` and lives within one's
  project directory.  If that name is a problem (e.g. your project is
  already using it or wants to use it), there is a way to select a
  different name.

* The generated test files all start with the prefix `judge-`.  A file
  that starts with that prefix is treated as a test file.  The prefix
  may be configured to be something else though, so if any of your
  source files uses that prefix, please choose a prefix that is not
  used by any of your source files.

See the `jg-verdict` portion of the Usage section for the command line
parameters that enable selection of these things.

Finally, please don't use this tool without source control or
something that provides adequate protection from data loss.  Thanks!

## How

* Within `comment` blocks, put expressions / forms to be tested along
  with brief records of expected values.

  * After placing an expression to test in a comment block, on the
    line immediately following the expression, put an appropriately
    formatted single line comment containing the expected return
    value, e.g.:

    ```
    (- 1 1)
    # => 0
    ```

    Note the use of `=>`.

  * Instead of a single line comment, a long-string may be used to
    express an expected return value.  This makes it possible to format
    the expected return value for easier human recognition, e.g.:

    ```
    (put (table :alpha "first" :beta "second") :gamma "third")
    `
    {:alpha "first"
     :beta "second"
     :gamma "third"}
    `
    ```

  * Expected errors may also be expressed using an appropriate single
    line comment, e.g.:

    ```
    (error "this is an error")
    # !
    ```

    Note the use of `!`.

* Having done some combination of the above things, employ the
  `jg(.exe)` binary to transform such code into executable tests.

* More conveniently, run a single command to have your directory of
  source files transformed into executable tests, run them, and see a
  summary.  This can be done via phony target(s) in `project.janet`
  (e.g. by running `jpm run judge`) or via the `jg-verdict(.exe)`
  executable.  See the Usage section below for details.

## Installation

Clone and build:

```
git clone https://github.com/sogaiu/judge-gen
cd judge-gen
jpm deps && jpm build
```

Success should yield the `jg(.exe)` and `jg-verdict(.exe)` binaries in
the `build` subdirectory.

Make the binaries available on `PATH` somehow, e.g. make symlinks to
the created binaries from some directory that is already on `PATH`.

Alternatively, `jpm install` should place `jg(.exe)` and
`jg-verdict(.exe)` in janet's `binpath`.

## Usage

### phony target(s) in project.janet

One way to have comment block tests for source files generated, run,
and summarized via the invocation of a single command, is to add phony
target(s) to `project.janet`.

Here is a sample with an explanation following:
```clojure
# (1)
(import ./vendor/path)

(declare-project
 :name "janet-peg-grammar"
 :url "https://github.com/sogaiu/janet-peg-grammar"
 :repo "git+https://github.com/sogaiu/janet-peg-grammar.git")

# (2)
(def proj-root
  (os/cwd))

# (3)
(def src-root
  (path/join proj-root "janet-peg-grammar"))

(declare-source
 :source [(path/join src-root "grammar.janet")])

(phony "netrepl" []
       (os/execute
        ["janet" "-e" (string "(os/cd \"" src-root "\")"
                              "(import spork/netrepl)"
                              "(netrepl/server)")] :p))

# (4)
(phony "judge" ["build"]
       (os/execute ["jg-verdict"
                    "-p" proj-root
                    "-s" src-root] :p))
```

The main point of interest is (4).  This makes it possible to run the
comment block tests via an invocation like:

```
jpm run judge
```

(2) and (3) exist so that (4) gets the information it needs to run.

(1) exists so that path manipulation can be done conveniently and in a
platform-independent manner.

It's also possible to integrate with `jpm test`, by appropriately
adding something like the following to `project.janet`:

```clojure
# (5)
# XXX: the following can be used to arrange for the overriding of the
#      "test" phony target
(put (dyn :rules) "test" nil)
# (6)
(phony "test" ["build"]
       (os/execute ["jg-verdict"
                    "-p" proj-root
                    "-s" src-root] :p))
```

Adding (6) makes it so that `jpm test` will cause comment block tests
to run.

If (5) is also added, only the comment block tests will run when `jpm
test` is invoked.

Not adding (5) means that whatever `jpm test` did before will ALSO be
done in addition to running comment-block tests.

### jg

Prepend a source file to tests found within it (intention is that the
result should then be executable for testing):

```
jg --prepend --number 0 <source-file> > file-with-tests.janet
```

or:

```
jg -p -n 0 <source-file> > file-with-tests.janet
```

Just produce tests (result meant to be used via a REPL where
expressions in the source file have already been evaluated):

```
jg -n 0 <source-file>
```

Just produce tests for the first two comment blocks in the file:

```
jg -n 2 <source-file>
```

Start looking for tests near line `90`, ignoring comment blocks that
occur before that line:

```
jg --line 90 <source-file>
```

or:

```
jg -l 90 <source-file>
```

To get some brief help:

```
$ jg -h
usage: jg [option] ...

Rewrite comment blocks as tests.

 Optional:
 -d, --debug                                 Debug output.
 -h, --help                                  Show this help message.
 -l, --line VALUE=1                          Line number to start search near, 1-based.
 -n, --number VALUE=1                        Number of comment blocks to select, 0 for all remaining.
 -o, --output VALUE=                         Path to store output to.
 -p, --prepend                               Prepend original source code.
 -v, --version                               Version output.
```

### jg-verdict

Generate tests, run them, and see a report:

```
jg-verdict \
  --project-root <full-path-to-proj-dir> \
  --source-root <full-path-to-source-dir>
```

or:

```
jg-verdict \
  -p <full-path-to-proj-dir> \
  -s <full-path-to-source-dir>
```

Use a name other than "judge" to generate tests into:

```
jg-verdict \
  --judge-dir-name "my-temporary-dir" \
  --project-root <full-path-to-proj-dir> \
  --source-root <full-path-to-source-dir>
```

or:

```
jg-verdict \
  -j "my-temporary-dir" \
  -p <full-path-to-proj-dir> \
  -s <full-path-to-source-dir>
```

Use a prefix other than "judge-" for test files:

```
jg-verdict \
  --judge-file-prefix "test-" \
  --project-root <full-path-to-proj-dir> \
  --source-root <full-path-to-source-dir>
```

or:

```
jg-verdict \
  -f "test-" \
  -p <full-path-to-proj-dir> \
  -s <full-path-to-source-dir>
```

To get some brief help:

```
$ jg-verdict -h
usage: jg-verdict [option] ...

Comment block test runner.

 Optional:
 -d, --debug                                 Debug output.
 -h, --help                                  Show this help message.
 -j, --judge-dir-name VALUE=judge            Name of judge directory.
 -f, --judge-file-prefix VALUE=judge-        Prefix for test files.
 -p, --project-root VALUE                    Project root.
 -s, --source-root VALUE                     Source root.
 -v, --version                               Version output.
```

### Editor Support

There is also preliminary support for use from Emacs (see the
[emacs](judge-gen/emacs) subdirectory).  I've also had some success
with VSCode and Neovim integration, but am not sure whether it's worth
it overall.

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

## Notes

See [notes.txt](judge-gen/notes.txt).

## Acknowledgements

* andrewchambers - suggestion and explanation
* bakpakin - janet, jpm, etc.
* pepe - discussion, One-Shot Power Util Solver ™ motivation, and naming
* pyrmont - discussion and exploration
* rduplain - bringing to light customization of `jpm test`
* Saikyun - discussion
* srnb@gitlab - suggestion
