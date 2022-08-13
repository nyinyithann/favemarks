open Core
open UI_display
module T = ANSITerminal

let ask_input msg =
  T.print_string [ T.Foreground T.Blue ] (sprintf "» %s" msg);
  printf "%!"
;;

let ask_retry msg = T.print_string [ T.Foreground T.Magenta ] (sprintf "💪  %s\n%!" msg)

let ask_again_if_invalid ?validate ?retry_first ~msg ~retry_msg () =
  let rec aux () =
    if Option.is_some retry_first
    then (
      new_line ();
      ask_retry retry_msg;
      ask_input msg)
    else ask_input msg;
    match In_channel.input_line In_channel.stdin with
    | None | Some "" ->
      ask_retry retry_msg;
      aux ()
    | Some x ->
      (match validate with
       | Some f ->
         if f x
         then x
         else (
           ask_retry retry_msg;
           aux ())
       | None -> x)
  in
  aux ()
;;

let ask_again_or_default ?validate ~msg ~retry_msg default =
  let rec aux () =
    ask_input msg;
    match In_channel.input_line In_channel.stdin with
    | None | Some "" -> default
    | Some x ->
      (match validate with
       | Some f ->
         if f x
         then x
         else (
           ask_retry retry_msg;
           aux ())
       | None -> x)
  in
  aux ()
;;

let get_one_char () =
  let open Caml_unix in
  let termio = tcgetattr stdin in
  let () = tcsetattr stdin TCSADRAIN { termio with c_icanon = false } in
  let res = Caml.input_char Caml.stdin in
  tcsetattr Core_unix.stdin TCSADRAIN termio;
  res
;;
