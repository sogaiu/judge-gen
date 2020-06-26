# judge-gen

## Aims

* Make simple testing low-cost and automatable especially during
  exploratory coding when using Janet.

  > Think: "don't have to create a separate file with specially
  > formatted tests initially"

* Provide a canonical location for illustrative examples to help
  potential users begin to form appropriate mental models.

  > Think: "place a few useful examples of calling a function in a
  > comment block immediately after a function's definition"

## Status

Early stage

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

* Having done some combination of the above things, employ judge-gen
  to transform such code into executable tests.

## Installation

Clone and build:

```
git clone https://github.com/sogaiu/judge-gen
cd judge-gen
jpm deps && jpm build
```

Result should be a `jg(.exe)` binary in the `build` subdirectory.

Make the binary available on `PATH` somehow, e.g. make a symlink to
the created binary from some directory that is already on `PATH`.

## Usage

Prepend a source file to tests found within it (intention is that the
result should then be executable for testing):

```
jg -p -n 0 <source-file> > file-with-tests.janet
```

Just produce tests (result meant to be used via a REPL):

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
jg -l 90 <source-file>
```

There is also preliminary support for use from Emacs (see the `emacs`
subdirectory).  I've also had some success with VSCode and Neovim
integration and hope to have that available soonish.

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

## More Details

See the beginning of [jg.janet](judge-gen/jg.janet).
