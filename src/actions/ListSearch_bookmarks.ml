open Core
open Common
open UI_display
open UI_prompt
open UI_menu

module rec Ls : sig
  val ls : ?sort_field:string -> ?sort_order:string -> unit -> unit
  val get_sort_field : string option -> string option
  val get_sort_order : string option -> string option
end = struct
  let get_sort_field v =
    let msg =
      {|Enter sort field 'id', 'url', 'tags', or 'date' (empty to use the default value 'id'): |}
    and retry_msg =
      {|Sort field should be either one of 'id', 'url', 'tags', or 'date' (empty to use the deault value 'id').|}
    and validate input = validate_fields [ "id"; "url"; "tags"; "date" ] input in
    (match v with
     | None -> Some (ask_again_or_default ~validate ~msg ~retry_msg "id")
     | Some x ->
       if validate x
       then Some x
       else Some (ask_again_or_default ~validate ~msg ~retry_msg "id"))
    |> Option.map ~f:String.strip
  ;;

  let get_sort_order v =
    let msg =
      {|Enter sort order 'asc' or 'desc' (empty to use the default value 'desc'): |}
    and retry_msg =
      {|Sort order should be either one of 'asc' or 'desc" (empty to use the default value 'desc').|}
    and validate input = validate_fields [ "asc"; "desc" ] input in
    (match v with
     | None -> Some (ask_again_or_default ~validate ~msg ~retry_msg "desc")
     | Some x ->
       if validate x
       then Some x
       else Some (ask_again_or_default ~validate ~msg ~retry_msg "desc"))
    |> Option.map ~f:String.strip
  ;;

  let rec ls_aux ~state =
    match Data_store.ls ~state with
    | Ok state ->
      display_table state;
      show_menu ~state ~ls ~search:Search.search ~go_home:ls_aux ()
    | Error e -> print_error_msg e

  and ls ?sort_field ?sort_order () =
    new_line ();
    let sort_field = get_sort_field sort_field in
    let sort_order = get_sort_order sort_order in
    let state = State.create () in
    State.set_mode state (Some (Model.List { sort_field; sort_order }));
    ls_aux ~state
  ;;
end

and Search : sig
  val search
    :  search_term:string option
    -> search_field:string option
    -> sort_field:string option
    -> sort_order:string option
    -> unit
    -> unit
end = struct
  let get_search_field v =
    let msg =
      {|Enter search field 'id', 'url', or 'tags' (empty to search in all columns): |}
    and retry_msg =
      {|Search field should be either one of  'id', 'url', or 'tags' (empty to search in all columns).|}
    and validate input = validate_fields [ "id"; "url"; "tags"; "all" ] input in
    (match v with
     | None -> ask_again_or_default ~validate ~msg ~retry_msg "id, url, tags"
     | Some x ->
       if validate x
       then x
       else ask_again_or_default ~validate ~msg ~retry_msg "id, url, tags")
    |> strip_and_lowercase
  ;;

  let get_search_term v =
    let msg = "Enter comma-delimited search terms: "
    and retry_msg = "Search term must be provided."
    and validate input = not (is_whitespace input) in
    (match v with
     | None -> ask_again_if_invalid ~validate ~msg ~retry_msg ()
     | Some x ->
       if validate x
       then x
       else ask_again_if_invalid ~validate ~retry_first:() ~msg ~retry_msg ())
    |> String.strip
  ;;

  let rec search_aux ~state =
    match Data_store.search ~state with
    | Ok state ->
      display_table state;
      show_menu ~state ~ls:Ls.ls ~search ~go_home:search_aux ()
    | Error e -> print_error_msg e

  and search ~search_term ~search_field ~sort_field ~sort_order () =
    new_line ();
    let search_term = get_search_term search_term in
    let search_field = get_search_field search_field in
    let sort_field = Ls.get_sort_field sort_field in
    let sort_order = Ls.get_sort_order sort_order in
    let state = State.create () in
    State.set_mode
      state
      (Some (Model.Search { search_field; search_term; sort_field; sort_order }));
    search_aux ~state
  ;;
end
