open Core
module T = ANSITerminal

let is_whitespace s = s |> String.strip |> String.is_empty
let strip_and_lowercase s = String.(lowercase @@ strip s)
let epoch_str () = Time_unix.to_string Time_unix.epoch

let map_input_to_result input =
  if String.(strip_and_lowercase input = "") then Error "" else Ok input
;;

let result_to_msg_opt (r : (string, string) result) =
  match r with
  | Ok s ->
    if String.(s = "") then None else Some (T.sprintf [ T.Foreground T.Green ] "%s" s)
  | Error e ->
    if String.(e = "") then None else Some (T.sprintf [ T.Foreground T.Red ] "%s" e)
;;

let time_of_string str =
  try Time_unix.of_string str with
  | _ -> Time_unix.epoch
;;

let string_of_time (time : Time_unix.t) =
  try
    let time_str =
      Time_unix.format time "%H:%M" ~zone:(Lazy.force Time_unix.Zone.local)
    in
    let date_str =
      Time_unix.format time "%d/%m/%y" ~zone:(Lazy.force Time_unix.Zone.local)
    in
    let h = int_of_string @@ String.slice time_str 0 2 in
    sprintf
      "%s %2d:%s %s"
      date_str
      (if h >= 12 then h - 12 else h)
      (String.slice time_str 3 5)
      (if h >= 12 then "PM" else "AM")
  with
  | _ -> epoch_str ()
;;

let strip_space_and_concat ~sep str =
  str |> String.split ~on:',' |> List.map ~f:String.strip |> String.concat ~sep
;;

let is_url_valid url =
  let re =
    Re.Perl.re
      {|((http|https)://)?(www.)?[a-zA-Z0-9@:%._\+~#?&//=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%._\+~#?&//=]*)|}
    |> Re.compile
  in
  Re.execp re url
;;

let validate_tags tags =
  (not @@ is_whitespace tags)
  && (not
     @@ String.(
          split tags ~on:','
          |> List.exists ~f:(fun x ->
               let sx = strip x in
               sx = "" || exists sx ~f:Char.is_whitespace)))
;;

let validate_fields fields input =
  fields
  |> List.exists ~f:(fun x -> String.(strip_and_lowercase x = strip_and_lowercase input))
;;

let tuple_of_first_two = function
  | f :: s :: _ -> Some (f, s)
  | _ -> None
;;

let get_os_type () =
  if String.(Sys.os_type = "Unix")
  then (
    try
      let ic = Caml_unix.open_process_in "uname -s" in
      let r = In_channel.input_line ic in
      In_channel.close ic;
      match r with
      | Some name when String.(name = "Darwin") -> Ok `MacOS
      | _ -> Ok `Linux
    with
    | e -> Error (Exn.to_string e))
  else Error "The OS is not supported."
;;

let normalize_url url =
  if String.(is_prefix ~prefix:"http://" url || is_prefix ~prefix:"https://" url)
  then url
  else "https://" ^ url
;;

module Browser = struct
  let chrome_key = "Chrome"
  let safari_key = "Safari"
  let edge_key = "Edge"
  let firefox_key = "Firefox"
  let brave_key = "Brave"

  let mac_browsers =
    [ chrome_key, "Google Chrome"
    ; safari_key, "Safari"
    ; edge_key, "Microsoft Edge"
    ; firefox_key, "Firefox"
    ; brave_key, "Brave Browser"
    ]
  ;;

  (* Just a name *)
  let other_os_default_browser = "Default Browser"

  let mac_browser_keys =
    sprintf "%s, %s, %s, %s, %s" chrome_key safari_key edge_key firefox_key brave_key
  ;;

  let mac_browser_key_list =
    String.
      [ lowercase chrome_key
      ; lowercase safari_key
      ; lowercase edge_key
      ; lowercase firefox_key
      ; lowercase brave_key
      ]
  ;;

  let get_browser_keys () =
    match get_os_type () with
    | Ok `MacOS -> mac_browser_keys
    | Ok `Linux -> other_os_default_browser
    | _ -> ""
  ;;

  let get_browser_key_list () =
    match get_os_type () with
    | Ok `MacOS -> mac_browser_key_list
    | Ok `Linux -> [ other_os_default_browser ]
    | _ -> []
  ;;

  let get_browser_name key =
    match
      (other_os_default_browser, other_os_default_browser) :: mac_browsers
      |> List.find ~f:(fun (k, _) -> String.(lowercase key = lowercase k))
    with
    | Some (_, n) -> Ok n
    | None -> Error (sprintf "%s is not found." key)
  ;;
end
