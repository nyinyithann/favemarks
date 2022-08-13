open Core
open Sqlite3
open Core.Result

let get_total_count ~db_path =
  try
    let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
    let sql = sprintf "SELECT COUNT(*) FROM bookmarks" in
    let stmt = prepare db sql in
    ignore @@ step stmt;
    let c = column_int stmt 0 in
    ignore @@ finalize stmt;
    ignore @@ db_close db;
    Ok c
  with
  | SqliteError s -> Error s
  | e -> Error (sprintf "db.get_total_count: %s." (Exn.to_string e))
;;

let get_like_clauses search_field search_term =
  search_term
  |> String.split ~on:','
  |> List.fold ~init:"" ~f:(fun acc x ->
       let sx = String.strip x in
       sprintf "%s %s" (if Common.is_whitespace acc then acc else acc ^ " OR ")
       @@ search_field
       |> String.split ~on:','
       |> List.fold ~init:"" ~f:(fun acc y ->
            sprintf
              "%s %s LIKE \'%%%s%%\' "
              (if Common.is_whitespace acc then acc else acc ^ " OR ")
              (String.strip y)
              sx))
;;

let get_search_total_count ~db_path ~search_field ~search_term =
  try
    let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
    let sql =
      sprintf
        "SELECT COUNT(*) FROM bookmarks WHERE %s"
        (get_like_clauses search_field search_term)
    in
    let stmt = prepare db sql in
    ignore @@ step stmt;
    let c = column_int stmt 0 in
    ignore @@ finalize stmt;
    ignore @@ db_close db;
    Ok c
  with
  | SqliteError s -> Error s
  | e -> Error (sprintf "db.get_search_total_count: %s." (Exn.to_string e))
;;

let add ~db_path ~url ~tags =
  let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
  try
    let sql =
      sprintf
        "INSERT INTO bookmarks(url, tags, date) VALUES('%s', '%s', '%s')"
        url
        tags
        (Time.now () |> Time.to_string_utc)
    in
    let result =
      match exec db sql with
      | Rc.OK -> Ok (sprintf "%s is added with id %Ld." url (last_insert_rowid db))
      | e -> Error (sprintf "db.add: %s. %s." (Rc.to_string e) (errmsg db))
    in
    ignore @@ db_close db;
    result
  with
  | SqliteError s ->
    ignore @@ db_close db;
    Error s
  | e ->
    ignore @@ db_close db;
    Error (sprintf "db.add: %s." (Exn.to_string e))
;;

let update ~db_path ~id ~url ~tags =
  try
    let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
    let sql =
      sprintf
        "UPDATE bookmarks SET url = '%s', tags = '%s', date = '%s' WHERE id = %d"
        url
        tags
        (Time.now () |> Time.to_string_utc)
        id
    in
    let result =
      match exec db sql with
      | Rc.OK -> Ok (sprintf "Record with id %d is updated." id)
      | e -> Error (sprintf "db.update: %s. %s." (Rc.to_string e) (errmsg db))
    in
    ignore @@ db_close db;
    result
  with
  | SqliteError s -> Error s
  | e -> Error (sprintf "db.update: %s." (Exn.to_string e))
;;

let delete ~db_path ~id =
  try
    let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
    let sql = sprintf "DELETE FROM bookmarks WHERE id = %d" id in
    let result =
      match exec db sql with
      | Rc.OK -> Ok (sprintf "Deleted a record with id %d" id)
      | e -> Error (sprintf "db.delete: %s. %s." (Rc.to_string e) (errmsg db))
    in
    ignore @@ db_close db;
    result
  with
  | SqliteError s -> Error s
  | e -> Error (sprintf "db.delete: %s." (Exn.to_string e))
;;

let load_all ~db_path =
  try
    let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
    let data_queue = Queue.create () in
    let sql = "SELECT * FROM bookmarks ORDER BY id DESC" in
    let stmt = prepare db sql in
    while Poly.(step stmt = Rc.ROW) do
      let id = column_int stmt 0
      and url = column_text stmt 1
      and tags = column_text stmt 2
      and date = column_text stmt 3 in
      Queue.enqueue
        data_queue
        { Model.id; mnemonic = ""; url; tags; date = Common.time_of_string date }
    done;
    ignore @@ finalize stmt;
    ignore @@ db_close db;
    Ok data_queue
  with
  | SqliteError s -> Error s
  | e -> Error (sprintf "db.load_all: %s." (Exn.to_string e))
;;

let load ~db_path ~mode ~limit ~offset =
  try
    let db = db_open ~mode:`NO_CREATE ~uri:true db_path in
    let data_queue = Queue.create () in
    let sql =
      match mode with
      | Model.List { sort_field; sort_order } ->
        let stf = Option.value sort_field ~default:"id" in
        let sto = Option.value sort_order ~default:"DESC" in
        sprintf
          "SELECT * FROM bookmarks ORDER BY %s %s LIMIT %d OFFSET %d"
          stf
          sto
          limit
          offset
      | Model.Search { search_field; search_term; sort_field; sort_order } ->
        let stf = Option.value sort_field ~default:"id" in
        let sto = Option.value sort_order ~default:"DESC" in
        sprintf
          "SELECT * FROM bookmarks WHERE %s ORDER BY %s %s LIMIT %d OFFSET %d"
          (get_like_clauses search_field search_term)
          stf
          sto
          limit
          offset
    in
    let stmt = prepare db sql in
    while Poly.(step stmt = Rc.ROW) do
      let id = column_int stmt 0
      and url = column_text stmt 1
      and tags = column_text stmt 2
      and date = column_text stmt 3 in
      Queue.enqueue
        data_queue
        { Model.id; mnemonic = ""; url; tags; date = Common.time_of_string date }
    done;
    ignore @@ finalize stmt;
    ignore @@ db_close db;
    Ok data_queue
  with
  | SqliteError s -> Error s
  | e -> Error (sprintf "db.load: %s." (Exn.to_string e))
;;

let db_new ~path =
  try
    let db = db_open ~uri:true path in
    let drop_sql = "DROP TABLE IF EXISTS bookmarks" in
    let new_sql =
      "CREATE TABLE bookmarks (id INTEGER PRIMARY KEY ASC AUTOINCREMENT UNIQUE,url \
       VARCHAR (65536) NOT NULL,tags VARCHAR (65536) NOT NULL,date TEXT)"
    in
    let result =
      match exec db drop_sql with
      | Rc.OK ->
        (match exec db new_sql with
         | Rc.OK -> Ok (sprintf "A new db is created: %s." path)
         | e -> Error (sprintf "db.db_new: %s. %s." (Rc.to_string e) (errmsg db)))
      | e -> Error (sprintf "db.db_new: %s. %s." (Rc.to_string e) (errmsg db))
    in
    ignore @@ db_close db;
    result
  with
  | SqliteError s -> Error s
  | e ->
    Error
      (sprintf
         "db.db_new: %s.\nPlease make sure path is valid. e.g. \"/Users/Jazz/fm.db\""
         (Exn.to_string e))
;;
