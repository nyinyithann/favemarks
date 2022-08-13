open Core
open UI_display
open UI_prompt
open Common

let get_page_size v =
  let msg = "Enter page size between 1 and 20 inclusive (empty to skip): "
  and retry_msg = "Page size should be between 1 and 20 inclusive"
  and validate input =
    (match int_of_string_opt (String.strip input) with
     | Some x when x > 0 && x < 21 -> true
     | _ -> false)
    || String.(input = "")
  in
  match v with
  | None -> Some (ask_again_or_default ~validate ~msg ~retry_msg "")
  | Some x ->
    if validate x
    then Some x
    else Some (ask_again_or_default ~validate ~msg ~retry_msg "")
;;

let get_open_with v =
  let msg =
    sprintf "Enter a browser name (%s) (empty to skip): "
    @@ Common.Browser.get_browser_keys ()
  and retry_msg =
    sprintf "Browser name should be one of (%s)" @@ Common.Browser.get_browser_keys ()
  and validate input =
    validate_fields (Browser.get_browser_key_list ()) input || String.(input = "")
  in
  match v with
  | None -> Some (ask_again_or_default ~validate ~msg ~retry_msg "")
  | Some x ->
    if validate x
    then Some x
    else Some (ask_again_or_default ~validate ~msg ~retry_msg "")
;;

let set_page_size page_size =
  match Config_store.set_page_size page_size with
  | Ok s -> print_ok_msg s
  | Error e -> print_error_msg e
;;

let set_open_with open_with =
  match Config_store.set_open_with open_with with
  | Ok s -> print_ok_msg s
  | Error e -> print_error_msg e
;;

let set ~page_size ~open_with =
  (match get_page_size page_size with
   | None | Some "" -> ()
   | Some ps -> set_page_size @@ int_of_string ps);

  match get_os_type () with
  | Ok `MacOS ->
    (match get_open_with open_with with
     | None | Some "" -> ()
     | Some ow -> set_open_with ow)
  | _ -> ()
;;
