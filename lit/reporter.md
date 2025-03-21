---
title: Reporter Module
---
<nav class="crumbs">
- [ysg](../index.html)
- [sml](../sml/index.html)
- [xunit](./index.html)
- reporter
</nav>

# Test Reporter

## Specification

A reporter will take a `TestResult.t`, then write a human-readable
report to the screen (or to a file, or send an email, or send a text
message, or post a viral Tik Tok video, or...). In effect, it will
`report` a test result.

Furthermore, if the `report` creates a new file, writes to it, then
closes it (or posts a new TikTok video, or sends an email, or...),
well what happens if it reports a sequence of test results? We'd get a
bunch of emails, or files, or TikTok videos, or..., when it'd be more
desirable to get **just one** artifact.

For this reason, we will add a `report_all` function to produce just
one artifact for a list of test results.

```sml {file="reporter.sig"}
(*
The REPORTER formats and writes the results...somewhere.
This could be to the screen (usually done by reporters
suffixed by `_Tt`) or to a file.

Either way, this is a `unit` return type.

The reason for `report_all` as separate than `report` is
because `report` could create a new file each time it is
called (which might be undesirable if we want to write all the
results to a single file).
*)
signature REPORTER = sig
  val report : Test.Result.t -> unit;
  val report_all : Test.Result.t list -> unit;
end;
```

## JUnit-like reporter printing to the terminal

We sometimes only want to know about failures or errors which
occurred, and then a summary for each test suite of the total number
of tests run. This is what JUnit does, so I just copied its format.

We begin with some helper functions for printing the time interval to
microseconds.

```sml {file="junit_tt.sml"}

(* 
Print to the terminal (hence the "-Tt" suffix) a summary of test
results in the style of JUnit.

If any failures or errors occur, print those out with a bit more
detail.
*)
structure JUnitTt :> REPORTER = struct
  structure Result = Test.Result;

  fun interval_to_string (dt : Time.time) =
    (LargeInt.toString (Time.toMicroseconds dt))^"ms";
```

The basic recursive scheme will be to carry the "path" to the test
suite containing the current test result. Then we have two possible
situations:

1. We are reporting the result for a test case. 
   - If the test failed, we should print the path to the test,
     announce it failed, and give the failure message.
   - If the test err'd, we should do everything similarly to the
     failure case, except announce it was an `ERROR` and produce the
     exception message.
   - If the test succeeded, then don't do anything: we do not wish to
     pollute the terminal.
2. We are reporting the result for a test suite.
   - Write the test suite's full path to the screen.
   - Write the results for each test in the suite to the screen.
   - Write to the screen a summary line counting the total number of
     tests run, the number of failures, the number of errors, and the
     name of the test suite.

These are precisely the `report_case` and `report_suite` functions
which will be given to `TestResult.report`.

```sml
  fun report_iter p =
    let
      fun for_case c =
        if Result.is_failure c
        then concat [Test.path p (Result.name c),
                     " FAIL: ",
                     Result.msg c,
                     "\n"]
        else if Result.is_error c
        then concat [Test.path p (Result.name c),
                     " ERROR: ",
                     (Result.exn_message c),
                     "\n"]
        else "";
      fun for_suite result rs =
        let
          val p2 = Test.path p (Result.name result);
        in
          concat ["Running ", p2, "\n",
                  concat (map (report_iter p2) rs),
                  "Tests run: ",
                  Int.toString(Result.count_total result),
                  ", Failures: ",
                  Int.toString(Result.count_failures result),
                  ", Errors: ",
                  Int.toString(Result.count_errors result),
                  ", Time elapsed: ",
                  interval_to_string (Result.realtime result),
                  " - in ",
                  (Result.name result), "\n"]
        end;
    in
      fn result => Result.report for_case for_suite result
    end;
```

The `report` function just prints the string we just constructed to
the screen. The `report_all` prints all the results to the screen.

That's all there is to the JUnit-teletype reporter.

```sml
  val report = print o (report_iter "");

  val report_all = app report;
end;
```

## Verbose Reporter

The verbose reporter is similar to the JUnit teletype reporter, but it
reports _successes_ as well as failures and errors.

```sml {file="verbose_tt.sml"}
(*
Write every test result to the terminal. It's very...verbose...
*)
structure VerboseTt :> REPORTER = struct
  structure Result = Test.Result;

  fun interval_to_string (dt : Time.time) : string =
    (LargeInt.toString (Time.toMicroseconds dt))^"ms";

  (* Print the results to the terminal *)
  fun report_iter p =
    let
      fun for_case c =
        if Result.is_failure c
        then concat [Test.path p (Result.name c),
                     " FAIL: ",
                     Result.msg c,
                     "\n"]
        else if Result.is_error c
        then concat [Test.path p (Result.name c),
                     " ERROR: ",
                     (Result.exn_message c),
                     "\n"]
        else concat [Test.path p (Result.name c),
                     " SUCCESS\n"];
      fun for_suite result rs =
        let
          val p2 = Test.path p (Result.name result);
        in
          concat ["Running ", p2, "\n",
                  concat (map (report_iter p2) rs),
                  "Tests run: ",
                  Int.toString(Result.count_total result),
                  ", Failures: ",
                  Int.toString(Result.count_failures result),
                  ", Errors: ",
                  Int.toString(Result.count_errors result),
                  ", Time elapsed: ",
                  interval_to_string (Result.realtime result),
                  " - in ",
                  (Result.name result), "\n"]
        end;
    in
      fn result => Result.report for_case for_suite result
    end;

  val report = print o (report_iter "");

  val report_all = app report;

end;
```

<footer>

**[**
[Back](./test-result.md) **|** [Up](./index.md) **|** [Next](./runner.md)
**]**

</footer>

