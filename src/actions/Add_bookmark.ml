open Core
open UI_prompt
open UI_display
open Common

let get_url v =
  let msg = "Enter a url (empty to abort): "
  and retry_msg = "Please provide a valid url."
  and validate input = String.(strip_and_lowercase input = "") || is_url_valid input in
  (match v with
   | None -> ask_again_or_default ~validate ~msg ~retry_msg ""
   | Some x -> if validate x then x else ask_again_or_default ~validate ~msg ~retry_msg "")
  |> map_input_to_result
;;

let get_tags v =
  let msg = "Enter comma-delimited tags (empty to abort): "
  and retry_msg =
    "One or more comma-delimited tags must be provided. Tags should not have space."
  and validate input = String.(strip_and_lowercase input = "") || validate_tags input in
  (match v with
   | None -> ask_again_or_default ~validate ~msg ~retry_msg ""
   | Some x ->
     if validate_tags x
     then String.strip x
     else ask_again_or_default ~validate ~msg ~retry_msg "")
  |> strip_space_and_concat ~sep:","
  |> map_input_to_result
;;

let add_url ~url ~tags =
  new_line ();
  let ( let* ) = Result.( >>= ) in
  let* url = get_url url in
  let* tags = get_tags tags in
  Data_store.add ~url ~tags
;;

let add ~url ~tags = with_console_report ~f:(fun () -> add_url ~url ~tags)
