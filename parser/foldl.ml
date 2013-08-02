open Unix

let rec parse_args = function
  | [] -> ( [] , None, [] )
  | ( '-' :: '@' :: sepmark ) :: xs -> let (x,y,z) = parse_args xs in (sepmark :: x, y, z)
  | (x :: xs) -> ( [], Some x, x :: xs )

let () = match Array.to_list (Array.map BatString.to_list Sys.argv) with
  | [] -> exit 1
  | prog :: xs ->
    let (sepmarks, cmd, argv) = parse_args xs in
    let sepmarks = List.map BatString.of_list sepmarks in
    let argv     = Array.of_list (List.map BatString.of_list argv) in

    match cmd with
    | None -> exit 1
    | Some cmd ->
      let cmd  = BatString.of_list cmd in

      let reading = ref (let (hin, hout) = pipe () in (hin, hout, in_channel_of_descr hin)) in
      let writing = ref (let (hin, hout) = pipe () in (hin, hout, out_channel_of_descr hout)) in

      let input_of descr = match !descr with (hin, hout, c) -> hin in
      let output_of descr = match !descr with (hin, hout, c) -> hout in

      let exeproc () =
        set_close_on_exec (output_of writing);
        set_close_on_exec (input_of reading);
        match create_process cmd argv (input_of writing) (output_of reading) stderr with _ -> ();
        close (input_of writing);
        close (output_of reading) in

      let endproc () =
        let lines = ref [] in begin
        match !writing with (hin, hout, c) -> close_out c;
        match !reading with (hin, hout, c) -> try while true do
          let l = input_line c in lines := l :: !lines
        done with End_of_file -> close_in c end;
        List.rev !lines in

      exeproc ();

      try while true do
        let l = read_line () in

        if List.mem l sepmarks then
          let lines = endproc () in
          reading := (let (hin, hout) = pipe () in (hin, hout, in_channel_of_descr hin));
          writing := (let (hin, hout) = pipe () in (hin, hout, out_channel_of_descr hout));

          exeproc ();

          match !writing with (hin, hout, c) -> begin
            List.iter (fun l -> output_string c l ; output_char c '\n') lines;
            output_string c l ; output_char c '\n'
          end
        else
          match !writing with (hin, hout, c) -> begin
            output_string c l ; output_char c '\n'
          end
      done with End_of_file -> ();

      let lines = endproc () in List.iter print_endline lines;;