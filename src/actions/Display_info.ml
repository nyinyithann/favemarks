open Core
open UI_display
module T = ANSITerminal

let get_config_values () =
  let ( let* ) = Result.( >>= ) in
  let* db_path = Config_store.get_db_path () in
  let* browser = Config_store.get_open_with () in
  let page_size = Config_store.get_page_size () in
  let config_path = Lazy.force @@ Config_store.get_config_path_full () in
  Ok (config_path, db_path, browser, page_size)
;;

let get_title title =
  sprintf
    " %s\n %s\n"
    (with_ok_style title)
    (with_ok_style (String.make (String.length title) '-'))
;;

let get_sub_info title value =
  sprintf " %s %s » %s\n%!" (with_ok_style "●") (with_ok_style title) (with_cyan value)
;;

let get_config_info () =
  match get_config_values () with
  | Ok (config_path, db_path, browser, page_size) ->
    Some
      (with_ok_style
      @@ sprintf
           "\n%s %s %s %s %s"
           (get_title "Configuration Info")
           (get_sub_info "Config file path" config_path)
           (get_sub_info "Db file path" db_path)
           (get_sub_info "Browser to open url" browser)
           (get_sub_info "Display records per page" @@ string_of_int page_size))
  | Error e -> Some (with_error_style e)
;;

let display_config () =
  (match get_config_info () with
   | Some s -> printf "%s" s
   | _ -> ());
  new_line ()
;;

let get_tags_info () =
  match Data_store.get_tags () with
  | Ok tl ->
    Some
      (with_ok_style
      @@ sprintf "\n%s %s" (get_title "Tags") (with_ok_style (String.concat ~sep:" " tl))
      )
  | Error e -> Some (with_error_style e)
;;

let display_tags () =
  (match get_tags_info () with
   | Some s -> printf "%s\n%!" s
   | _ -> ());
  new_line ()
;;
