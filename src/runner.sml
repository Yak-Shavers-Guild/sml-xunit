(*

Using the different reporters, we can run the tests, then
report the results.

Defaults to the JUnitTt reporter.

For inspecting per test result, VerboseTt.report may be useful
*)
structure Runner :> RUNNER = MkRunner(JUnitTt);

val main = Runner.run;
