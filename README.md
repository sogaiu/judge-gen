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

  One might call the form + expected value comment a "comment block
  test".

  See [Tips and Tweaking](doc/tips-and-tweaking.md) for more details.

* Once some setup steps are followed, tests can be run by: `jpm test`

## Setup Steps

### Basic Description

Copy a specific file to a project's `test` subdirectory.

Edit the file so it knows where the files with "comment block" tests
live.

### Specific Steps

1. Copy the file `test/judge-gen.janet` from this repository to the
   target project's `test` subdirectory.
2. Near the top of the file, change the `def` form for `src-dir-name`
   to have the value `examples` (or other appropriate name).
3. Create the `examples` directory (or other suitable) if it doesn't
   exist already.
4. If the directory in the previous step doesn't have at least
   one file with a comment block test in it, do something about that :)

### The Longer Explanation

A single file (`test/judge-gen.janet`) needs to be copied to a
project's `test` subdirectory and then usually at least one definition
in the file (`src-dir-name`) needs to be changed.

The value for `src-dir-name` represents the name of a subdirectory in
the project's root directory that contains files with "comment block"
tests (as described above).

The aforementioned directory (the one that `src-dir-name` specifies)
needs to exist and have appropriate files in it.

## Usage

To run the tests and get a report: `jpm test`

Add more tests / examples by creating more comment block tests in
files that live in the directory specified by `src-dir-name`.

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
