open Core
open UI_display

let rec db_new ~path =
  match Data_store.db_new ~path with
  | Ok s -> 
        print_ok_msg s;
        db_switch ~new_path:path       
  | Error e -> print_error_msg e
and db_switch ~new_path =
  match Config_store.set_db_filepath ~new_path with
  | Ok _ -> print_ok_msg @@ sprintf "Db is switched to %s" new_path
  | Error e -> print_error_msg e
;;
