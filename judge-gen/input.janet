(defn input/slurp-input
  [input]
  (var f nil)
  (try
    (if (= input "-")
      (set f stdin)
      (if (os/stat input)
        (set f (file/open input :rb))
        (do
          (eprint "path not found: " input)
          (break nil))))
    ([err]
      (eprintf "slurp-input failed")
      (error err)))
  #
  (var buf nil)
  (defer (file/close f)
    (set buf @"")
    (file/read f :all buf))
  buf)
