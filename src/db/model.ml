type bookmark =
  { id : int
  ; mnemonic : string
  ; url : string
  ; tags : string
  ; date : Time_unix.t
  }

type mode =
  | List of
      { sort_field : string option
      ; sort_order : string option
      }
  | Search of
      { search_field : string
      ; search_term : string
      ; sort_field : string option
      ; sort_order : string option
      }
