(lang dune 3.3)

(name fm)

(generate_opam_files true)

(source
 (github nyinyithann/favemarks))

(authors "Nyi Nyi Than")

(maintainers "Nyi Nyi Than")

(license ISC)

(documentation "https://github.com/nyinyithann/favemarks")

(package
 (name fm)
 (synopsis "Favemarks: Your favourite bookmarks at your fingertips")
 (description "A command line bookmark manager")
 (depends 
   (ocaml (>= 4.10.0))
   dune
   (core_compat (>= 0.15.0))
   (sqlite3 (>= 5.1.0))
   (ANSITerminal (>= 0.8.5))
   (re (>= 1.10.4))
   (textutils (>= 0.15.0))
   (yojson (>= 2.0.1))
   (tyxml (>= 4.5.0))
 ))
