# jg

Prepend a source file to tests found within it (intention is that the
result should then be executable for testing):

```
jg --prepend <source-file> > file-with-tests.janet
```

or:

```
jg -p <source-file> > file-with-tests.janet
```

Just produce tests (result meant to be used via a REPL where
expressions in the source file have already been evaluated):

```
jg <source-file>
```

Produce tests for comment blocks from the beginning of the file up
through line `90`:

```
jg --line 90 <source-file>
```

or:

```
jg -l 90 <source-file>
```

Start looking for tests near line `90`, but only pick out one comment
block:

```
jg --line 90 --single <source-file>
```

or:

```
jg -l 90 -s <source-file>
```

To get some brief help:

```
$ jg -h
usage: jg [option] ...

Rewrite comment blocks as tests.

 Optional:
 -d, --debug                                 Debug output.
 -f, --format VALUE=jdn                      Output format, jdn or text
 -h, --help                                  Show this help message.
 -l, --line VALUE=0                          1-based cursor location linue number, 0 means no cursor.
 -o, --output VALUE=                         Path to store output to.
 -p, --prepend                               Prepend original source code.
 -s, --single                                Select single comment block or all relevant
 -v, --version                               Version output.
```
