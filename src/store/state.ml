type t =
  { mutable mode : Model.mode option
  ; mutable total_count : int
  ; mutable total_search_count : int option
  ; mutable total_pages : int
  ; mutable current_page : int
  ; mutable page_size : int
  ; mutable bookmarks : Model.bookmark list
  ; mutable status : string option
  }

let create () =
  { mode = None
  ; total_count = 0
  ; total_search_count = None
  ; total_pages = 0
  ; current_page = 0
  ; page_size = Config_store.get_page_size ()
  ; bookmarks = []
  ; status = None
  }
;;

let get_mode state = state.mode
let set_mode state mode = state.mode <- mode
let get_total_count state = state.total_count
let set_total_count state count = state.total_count <- count
let get_search_count state = state.total_search_count
let set_search_count state count = state.total_search_count <- count
let get_total_pages state = state.total_pages
let set_total_pages state pages = state.total_pages <- pages
let get_page_size state = state.page_size
let set_page_size state page_size = state.page_size <- page_size
let get_current_page state = state.current_page
let set_current_page state page = state.current_page <- page
let get_bookmarks state = state.bookmarks
let set_bookmarks state bookmarks = state.bookmarks <- bookmarks
let get_status state = state.status
let set_status state status = state.status <- status
