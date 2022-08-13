open Core
open Common
open UI_display
open UI_prompt
open Tyxml.Html

let get_format () =
  let msg = {|Enter format to export - 'json', 'md', 'html' (empty to abort): |}
  and retry_msg = {|Format should be 'json' or 'md' or 'html'.|}
  and validate input =
    validate_fields [ "json"; "md"; "html" ] input
    || String.(strip_and_lowercase input = "")
  in
  strip_and_lowercase @@ ask_again_or_default ~validate ~msg ~retry_msg ""
;;

let get_path ~format =
  let msg = "Enter a file path to export: "
  and retry_msg =
    sprintf
      "File path should be valid. Please make sure to provide file extension in the file \
       path. (e.g. /Users/jazz/export.%s)"
      format
  and validate input =
    (Filename.is_absolute input || Filename.is_relative input)
    && Filename.check_suffix input format
  in
  ask_again_if_invalid ~validate ~msg ~retry_msg ()
;;

let to_json ~bookmarks ~path =
  try
    let rec loop bookmarks acc =
      match bookmarks with
      | [] -> acc
      | h :: t ->
        loop t
        @@ (`Assoc
              [ "id", `Int h.Model.id
              ; "url", `String (normalize_url h.Model.url)
              ; "tags", `String h.Model.tags
              ; "date", `String (string_of_time h.Model.date)
              ]
           :: acc)
    in
    let l = loop bookmarks [] in
    let j =
      Yojson.Safe.to_string
      @@ `Assoc
           [ "title", `String "Bookmarks exported from Favemarks"
           ; "date", `String (string_of_time (Time.now ()))
           ; "count", `Int (List.length bookmarks)
           ; "bookmarks", `List l
           ]
    in
    Out_channel.write_all path ~data:j;
    Ok (sprintf "%d Bookmarks are exported to %s" (List.length bookmarks) path)
  with
  | _ ->
    Error
      (sprintf
         "Error occured while exporting at %s.\nPlease check if the file path is valid."
         path)
;;

let to_markdown ~bookmarks ~path =
  try
    let b = Buffer.create 100 in
    Buffer.(
      add_string b "# Bookmarks exported from Favemarks<br/>\n";
      add_string b (sprintf "#### Count: %d<br/>\n" @@ List.length bookmarks);
      add_string b (sprintf "#### Date: %s<br/><br/>\n" (string_of_time (Time.now ()))));
    let rec loop bookmarks acc =
      match bookmarks with
      | [] -> acc
      | h :: t ->
        Buffer.add_string
          acc
          (sprintf
             "#### [%s](%s)<br/>%s<br/><br/>\n"
             h.Model.url
             (normalize_url h.Model.url)
             h.Model.tags);
        loop t acc
    in
    let md_str = loop bookmarks b in
    Out_channel.write_all path ~data:(Buffer.contents md_str);
    Ok (sprintf "%d Bookmarks are exported to %s" (List.length bookmarks) path)
  with
  | _ ->
    Error
      (sprintf
         "Error occured while exporting at %s.\nPlease check if the file path is valid."
         path)
;;

let to_html ~bookmarks ~path =
  try
    let header_section =
      section
        ~a:[ a_class [ "box"; "header" ] ]
        [ span ~a:[ a_class [ "id-header" ] ] [ txt "Id" ]
        ; span ~a:[ a_class [ "url-header" ] ] [ txt "URL" ]
        ; span ~a:[ a_class [ "tag-header" ] ] [ txt "Tags" ]
        ; span ~a:[ a_class [ "date-header" ] ] [ txt "Date" ]
        ]
    in
    let rec loop bookmarks acc =
      match bookmarks with
      | [] -> acc
      | h :: t ->
        let s =
          section
            ~a:[ a_class [ "box" ] ]
            [ span ~a:[ a_class [ "id" ] ] [ txt (string_of_int h.Model.id) ]
            ; a
                ~a:
                  [ a_class [ "url" ]
                  ; a_target "_blank"
                  ; a_href (normalize_url h.Model.url)
                  ]
                [ txt h.Model.url ]
            ; span ~a:[ a_class [ "tag" ] ] [ txt h.Model.tags ]
            ; span ~a:[ a_class [ "date" ] ] [ txt (string_of_time h.Model.date) ]
            ]
        in
        loop t (s :: acc)
    in
    let sections = loop bookmarks [] in
    let main_str =
      Format.asprintf "%a" (Tyxml.Html.pp_elt ()) @@ main (header_section :: sections)
    in
    let html =
      {|<!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
          <meta http-equiv="x-ua-compatible" content="ie=edge,chrome=1" />
          <meta name="viewport"
            content="width=device-width, height=device-height, initial-scale=1.0, maximum-scale=1.0, user-scalable=0" />
          <meta name="keywords" content="bookmarks" />
          <style>
          :root {
            font-size: calc(1vw + 0.6em);
            box-sizing: border-box;
          }
          @media screen and (min-width: 50em) {
            :root {
              font-size: 1.125em;
            }
          }
          *,
          *::before,
          *::after {
            box-sizing: inherit;
          }
          body {
            margin: 0;
            padding: 0;
          }
          h2 {
            color: #004519;
            font-weight: bold;
            padding: 0.2rem 0.2rem;
            margin: 0;
          }
          .box {
            display: flex;
            flex-flow: row nowrap;
            justify-content: flex-start;
            background-color: #b6d2de;
            color: #17543e;
            padding: 0.2rem 0.2rem;
            margin: 0.2rem 0.2rem;
          }
          .header {
            font-weight: bold;
            color: #004519;
            padding: 0.2rem 0.2rem;
          }
          .small-header {
            margin: 0 0;
            padding: 0 0;
            color: #004519;
            padding: 0.2rem 0.2rem;
          }
          .id-header {
           flex : 1 10%;
          }
          .url-header {
            flex : 1 100%;
          }
          .tag-header {
            flex : 1 100%;
          }
          .date-header {
            flex : 1 50%;
            text-align: center;
          }
          .id {
           flex : 1 10% 
          }
          .url {
              flex : 1 100%;
              overflow: hidden;
              white-space: nowrap;
              text-overflow: ellipsis;
          }
          .tag {
              flex : 1 100%;
              overflow: hidden;
              white-space: nowrap;
              text-overflow: ellipsis;
          }
          .date {
            flex : 1 50%;
            text-align: right;
          }
          </style>
          <title>Bookmarks exported from Favemarks</title>
        </head>
        <body>
        <h2>Bookmarks Exported From Favemarks</h2>
    |}
      ^ (Format.asprintf "%a" (Tyxml.Html.pp_elt ())
        @@ p
             ~a:[ a_class [ "small-header" ] ]
             [ txt (sprintf "Count: %d" @@ List.length bookmarks) ])
      ^ (Format.asprintf "%a" (Tyxml.Html.pp_elt ())
        @@ p
             ~a:[ a_class [ "small-header" ] ]
             [ txt (sprintf "Date: %s" @@ string_of_time @@ Time.now ()) ])
      ^ main_str
      ^ "</body></html>"
    in
    Out_channel.write_all path ~data:html;
    Ok (sprintf "%d Bookmarks are exported to %s" (List.length bookmarks) path)
  with
  | _ ->
    Error
      (sprintf
         "Error occured while exporting at %s.\nPlease check if the file path is valid."
         path)
;;

let export ~go_home ~state =
  new_line ();
  let format = get_format () in
  if String.(format = "")
  then go_home ~state
  else (
    let path = get_path ~format in
    match Data_store.get_bookmarks_without_pagination ~state with
    | Ok bookmarks ->
      if String.(format = "json")
      then (
        match to_json ~bookmarks ~path with
        | Ok s -> State.set_status state (Some (with_ok_style s))
        | Error e -> State.set_status state (Some (with_error_style e)));

      if String.(format = "md")
      then (
        match to_markdown ~bookmarks ~path with
        | Ok s -> State.set_status state (Some (with_ok_style s))
        | Error e -> State.set_status state (Some (with_error_style e)));

      if String.(format = "html")
      then (
        match to_html ~bookmarks ~path with
        | Ok s -> State.set_status state (Some (with_ok_style s))
        | Error e -> State.set_status state (Some (with_error_style e)));

      go_home ~state
    | Error e ->
      State.set_status state (Some e);
      print_error_msg e)
;;
