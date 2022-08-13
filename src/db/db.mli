val add : db_path:string -> url:string -> tags:string -> (string, string) result
val get_total_count : db_path:string -> (int, string) result

val get_search_total_count
  :  db_path:string
  -> search_field:string
  -> search_term:string
  -> (int, string) result

val update
  :  db_path:string
  -> id:int
  -> url:string
  -> tags:string
  -> (string, string) result

val delete : db_path:string -> id:int -> (string, string) result

val load
  :  db_path:string
  -> mode:Model.mode
  -> limit:int
  -> offset:int
  -> (Model.bookmark Base.Queue.t, string) result

val load_all : db_path:string -> (Model.bookmark Base.Queue.t, string) result
val db_new : path:string -> (string, string) result
