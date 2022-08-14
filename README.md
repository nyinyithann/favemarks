# ⚡︎ Favemarks
<p align="center">Favemarks is a simple command-line bookmark manager.</p>

![image](/docs/main.png)
## Installation
Favemarks is tested on MacOS and Ubuntu. Windows is not supported 😎.<br/>
Please run the following script to install it. You will be asked to provide admin password to actually install it.
```bash
curl -fsSL https://github.com/nyinyithann/favemarks/raw/main/script/install.sh | bash
```
## Getting Started
1. After installing Favemarks, you first need to create a database to store bookmarks.<br/>**Please note that the path must be absolute.**
```bash
 $ fm db-new -path "/path/to/favemarks.db"
 ```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; If you run the above command successfully, you would see something like this.<br/> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; An SQlite db with a table called 'bookmarks' is created.<br/>
![Image](/docs/db-new-command.png)

2. You would now start using Favemarks with the following command.
```bash
 $ fm ls
``` 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Initally you would see a blank table with menus, and if you add some records, you would see something like this.<br/>

**NOTE**<br/>
_If you don't see the below screen after running `fm ls` command. You might probably need to install SQlite to your machine. Favemarks uses SQlite to manage the data._

_For Ubuntu user, please run  `sodo apt install sqlite3`._<br/>
_For Mac use, please run `brew install sqlite3`._

![Image](/docs/fmls.png)
- Press `a` to add a new record.
- Press `u` to update and existing record.
- Press `d` to delete a record.
- Press `s` to search records.
- Press `l` to list all records.
- Press `o` to open Urls in browser.
- Press `c` to display Configuration values.
- Press `t` to display all tags saved in the database.
- Press `e` to export records as json, markdown, or html file.
- Press `j` to got to next page.
- Press `k` to go to previous page.
- Press `q` to quit.

## Commands 
You could check all the available commands with 
```bash
 $ fm --help
```
```bash 
Your favourite bookmarks at your fingertips

  fm SUBCOMMAND

=== subcommands ===

  add                        . add a bookmark
  config-info                . show config info
  config-set                 . set config
  db-new                     . create a new database
  db-switch                  . switch to another database
  ls                         . list bookmarks
  search                     . search bookmarks
  tags                       . show all tags
  version                    . print version information
  help                       . explain a given subcommand (perhaps recursively)
```
You could set 2 config values - `page size` and `browser` if you use Mac. On Linux, only page size can be configured, and the default browser will be used to open links. Default value of `page size` is `12` and `browser` is `Chrome`.
```bash
$ fm config-set

» Enter page size between 1 and 20 inclusive (empty to skip): 10
✅  Successfully saved

» Enter a browser name (Chrome, Safari, Edge, Firefox, Brave) (empty to skip): Chrome
✅  Successfully saved
```
You can add a new record with `fm add`
```bash
$ fm add -url "https://dev.realworldocaml.org/" -tags "ocaml, realworldocaml, book"

✅  https://dev.realworldocaml.org/ is added with id 6.
```
You would check config info with `fm config-info`
```bash
$ fm config-info

 Configuration Info
 ------------------
  ● Config file path » /Users/jazz/.favemarks.config
  ● Db file path » /Users/jazz/Library/Mobile Documents/com~apple~CloudDocs/Favemarks/favemarks.db
  ● Browser to open url » Chrome
  ● Display records per page » 10
```
You would also check all the tags stored in the db with  `fm tags`
```bash
$ fm tags

 Tags
 ----
 book github manual multicore ocaml realworldocaml stdlib unix wiki
```
If you create multiple database, you would switch among them with
```bash
fm db-switch -path "/your/db/path/fm.db"
```
You could search records with

```bash
$ fm search 

or

$ fm search -search-field "tags" -search-term "stdlib, ocaml"

or

$ fm search -search-field "tags" -search-term "stdlib, ocaml" -sort-field "id" -sort-order "asc" 
```
you could also list down all records with
```bash
$ fm ls

or

$ fm ls -sort-field "tags" -sort-order "asc"

```
## contributing
Love your help improving Favemarks!

## License
Distributed under the ISC License. See [LICENSE](LICENSE) for more information.
