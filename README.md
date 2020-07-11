# judge-gen

## Aims

* Make simple testing low-cost and automatable especially during
  exploratory coding when using Janet.

  > Think: "don't have to create a separate file with specially
  > formatted tests initially"

* Push for a canonical location for illustrative examples to help
  potential users form appropriate mental models.

  > Think: "place a few useful examples of calling a function in a
  > comment block immediately after a function's definition"

## Status and Warnings

This is an early stage project.  The author uses it in a number of
projects though.  Be sure to examine the [fine print](doc/warning.md).

## How

* Within `comment` blocks, put expressions / forms to be tested along
  with brief records of expected values.

  * After placing an expression to test in a comment block, on the
    line immediately following the expression, put an appropriately
    formatted single line comment containing the expected return
    value, e.g.:

    ```
    (comment

      (- 1 1)
      # => 0

    )
    ```

    Note the use of `=>`.

  * A long-string (backquote-delimited) placed after an expression may
    also be used to indicate an expected return value.  This makes it
    possible to format the expected return value for easier human
    recognition, e.g.:

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

    More than one expression + expected value info pair can be placed
    in a comment block.  It's also fine to put other forms in the
    comment block that don't have expected value info appearing after
    them, all forms in comment blocks will be included in tests.

* Having done some combination of the above things, to execute tests
  you can:

  * Run a single command to have your directory of source files
    transformed into tests, execute them, and see a summary.  This can
    be done via:

    * A phony target(s) in `project.janet` (e.g. by running `jpm run
      judge` or `jpm test`).  See the Usage section below for details.

    * Manually via the `jg-verdict(.exe)` command line tool.

    * Some other tooling that calls `jg-verdict(.exe)` and/or `jg(.exe)`.

  * Run the tests via a REPL connection by using editor integration.
    See below for some details in the Usage section.

## Installation

Clone and build:

```
git clone https://github.com/sogaiu/judge-gen
cd judge-gen
jpm deps && jpm build
```

Success should yield the [jg](doc/jg.md) and
[jg-verdict](doc/jg-verdict.md) binaries in the `build` subdirectory.

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
platform-independent manner.  (At the moment, it's up to a project's
author to figure out how to do path-handling within `project.janet`.
The way shown here is just one possibility.  There are bits within
`jpm` itself that can help with this, but they are unfortunately
marked private.)

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

### jg-verdict(.exe)

[Command line test runner](doc/jg-verdict.md) -- generate tests, run
them, and display report.  Note that `jg-verdict(.exe)` calls
`jg(.exe)` as part of its operation.

### jg(.exe)

[Command line tool](doc/jg.md) -- create tests based on existing
source code.

### Editor Support

There is also preliminary support for use from Emacs (see the
[emacs](emacs) subdirectory).  I've also had some success with VSCode
and Neovim integration, but am not sure whether it's worth it overall.

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

## Tweaking

[Configuring some names](doc/tweaking.md)

## Notes

See [notes.txt](notes.txt).

## Acknowledgements

* andrewchambers - suggestion and explanation
* bakpakin - janet, jpm, etc.
* pepe - discussion, One-Shot Power Util Solver ™ motivation, and naming
* pyrmont - discussion and exploration
* rduplain - bringing to light customization of `jpm test`
* Saikyun - discussion
* srnb@gitlab - suggestion
