
module Config = struct
  let runtime_path ~bs_project_dir =
    bs_project_dir ^ "/jscomp/runtime"

  let belt_path ~bs_project_dir =
    bs_project_dir ^ "/jscomp/others"

  let odoc_cache_path ~output_dir =
    output_dir ^ "/_odoc"

  let json_path ~output_dir =
    output_dir ^ "/_json"
end


let run cmd =
  cmd
  |> String.concat " "
  |> Unix.system
  |> begin function
    | Unix.WEXITED 0 -> ()
    | Unix.WEXITED e ->
      prerr_endline (
        "Error while running `" ^ String.concat " " cmd ^ "`:" ^ "\n" ^
        "Exited with a non-zero code: " ^ string_of_int e
      );
      exit (100 + e)
    | _ ->
      prerr_endline (
        "Error while running `" ^ String.concat " " cmd ^ "`:" ^ "\n" ^
        "Unexpected termination"
      );
      exit 100
  end


let odoc_compile ~odoc_exe ?odoc_cache_path ~package ~output_dir comp_unit_path =
  let comp_unit_name = Filename.remove_extension (Filename.basename comp_unit_path) in
  let odoc_file = Config.odoc_cache_path ~output_dir ^ "/" ^ comp_unit_name ^ ".odoc" in
  let cmd = [
    odoc_exe;
    "compile";
    "--package=" ^ package;
    "-o"; odoc_file;
  ] in
  let cmd =
    match odoc_cache_path with
    | Some p -> cmd @ ["-I" ^ p]
    | None -> cmd in
  let cmd = cmd @ [comp_unit_path] in
  run cmd;
  odoc_file


let odoc_json ~odoc_exe ?odoc_cache_path ~output_dir odoc_file =
  let cmd = [
    odoc_exe; "json";
    "-o"; Config.json_path ~output_dir;
  ] in
  let cmd =
    match odoc_cache_path with
    | Some p -> cmd @ ["-I" ^ p]
    | None -> cmd in
  let cmd = cmd @ [odoc_file] in
  prerr_endline ("Will generate JSON files for " ^ Filename.basename odoc_file ^
                 " in " ^ Config.json_path ~output_dir);
  run cmd


type package = {
  name : string;
  path : string;
  deps : package list;
  comp_units: string list;
}

let runtime ~bs_project_dir = {
  name = "runtime";
  path = Config.runtime_path ~bs_project_dir;
  deps = [];
  comp_units = ["js.cmi"]
}

let belt ~bs_project_dir = {
  name = "belt";
  path = Config.belt_path ~bs_project_dir;
  deps = [runtime ~bs_project_dir];
  comp_units = [
    "belt_Array.cmti";
    "belt_Float.cmti";
    "belt_HashMap.cmti";
    "belt_HashMapInt.cmti";
    "belt_HashMapString.cmti";
    "belt_HashSet.cmti";
    "belt_HashSetInt.cmti";
    "belt_HashSetString.cmti";
    "belt_Id.cmti";
    "belt_Int.cmti";
    "belt_internalAVLset.cmti";
    "belt_internalAVLtree.cmti";
    "belt_internalBuckets.cmti";
    "belt_internalBucketsType.cmti";
    "belt_internalSetBuckets.cmti";
    "belt_List.cmti";
    "belt_Map.cmti";
    "belt_MapDict.cmti";
    "belt_MapInt.cmti";
    "belt_MapString.cmti";
    "belt_MutableMap.cmti";
    "belt_MutableMapInt.cmti";
    "belt_MutableMapString.cmti";
    "belt_MutableQueue.cmti";
    "belt_MutableSet.cmti";
    "belt_MutableSetInt.cmti";
    "belt_MutableSetString.cmti";
    "belt_MutableStack.cmti";
    "belt_Option.cmti";
    "belt_Range.cmti";
    "belt_Result.cmti";
    "belt_Set.cmti";
    "belt_SetDict.cmti";
    "belt_SetInt.cmti";
    "belt_SetString.cmti";
    "belt_SortArray.cmti";
    "belt_SortArrayInt.cmti";
    "belt_SortArrayString.cmti";
  ]
}

(** Given a package compile it and produce JSON files with odoc. *)
let rec process_package ~odoc_exe ~odoc_cache_path ~output_dir pkg : unit =
  List.iter (process_package ~odoc_exe ~odoc_cache_path ~output_dir) pkg.deps;
  pkg.comp_units
  |> List.map (fun comp_units -> pkg.path ^ "/" ^ comp_units)
  |> List.iter (fun comp_unit_path ->
      let odoc_file = odoc_compile ~odoc_cache_path ~odoc_exe ~package:pkg.name ~output_dir comp_unit_path in
      odoc_json ~odoc_exe ~odoc_cache_path ~output_dir odoc_file)


let main odoc_exe bs_project_dir output_dir =
  prerr_endline ("Starting...");
  run ["mkdir"; "-p"; output_dir];

  process_package (belt ~bs_project_dir)
    ~odoc_exe
    ~odoc_cache_path:(Config.odoc_cache_path ~output_dir)
    ~output_dir;

  prerr_endline "Done."


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
