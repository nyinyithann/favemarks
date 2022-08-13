open Core
open Common

let config_path = "/.favemarks.config"
let db_path_key = "Db_Path_Key"
let page_size_key = "Page_Size_Key"
let open_with_key = "Open_With"
let default_page_size = 12
let max_page_size = 20
let cache = Hashtbl.create (module String)

let get_config_path_full () =
  Lazy.from_fun (fun () -> Sys_unix.home_directory () ^ config_path)
;;

let config_file_exists () =
  let config_path_full = Lazy.force @@ get_config_path_full () in
  match Sys_unix.file_exists config_path_full with
  | `Yes -> true
  | `No | `Unknown -> false
;;

let get_config () =
  if config_file_exists ()
  then (
    try
      In_channel.read_lines @@ Lazy.force @@ get_config_path_full ()
      |> List.fold ~init:[] ~f:(fun acc x ->
           if String.length x > 0
           then (
             match String.split x ~on:'=' |> Common.tuple_of_first_two with
             | Some (fst, snd) -> String.(strip fst, strip snd) :: acc
             | None -> acc)
           else acc)
      |> Ok
    with
    | e -> Error (Exn.to_string e))
  else Error "Config file is not found."
;;

let config_not_found_error_msg key =
  Error
    (sprintf
       "config value of %s not found. Please run \'fm db -new\' command to create a new \
        db unless you haven't."
       key)
;;

let get_db_path () =
  let set_cache_and_return v =
    Hashtbl.set cache ~key:db_path_key ~data:v;
    Ok v
  in
  match Hashtbl.find cache db_path_key with
  | Some v -> set_cache_and_return v
  | None ->
    (match get_config () with
     | Ok l ->
       (match
          List.find l ~f:(fun (fst, _) ->
            String.(equal (strip_and_lowercase fst) (lowercase db_path_key)))
        with
        | Some (_, snd) -> set_cache_and_return (String.strip snd)
        | _ -> config_not_found_error_msg db_path_key)
     | Error _ as e -> e)
;;

let get_open_with () =
  match get_os_type () with
  | Ok `MacOS ->
    let set_cache_and_return v =
      Hashtbl.set cache ~key:open_with_key ~data:v;
      Ok v
    in
    (match Hashtbl.find cache open_with_key with
     | Some v -> set_cache_and_return v
     | None ->
       (match get_config () with
        | Ok l ->
          (match
             List.find l ~f:(fun (fst, _) ->
               String.(equal (strip_and_lowercase fst) (lowercase open_with_key)))
           with
           | Some (_, snd) -> set_cache_and_return (String.strip snd)
           | _ -> set_cache_and_return Common.Browser.chrome_key)
        | _ -> set_cache_and_return Common.Browser.chrome_key))
  | _ -> Ok Common.Browser.other_os_default_browser
;;

let get_page_size () =
  let set_cache_and_return v =
    let pz =
      match int_of_string_opt (String.strip v) with
      | Some x ->
        if x > max_page_size
        then max_page_size
        else if x <= 0
        then default_page_size
        else x
      | None -> default_page_size
    in
    Hashtbl.set cache ~key:page_size_key ~data:(string_of_int pz);
    pz
  in
  match Hashtbl.find cache page_size_key with
  | Some v -> set_cache_and_return v
  | None ->
    (match get_config () with
     | Ok l ->
       (match
          List.find l ~f:(fun (fst, _) ->
            String.(equal (strip_and_lowercase fst) (lowercase page_size_key)))
        with
        | Some (_, snd) -> set_cache_and_return snd
        | _ -> set_cache_and_return (string_of_int default_page_size))
     | _ -> set_cache_and_return (string_of_int default_page_size))
;;

let save_data data =
  try
    let oc = Out_channel.create ~binary:false (Lazy.force @@ get_config_path_full ()) in
    Out_channel.output_lines oc (data |> List.map ~f:(fun (k, v) -> sprintf "%s=%s\n" k v));
    Out_channel.close oc;
    data |> List.iter ~f:(fun (key, data) -> Hashtbl.set cache ~key ~data);
    Ok "Successfully saved"
  with
  | e -> Error (Exn.to_string e)
;;

let set_db_filepath ~new_path =
  if config_file_exists ()
  then (
    match get_open_with () with
    | Ok op ->
      save_data
        [ db_path_key, new_path
        ; page_size_key, string_of_int @@ get_page_size ()
        ; open_with_key, op
        ]
    | Error _ as e -> e)
  else save_data [ db_path_key, new_path ]
;;

let set_page_size page_size =
  let page_size = string_of_int page_size in
  if config_file_exists ()
  then (
    match get_db_path (), get_open_with () with
    | Ok dbp, Ok opw ->
      save_data [ db_path_key, dbp; open_with_key, opw; page_size_key, page_size ]
    | Error e1, Error e2 -> Error (e1 ^ e2)
    | (Error _ as e), _ -> e
    | _, (Error _ as e) -> e)
  else save_data [ page_size_key, page_size ]
;;

let set_open_with open_with =
  if config_file_exists ()
  then (
    match get_db_path (), get_page_size () with
    | Ok dbp, ps ->
      save_data
        [ db_path_key, dbp; page_size_key, string_of_int ps; open_with_key, open_with ]
    | (Error _ as e), _ -> e)
  else save_data [ open_with_key, open_with ]
;;
