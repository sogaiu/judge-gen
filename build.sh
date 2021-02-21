#! /bin/sh

cd judge-gen

# concatenate the files together in an appropriate order
cat config.janet \
    path.janet \
    jpm.janet \
    grammar.janet \
    pegs.janet \
    segments.janet \
    rewrite.janet \
    input.janet \
    jg.janet \
    utils.janet \
    jg-runner.janet \
    jg-jpm-test.janet \
    >> ../raw.janet

cd ..

# hack to strip imports
grep -v "^(import" raw.janet > judge-gen.janet

rm raw.janet
