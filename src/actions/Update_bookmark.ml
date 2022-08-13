open Core
open Common
open UI_display
open UI_prompt

let get_key bookmarks =
  let msg = "Enter a key (empty to abort): " in
  let retry_msg = "Key is not found in the displaying records. Please try again." in
  let keys = bookmarks |> List.map ~f:(fun x -> x.Model.mnemonic) in
  let validate input = validate_fields keys input in
  strip_and_lowercase @@ ask_again_or_default ~validate ~msg ~retry_msg ""
;;

let get_modified_url existing_url =
  print_noti (sprintf "Existing url: %s" existing_url);
  let msg = "Enter a url (empty to use existing one): "
  and retry_msg = "A valid url must be provided." in
  ask_again_or_default ~validate:is_url_valid ~msg ~retry_msg existing_url
;;

let get_modified_tags existing_tags =
  print_noti (sprintf "Existing tags: %s" existing_tags);
  let msg = "Enter comma-delimited tags (empty to use existing ones): "
  and retry_msg =
    "One or more comma-delimited tags must be provided. Tags should not have space."
  in
  strip_space_and_concat ~sep:","
  @@ ask_again_or_default ~validate:validate_tags ~msg ~retry_msg existing_tags
;;

let update ~go_home ~state =
  new_line ();
  let bookmarks = State.get_bookmarks state in
  let key = get_key bookmarks in
  if String.(key = "")
  then (
    State.set_status state None;
    go_home ~state)
  else (
    (match List.find bookmarks ~f:(fun x -> String.(x.Model.mnemonic = key)) with
     | Some { Model.id; url; tags; _ } ->
       let modified_url = get_modified_url url in
       let modified_tags = get_modified_tags tags in
       if String.(modified_url <> url || modified_tags <> tags)
       then (
         match Data_store.update ~id ~url:modified_url ~tags:modified_tags with
         | Ok s -> State.set_status state @@ Some (with_ok_style s)
         | Error e -> State.set_status state @@ Some (with_error_style e))
     | _ ->
       State.set_status state
       @@ Some
            (with_error_style
            @@ sprintf "Record with key %s is not found in the table." key));
    go_home ~state)
;;
