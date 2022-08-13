open Core

let with_db_path (type a) ~(f : string -> (a, string) result) =
  match Config_store.get_db_path () with
  | Ok p -> f p
  | Error _ as e -> e
;;

let add ~url ~tags = with_db_path ~f:(fun db_path -> Db.add ~db_path ~url ~tags)
let get_total_count () = with_db_path ~f:(fun db_path -> Db.get_total_count ~db_path)

let get_search_total_count ~search_field ~search_term =
  with_db_path ~f:(fun db_path ->
    Db.get_search_total_count ~db_path ~search_field ~search_term)
;;

let delete ~id = with_db_path ~f:(fun db_path -> Db.delete ~db_path ~id)

let update ~id ~url ~tags =
  with_db_path ~f:(fun db_path -> Db.update ~db_path ~id ~url ~tags)
;;

let db_new ~path = Db.db_new ~path

let get_bookmarks_without_pagination ~state =
  let ( let* ) = Result.( >>= ) in
  let* mode = Result.of_option (State.get_mode state) ~error:"Invalid Mode" in
  let* data =
    with_db_path ~f:(fun db_path -> Db.load ~db_path ~mode ~limit:Int.max_value ~offset:0)
  in
  Ok (Queue.to_list data)
;;

let with_mnemonic data =
  let mnemonic_count = 26 in
  let mnemonics =
    Array.init mnemonic_count ~f:(fun x -> String.of_char @@ Char.of_int_exn (x + 97))
  in
  data
  |> Queue.to_list
  |> List.mapi ~f:(fun i x ->
       { x with Model.mnemonic = (if i < mnemonic_count then mnemonics.(i) else "") })
;;

let search ~state =
  let mode = State.get_mode state in
  match mode with
  | Some (Model.Search { search_field; search_term; _ } as mode) ->
    let ( let* ) = Result.( >>= ) in
    let* total_count = get_total_count () in
    let* search_count = get_search_total_count ~search_field ~search_term in
    let page_size = State.get_page_size state in
    let offset = State.get_current_page state * page_size in
    let* data =
      with_db_path ~f:(fun db_path -> Db.load ~db_path ~mode ~limit:page_size ~offset)
    in
    State.set_total_count state total_count;
    State.set_search_count state (Some search_count);
    State.set_bookmarks state (with_mnemonic data);
    State.set_total_pages
      state
      (Float.to_int
      @@ Float.(round_up (float_of_int search_count / float_of_int page_size)));
    Ok state
  | _ -> Error "search_field and search_term must be provided."
;;

let ls ~state =
  let mode = State.get_mode state in
  match mode with
  | Some (Model.List _ as mode) ->
    let ( let* ) = Result.( >>= ) in
    let* total_count = get_total_count () in
    let page_size = State.get_page_size state in
    let offset = State.get_current_page state * page_size in
    let* data =
      with_db_path ~f:(fun db_path -> Db.load ~db_path ~mode ~limit:page_size ~offset)
    in
    State.set_total_count state total_count;
    State.set_search_count state None;
    State.set_bookmarks state (with_mnemonic data);
    State.set_total_pages
      state
      (Float.to_int
      @@ Float.(round_up (float_of_int total_count / float_of_int page_size)));
    Ok state
  | _ -> Error "Internal error: setting the wrong mode."
;;

let get_tags () =
  let ( let* ) = Result.( >>= ) in
  let* data = with_db_path ~f:(fun db_path -> Db.load_all ~db_path) in
  let tags =
    Queue.to_list data
    |> List.concat_map ~f:(fun x ->
         x.Model.tags
         |> String.split ~on:','
         |> List.map ~f:(fun x -> Common.strip_and_lowercase x))
  in
  Set.of_list (module String) tags |> Set.to_list |> Ok
;;
