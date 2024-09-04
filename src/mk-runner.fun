(*
Using any test reporter, we can run the tests, then
report the results.
*)
functor MkRunner(Reporter : REPORTER) :> RUNNER = struct
  fun run () =
    let
      val results = Test.run_all ();
    in
      Reporter.report_all results;
      OS.Process.exit (Test.exit_status results);
      ()
    end;
end;

