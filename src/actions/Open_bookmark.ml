open Core
open Common
open UI_display
open UI_prompt

type open_link =
  | Empty
  | Number of int
  | Links of string list

let get_links data =
  let r = ref Empty in
  let page_size = Config_store.get_page_size () in
  let msg =
    sprintf
      "Enter a number between 1 and %d inclusive or\n\
      \  comma-delimited letters from \'Key\' column or\n\
      \  empty to abort: "
      page_size
  and validate input =
    let input = String.strip input in
    String.(input = "")
    ||
    match int_of_string_opt input with
    | Some n ->
      if n > 0
      then (
        r := Number n;
        true)
      else false
    | None ->
      if is_whitespace input
      then (
        r := Empty;
        false)
      else (
        let lnks =
          input
          |> String.split ~on:','
          |> List.fold_right
               ~f:(fun x acc ->
                 match
                   List.find data ~f:(fun y ->
                     String.(y.Model.mnemonic = strip_and_lowercase x))
                 with
                 | Some d -> d.Model.url :: acc
                 | None -> acc)
               ~init:[]
        in
        if List.length lnks > 0
        then (
          r := Links lnks;
          true)
        else (
          r := Empty;
          false))
  in
  ignore @@ ask_again_or_default ~validate ~msg ~retry_msg:msg "";
  !r
;;

let open_url url cout =
  let link = Common.normalize_url url in
  (* Unix exit code min =0 max=255 *)
  (* in_channel_length throws Illagle_seek error. Hence, work around it *)
  let get_exit_code n = 130 + if n > 120 then 120 else n in
  match Config_store.get_open_with () with
  | Ok open_with ->
    (match Browser.get_browser_name open_with with
     | Ok bn ->
       (try
          match get_os_type () with
          | Ok `Linux ->
            Out_channel.close cout;
            Caml_unix.execvp "open" [| "open"; link |]
          | Ok `MacOS ->
            Out_channel.close cout;
            exit @@ Caml_unix.execvp "open" [| "open"; "-a"; bn; link |]
          | Error e ->
            Out_channel.output_string cout e;
            Out_channel.close cout;
            exit (get_exit_code (String.length e))
        with
        | Caml_unix.Unix_error (err, _, _) ->
          let e = Caml_unix.error_message err in
          Out_channel.output_string cout e;
          Out_channel.close cout;
          exit (get_exit_code (String.length e)))
     | Error e ->
       Out_channel.output_string cout e;
       Out_channel.close cout;
       exit (get_exit_code (String.length e)))
  | Error e ->
    Out_channel.output_string cout e;
    Out_channel.close cout;
    exit (get_exit_code (String.length e))
;;

let open_links ~state =
  new_line ();
  let bookmarks = State.get_bookmarks state in
  if List.length bookmarks = 0
  then with_error_style "No url to open."
  else (
    let links =
      match get_links bookmarks with
      | Number n -> List.take bookmarks n |> List.map ~f:(fun x -> x.Model.url)
      | Links ls -> ls
      | Empty -> []
    in
    let fork_open_aux l =
      let open Caml_unix in
      let fd_in, fd_out = pipe () in
      let cin = in_channel_of_descr fd_in in
      let cout = out_channel_of_descr fd_out in
      match fork () with
      | 0 -> open_url l cout
      | _ ->
        let _, status = wait () in
        (match status with
         | WEXITED n when n >= 130 ->
           (* in_channel_length throws Illagle_seek error. Hence, work around it *)
           let s =
             with_error_style
             @@ sprintf "%s Error at opening %s. %s" fail_icon l
             @@ Caml.really_input_string cin (n - 130)
           in
           In_channel.close cin;
           s
         | WEXITED n ->
           In_channel.close cin;
           (*
              A minor bug here: even open_url function throws error, n is 0 for the last call.
              Meaning if open more than 1 url, error messages are received for all except the last one.
              Need to dig deeper later.
           *)
           if n = 0
           then with_ok_style @@ sprintf "%s %s" success_icon l
           else
             with_error_style
             @@ sprintf "%s Error at opening %s. Error code: %d." fail_icon l n
         | WSIGNALED signal ->
           In_channel.close cin;
           with_error_style
           @@ sprintf "%s Browser is killed by signal %d." fail_icon signal
         | WSTOPPED _ ->
           In_channel.close cin;
           with_error_style @@ sprintf "%s Browser stopped." fail_icon)
    in
    let fork_open ls =
      let rec loop ls acc =
        match ls with
        | [] -> acc
        | h :: t -> loop t (fork_open_aux h :: acc)
      in
      let msgs = loop ls [] in
      if List.length msgs > 0
      then (
        let s =
          with_ok_style
          @@ sprintf "Status of opening links in %s\n "
          @@ Option.value ~default:""
          @@ Result.ok
          @@ Config_store.get_open_with ()
        in
        s ^ String.concat ~sep:"\n " msgs)
      else ""
    in
    fork_open links)
;;
