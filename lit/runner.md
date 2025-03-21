---
title: Test Runner
---
<nav class="crumbs">
- [ysg](../index.html)
- [sml](../sml/index.html)
- [xunit](./index.html)
- runner
</nav>

# Test Runner

Now we're nearing the finish line, we're almost done. 

The test runner is the "main" program.

## Specification

It has a "big red button", just one, which is invoked to run the whole
thing: results are determined, reports tabulated, and then printed to
the screen (or written to a file, or posted to Tik Tok, or whatever).

Since this function is just waiting to be run, and produces
side-effects, it's a `unit -> unit` function signature.

```sml {file="runner.sig"}
signature RUNNER = sig
  val run : unit -> unit;
end;
```

## Parametrizing the Runner with a Reporter

We parametrize the test runner by some Reporter module. In Standard
ML, such structures parametrized by other structures are called
"functors" (no relation to "functors" in category theory).

The basic idea is that we will run all tests which have been
registered using `Test.register_suite`, then we will report the
results for all the tests, and then the program will exit (either
successfully or not depending on if there were only successful test
results or not, respectively).

```sml {file="mk-runner.fun"}
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
```

## Wrapping it all together

We will use the JUnit test reporter as the default reporter.

Working with MLton and Poly/ML, we also define the main function here
for future usage.

```sml {file="runner.sml"}
(*

Using the different reporters, we can run the tests, then
report the results.

Defaults to the JUnitTt reporter.

For inspecting per test result, VerboseTt.report may be useful
*)
structure Runner :> RUNNER = MkRunner(JUnitTt);

val main = Runner.run;
```

And we're done! Now we can use our lovely little testing library when
building other parts of our exploratory mission.

<footer>

**[**
[Back](./reporter.md) **|** [Up](./index.md)
**]**

</footer>

