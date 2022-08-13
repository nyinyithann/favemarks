open Core
module T = ANSITerminal

let success_icon = "✅"
let fail_icon = "🌶 "
let noti_icon = "🟠"
let new_line () = printf "\n%!"
let with_error_style msg = T.sprintf [ T.Foreground T.Red ] "%s" msg
let with_ok_style msg = T.sprintf [ T.Foreground T.Green ] "%s" msg
let with_cyan msg = T.sprintf [ T.Foreground T.Cyan ] "%s" msg

let print_ok_msg msg =
  print_string (with_ok_style @@ sprintf "\n%s  %s\n%!" success_icon msg)
;;

let print_error_msg msg =
  print_string (with_error_style @@ sprintf "\n%s  %s\n\n%!" fail_icon msg)
;;

let show_empty () = print_error_msg "No bookmarks to display."

let print_noti msg =
  T.print_string [ T.Foreground T.Magenta ] (sprintf "%s  %s" noti_icon msg);
  new_line ()
;;

let print_lines l = l |> List.iter ~f:(printf "%s\n%!")

let show_title () =
  T.erase T.Screen;
  T.set_cursor 0 0;
  T.erase T.Screen;
  T.print_string
    [ T.Foreground T.Green; T.Bold ]
    "\n⚡︎Favemarks: Your favourite bookmarks at your fingertips\n"
;;

let show_status_info ~state =
  let current_page = State.get_current_page state in
  let total_pages = State.get_total_pages state in
  let total_count = State.get_total_count state in
  let total_search_count = State.get_search_count state in
  let mode = State.get_mode state in
  let status = State.get_status state in

  let current_page_status =
    sprintf
      "⚑ Page %d/%d"
      (if current_page < total_pages then current_page + 1 else current_page)
      total_pages
  in
  let total_search_count_status =
    match total_search_count with
    | Some x -> sprintf "⚑ Total found in search: %d" x
    | None -> ""
  in
  let total_count_status = sprintf "⚑ Total in database: %d" total_count in
  let mode_status =
    if total_count = 0
    then ""
    else (
      match mode with
      | Some x ->
        (match x with
         | Model.List { sort_field; sort_order } ->
           sprintf
             "⚑ Listed all in \'%s\' order, by \'%s\' column."
             (Option.value sort_order ~default:"")
             (Option.value sort_field ~default:"")
         | Model.Search { search_term; search_field; sort_field; sort_order } ->
           sprintf
             "⚑ Searched \'%s\' in \'%s\'. Sorted in \'%s\' order, by \'%s\' column."
             search_term
             search_field
             (Option.value sort_order ~default:"")
             (Option.value sort_field ~default:""))
      | None -> "")
  in
  let status_msg =
    match status with
    | Some s -> sprintf "\n%s %s" (with_ok_style "♨︎") s
    | None -> ""
  in
  T.print_string
    [ T.Foreground T.Blue ]
    (sprintf
       "%s  %s  %s\n%s%s\n\n%!"
       current_page_status
       total_search_count_status
       total_count_status
       mode_status
       status_msg)
;;

let display_table state =
  let columns =
    let open Ascii_table_kernel in
    [ Column.create_attr
        ~align:Align.Left
        ~min_width:6
        ~max_width:6
        "Key"
        (fun (x : Model.bookmark) -> [ `Green ], x.mnemonic)
    ; Column.create_attr
        ~align:Align.Left
        ~min_width:8
        ~max_width:8
        "Id"
        (fun (x : Model.bookmark) -> [ `Blue ], string_of_int x.id)
    ; Column.create_attr
        ~align:Align.Left
        ~min_width:35
        "Url"
        (fun (x : Model.bookmark) -> [ `Blue ], x.url)
    ; Column.create_attr
        ~align:Align.Left
        ~min_width:35
        "Tags"
        (fun (x : Model.bookmark) -> [ `Blue ], x.tags)
    ; Column.create_attr
        ~align:Align.Left
        ~min_width:20
        "Date"
        (fun (x : Model.bookmark) -> [ `Blue ], Common.string_of_time x.date)
    ]
  in
  show_title ();
  Ascii_table.output
    ~oc:stdout
    ~limit_width_to:140
    ~header_attr:[ `Cyan; `Bright ]
    ~bars:`Unicode
    columns
    (State.get_bookmarks state);

  show_status_info ~state
;;

let with_console_report ~(f : unit -> (string, string) result) =
  match f () with
  | Ok s -> print_ok_msg s
  | Error e -> if String.(e = "") then () else print_error_msg e
;;
