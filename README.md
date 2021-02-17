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
  with brief records of expected values:

  ```
  (comment

    (- 1 1)
    # => 0

  )
  ```

  Note the use of a single line comment and `=>` to express an
  expected return value.

  See [Tips and Tweaking](doc/tips-and-tweaking.md) for more details.

* Once some setup steps are followed, tests can be run by: `jpm test`

## Setup Steps

Some files and directories need to be prepared in one's project.  See
the end of this section for the brief version.

### Details

One such arrangement relative to the project root directory is:

1. `test/runner.janet` - test runner and reporter
2. `support` - a directory for judge-gen's code
3. `examples` - a directory for files that get turned into test files

`test/runner.janet` needs to be minimally configured to know where the
directory for 3. is.  That can be done by modifying the `def` form for
`src-root`.  The `runner.janet` file in this repository's `test`
subdirectory can be used as a template.

`support` can be populated by copying files from this repository's
`judge-gen` subdirectory.

`examples` is the subdirectory to house files that get turned into
tests.  It can be the directory containing the project's source (and
doesn't need to be named `examples`).  It's most likely to work if
this is a direct subdirectory of the project's root directory.

See [Tips and Tweaking](doc/tips-and-tweaking.md) for more information
about configuration.

### Specific Steps

1. Create `test/runner.janet` based on the one in this repository.
2. Edit the contained `def` form for `src-root` to point at `examples`
   (or other appropriate location as discussed above).
3. Create the `support` subdirectory and copy the content of this
   repository's `judge-gen` subdirectory (so one of the files in
   the `support` will be `jg.janet`, for example).
4. Create the `examples` directory depending on what was done in step 2.

## Usage

To run the tests and get a report: `jpm test`

## Sample Configurations

This repository can serve as an example, but
[margaret](https://gitlab.com/sogaiu/margaret) is another example.

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
