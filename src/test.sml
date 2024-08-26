structure Test :> TEST = struct
  datatype Test = Case of string*(unit -> unit)
                | Suite of string*(Test list);
  type t = Test;
  structure Result : TEST_RESULT = TestResult;

  val all : (Test list) ref = ref [];

  fun suite name tests = Suite(name, tests);

  fun new name f = Case(name,f);
  
  fun register_suite name tests =
    let
      val s = suite name tests
    in
      all := s::(!all);
      s
    end;
  
(*
The "path" refers to relative positioning of a test within the
hierarchy of suites. It's use is for looking up failing tests.

If a suite ends with a '/', then it is treated as a separator.

Otherwise the default separator is a dot ".".

Empty paths are treated as empty strings, and when we append a
name to it, the path is "just" that new name.
*)
  fun path "" name = name
    | path p name = if String.isSuffix "/" p
                    then p ^ name
                    else (p ^ "." ^ name);

  fun run (Case (name, assertion)) =
      Result.for_case name assertion
    | run (Suite (name, tests)) =
      Result.for_suite name
                       (fn () => map run tests);
  
  fun run_all () = map run (!all);

  (* Exit successfully iff all tests are successful. *)
  fun exit_status results =
    if List.all Result.is_success results
    then OS.Process.success
    else OS.Process.failure;
end;
