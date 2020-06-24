(declare-project
  :name "judge-gen"
  :url "https://github.com/sogaiu/judge-gen"
  :repo "git+https://github.com/sogaiu/judge-gen.git"
  :dependencies [
    "https://github.com/janet-lang/argparse"
    "https://github.com/sogaiu/janet-peg-grammar"
  ])

(declare-executable
  :name "jg"
  :entry "judge-gen.janet")
