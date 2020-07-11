# jg-verdict

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
