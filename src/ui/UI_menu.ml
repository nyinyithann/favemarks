open Core
open UI_display
open UI_prompt
open Common

let display_menu_items () =
  let menu_text = Queue.create () in
  let add_prompt_msg l =
    let buffer = Buffer.create 80 in
    l
    |> List.iter ~f:(fun (title, key) ->
         Buffer.add_string buffer
         @@ sprintf
              "%s %s:%s%4s"
              (with_blue "●")
              (with_cyan @@ sprintf "%-7s" title)
              (with_blue @@ sprintf "%2s" key)
              "");
    Queue.enqueue menu_text @@ Buffer.contents buffer
  in
  add_prompt_msg [ "Add", "a"; "Search", "s"; "Config", "c"; "Next", "j" ];
  add_prompt_msg [ "Update", "u"; "List", "l"; "Tags", "t"; "Prev", "k" ];
  add_prompt_msg [ "Delete", "d"; "Open", "o"; "Export", "e"; "Quit", "q" ];
  print_lines @@ Queue.to_list menu_text;
  new_line ();
  print_string @@ with_ok_style "⚡︎Your choice: ";
  printf "%!"
;;

let show_menu ~state ~ls ~search ~go_home () =
  display_menu_items ();
  let current_page = State.get_current_page state in
  let total_pages = State.get_total_pages state in

  match Char.lowercase (get_one_char ()) with
  | 'a' ->
    let r = Add_bookmark.add_url ~url:None ~tags:None in
    State.set_status state (result_to_msg_opt r);
    go_home ~state
  | 'j' when current_page < total_pages - 1 ->
    State.set_current_page state (State.get_current_page state + 1);
    State.set_status state None;
    go_home ~state
  | 'k' when current_page > 0 ->
    State.set_current_page state (State.get_current_page state - 1);
    State.set_status state None;
    go_home ~state
  | 's' ->
    search ~search_term:None ~search_field:None ~sort_field:None ~sort_order:None ()
  | 'l' -> ls ?sort_field:None ?sort_order:None ()
  | 'u' -> Update_bookmark.update ~go_home ~state
  | 'd' -> Delete_bookmark.delete ~go_home ~state
  | 'o' ->
    let msg = Open_bookmark.open_links ~state in
    State.set_status state (if String.(msg = "") then None else Some msg);
    go_home ~state
  | 'c' ->
    let msg = Display_info.get_config_info () in
    State.set_status state @@ msg;
    go_home ~state
  | 't' ->
    let msg = Display_info.get_tags_info () in
    State.set_status state @@ msg;
    go_home ~state
  | 'e' -> Export_bookmarks.export ~go_home ~state
  | 'q' -> new_line ()
  | _ -> go_home ~state
;;
