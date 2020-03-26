
module Config = struct
  let runtime_path ~bs_project_dir =
    bs_project_dir ^ "/jscomp/runtime"

  let odoc_cache_path ~output_dir =
    output_dir ^ "/_odoc"
  
  let json_path ~output_dir =
    output_dir ^ "/_json"
end


let run cmd =
  cmd
  |> String.concat " "
  |> Unix.system
  |> ignore


let odoc_compile ~odoc_exe ~package ~output_dir ~comp_unit_path =
  let comp_unit_name = Filename.remove_extension (Filename.basename comp_unit_path) in
  let odoc_file = Config.odoc_cache_path ~output_dir ^ "/" ^ comp_unit_name ^ ".odoc" in
  let cmd = [
    odoc_exe; "compile";
    "--package=" ^ package;
    "-o"; odoc_file;
    comp_unit_path
  ] in
  run cmd;
  odoc_file


let odoc_json ~odoc_exe ~output_dir ~odoc_file =
  let cmd = [
    odoc_exe; "json";
    "-o"; Config.json_path ~output_dir;
    odoc_file
  ] in
  run cmd


let main odoc_exe bs_project_dir output_dir =
  prerr_endline ("Starting...");
  run ["mkdir"; "-p"; output_dir];
  let comp_unit_path = Config.runtime_path ~bs_project_dir ^ "/js.cmi" in
  let odoc_file = odoc_compile ~odoc_exe ~package:"runtime" ~output_dir ~comp_unit_path in
  odoc_json ~odoc_exe ~output_dir ~odoc_file


open Cmdliner


let odoc_exe =
  Arg.(
    info ["odoc-exe"] ~docv:"PATH" ~doc:"The path to the odoc executable to be used for doc generation."
    |> opt (some string) (Some "odoc")
    |> required
  )

let bs_project_dir =
  Arg.(
    info ["bs-project-dir"] ~docv:"PATH" ~doc:"The path to the Bucklescript git repository."
    |> opt (some dir) None
    |> required
  )

let output_dir =
  Arg.(
    info ["o"; "output-dir"] ~docv:"PATH"
      ~doc:"The path to directory where generated documentation will be saved."
    |> opt (some string) (Some "_output")
    |> required
  )

let () =
  Term.(
    (pure(main) $ odoc_exe $ bs_project_dir $ output_dir,
     info "bs-doc" ~version:"0.1.0" ~doc:"Generate documentation for Bucklescript libraries")
    |> eval
    |> exit
  )
