open Core
open UI_display
open UI_prompt
open Common
module T = ANSITerminal

let show_menu ~state ~ls ~search ~go_home () =
  let menu_text = Queue.create () in
  let add_prompt_msg l =
    let buffer = Buffer.create 80 in
    l
    |> List.iter ~f:(fun (title, key) ->
         Buffer.add_string buffer
         @@ sprintf
              "%s %s:%s%4s"
              (T.sprintf [ T.Foreground T.Blue ] "%s" "●")
              (T.sprintf [ T.Foreground T.Cyan ] "%-7s" title)
              (T.sprintf [ T.Foreground T.Blue ] "%2s" key)
              "");
    Queue.enqueue menu_text @@ Buffer.contents buffer
  in
  add_prompt_msg [ "Add", "a"; "Search", "s"; "Config", "c"; "Next", "j" ];
  add_prompt_msg [ "Update", "u"; "List", "l"; "Tags", "t"; "Prev", "k" ];
  add_prompt_msg [ "Delete", "d"; "Open", "o"; "Export", "e"; "Quit", "q" ];
  print_lines @@ Queue.to_list menu_text;
  new_line ();
  T.print_string [ T.Foreground T.Green ] "⚡︎Your choice: ";
  printf "%!";
  let c = Char.lowercase (get_one_char ()) in

  let current_page = State.get_current_page state in
  let total_pages = State.get_total_pages state in

  if Char.(c = 'a')
  then (
    let r = Add_bookmark.add_url ~url:None ~tags:None in
    State.set_status state (result_to_msg_opt r);
    go_home ~state)
  else if Char.(c = 'j') && current_page < total_pages - 1
  then (
    State.set_current_page state (State.get_current_page state + 1);
    State.set_status state None;
    go_home ~state)
  else if Char.(c = 'k') && current_page > 0
  then (
    State.set_current_page state (State.get_current_page state - 1);
    State.set_status state None;
    go_home ~state)
  else if Char.(c = 's')
  then search ~search_term:None ~search_field:None ~sort_field:None ~sort_order:None ()
  else if Char.(c = 'l')
  then ls ?sort_field:None ?sort_order:None ()
  else if Char.(c = 'u')
  then Update_bookmark.update ~go_home ~state
  else if Char.(c = 'd')
  then Delete_bookmark.delete ~go_home ~state
  else if Char.(c = 'o')
  then (
    let msg = Open_bookmark.open_links ~state in
    State.set_status state (if String.(msg = "") then None else Some msg);
    go_home ~state)
  else if Char.(c = 'c')
  then (
    let msg = Display_info.get_config_info () in
    State.set_status state @@ msg;
    go_home ~state)
  else if Char.(c = 't')
  then (
    let msg = Display_info.get_tags_info () in
    State.set_status state @@ msg;
    go_home ~state)
  else if Char.(c = 'e')
  then Export_bookmarks.export ~go_home ~state
  else if Char.(c = 'q')
  then new_line ()
  else go_home ~state
;;
