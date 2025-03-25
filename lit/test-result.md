---
title: Test Results
---
<nav class="crumbs">
- [ysg](../index.html)
- [sml](../sml/index.html)
- [xunit](./index.html)
- result
</nav>

# Test Results

## Specification for Test Result Module

The common practice is that, when we're describing a data structure,
we create a module for it with a `type t` for the type of the data
structure. We follow this rule when specifyign the test result module.

We need the following methods:

- Smart constructors which will run a test case (or test suite) once,
  and record all the information for it. These will
  be `TestResult.for_case` and `TestResult.for_suite`
- Reporting results. We don't know what the user will want. So we
  allow the user to give us two functions `report_case : t -> string` 
  and `report_suite : t -> t list -> string` which will then
  parametrize a function `t -> string` reporting the results of a
  particular run to the user as a string.
- We want accessor functions for various fields.
- We want predicates testing if the test result records a success,
  failure, or error.
- We want to count the number of successes, failures, and errors which
  occurred when running a test. For test cases, these will be at most
  1.

And that's it! It _sounds_ scarier than it is. Let us scribble this
specification down, then run over to its implementation.

(Note: if the user _wants_ to capture everything printed to `stdout`
and `stderr`, Reppy and Gansner's <cite class="book">The Standard ML
Basis Library</cite> gives some pointers in section 8.2.4.)

```sml {file="test_result.sig"}
(*
TODO: capture everything printed to stdout and stderr, then
allow the user access to these strings.
*)
signature TEST_RESULT = sig
  type t;
  val for_case : string -> (unit -> unit) -> t;
  val for_suite : string -> (unit -> (t list)) -> t;

  val report : (t -> string) -> (t -> t list -> string) -> t -> string;

  val name : t -> string;
  val msg : t -> string;
  val exn_message : t -> string;
  (* realtime excludes the time it took a TestSuite to
   allocate infrastructure in memory. *)
  val realtime : t -> Time.time;
  val runtime : t -> Time.time;
  
  val is_success : t -> bool;
  val is_failure : t -> bool;
  val is_error : t -> bool;

  val count_successes : t -> int;
  val count_failures : t -> int;
  val count_errors : t -> int;
  val count_total : t -> int;
end;
```

## Types for Test Results

The first thing we want to do is introduce types for test
results.

First, there is the type describing the conceivable outcomes of a
test. We agreed that a test could: succeed, fail with a message, or an
exception could be raised (and we'd count this as an "error"
situation).

Then, when we run a test case, we want to store its name, the time
interval for running the test, and the outcome.

When running a test suite, we want to remember its name, the time
interval it took to run it, and the results for every test in the
suite (**NOT** the outcomes --- what good would this do for nested
test suites?).

```sml {file="test_result.sml"}
structure TestResult :> TEST_RESULT = struct
  datatype Outcome = Success
                   | Failure of string
                   | Error of exn;
  
  datatype t = Case of string * Time.time * Outcome
             | Suite of string * Time.time * (t list);
```

## Smart Constructors

OK, the basic plan for constructing a test result for a test case is:

- Given the name (as a string) and the four-phase procedure as a
  function
- We will record the start time
- Then we will execute the four-phase assertion function.
- In the default case (no exception is raised), we record the stop
  time, and construct a result object for a test case saving the name,
  time interval, and a "success" outcome. This is returned to the
  user.
- If an `Assert.Failure msg` was raised, then we record the stop time,
  and construct a test result instance with a "failure" outcome
  (saving the `msg` parameter). Then we return this to the user.
- If any other exception `e` was raised, we record the stop time, and
  construct the test result recording the test case's name, the time
  interval it took to run, and that an "error" outcome with exception
  `e` occurred.

Strictly speaking, we could use a [`Timer`](https://smlfamily.github.io/Basis/timer.html)
if we wanted to check the CPU time consumed.

```sml
  fun for_case name assertion =
    let
      val start = Time.now();
    in
      (assertion();
       Case(name,
            (Time.-)(Time.now(), start),
            Success))
      handle Assert.Failure msg =>
             Case (name,
                   (Time.-)(Time.now(), start),
                   Failure msg)
             | e => Case(name,
                         (Time.-)(Time.now(), start),
                         Error e)
    end;
```

For a test suite, we simply record the start time, then determine the
results for every test in the suite. Once these results have been
tabulated, we record the interval `dt` it took to run all these tests.

Then we save these results in a test result object for a test suite.

```sml
  fun for_suite name form_results =
    let
      val start = Time.now();
      val results = form_results ();
      val dt = (Time.-)(Time.now(), start);
    in
      Suite (name, dt, results)
    end;
```

## Accessor functions

We want to hide the implementation details **entirely** from the user. 
This forces us to produce a large number of functions for obtaining
information about a test result.

The user may want to know the name of the test which was run. This is
a simple accessor function.

```sml
(* *** accessor functions *** *)
  
  fun name (Case (n,_,_)) = n
    | name (Suite (n,_,_)) = n;
```

Now, we may want to know the time it took to run the test. This will
possibly include some overhead from the test suite, so we offer two
functions for determining the time it took: the `runtime` is simply
the time intervals stored in the test result object.

The `real_time` computes the time interval for results from test
suites by summing the time intervals in the result objects for
test cases only. These two functions are the same for test case
results.

```sml
  (* runtime : t -> Time.time

How long did it take to run the test(s) and construct the
result(s)? *)
  fun runtime (Case (_,dt,_)) = dt
    | runtime (Suite (_,dt,_)) = dt;

  (* realtime : t -> Time.time

How long did it take just to run the test(s)? *)
  fun realtime (Case (_,dt,_)) = dt
    | realtime (Suite (_,_,[])) = Time.zeroTime
    | realtime (Suite (_,_,[x])) = realtime x
    | realtime (Suite (_,_,r::rs)) =
      foldl (fn (result,dt) =>
                (Time.+)(dt, realtime result))
            (realtime r)
            rs;
```

### Counting results

We can count the number of successes as follows:

- For a test result describing a single test case, if the outcome was
  a `Success`, then return 1; otherwise, return 0.
- For a test suite, simply sum the number of successes for each result
  for all tests in the suite.

This could be improved slightly by changing the test suite code to
something like
`foldl (fn (outcome, acc) (acc + (count_successes outcome))) 0 outcomes`
which avoids creating a temporary list.

```sml
  fun count_successes (Case (_,_,Success)) = 1
    | count_successes (Case _) = 0 
    | count_successes (Suite (_,_,outcomes)) =
      foldl (op +) 0 (map count_successes outcomes);
```

The reasoning is similar for counting failures and errors.

```sml
  fun count_failures (Case (_,_,Failure _)) = 1
    | count_failures (Case _) = 0
    | count_failures (Suite (_,_,outcomes)) =
      foldl (op +) 0 (map count_failures outcomes);

  fun count_errors (Case (_,_,Error _)) = 1
    | count_errors (Case _) = 0
    | count_errors (Suite (_,_,outcomes)) =
      foldl (op +) 0 (map count_errors outcomes);
```

We also want to eventually tally the total number of tests run for a
result, and this just adds up the previous three functions.

```sml
  fun count_total x =
    count_successes x + count_failures x + count_errors x;
```

### Predicates for each outcome

How do we know if a test has run "successfully" or not?

Well, for a test case, we can determine this by inspecting the
outcome, and seeing if it is a `Success` or not.

For a test _suite_, that's a bit trickier. We will consider a test
suite as executing "successfully" if every test in the suite has
executed successfully. This is a bit recursive.

Fortunately, this means the number of successes is equal to the number
of tests. And this works for both test suites and test cases.

```sml
  fun is_success x = (count_total x) = (count_successes x);
```

Now we have the trickier cases. When does a test "fail"? For a test
case, this is when the outcome is `Failure`.

For a test suite, is it when all tests have failed? If just one test
fails, is it considered a "successful" execution? No, success only
occurs when all tests have executed successfully. So if at least one
fails or throws an unexpected assertion, then the test suite executed
_unsuccessfully._

We should think of a test suite as failing if at least one failure has
occurred.

But what about an "error" outcome from executing a test suite? Now we
have a serious logic problem: are these predicates mutually exclusive
(i.e., exactly one of them is true)? Or will `is_failure` and
`is_error` permit some overlap/redundancy?

Well, either design choice seems reasonable. We will adopt the
convention that _any_ failure qualifies as `is_failure`, and that
_any_ error qualifies as `is_error`.

The implementation for these predicates are then:

```sml
  fun is_failure (Case (_,_, Failure _)) = true
    | is_failure (Case _) = false
    | is_failure (s as Suite _) =
      (count_failures s) > 0;

  fun is_error (Case (_,_, Error _)) = true
    | is_error (Case _) = false
    | is_error (s as Suite _) =
      (count_errors s) > 0;
```

### Failure messages and exception messages

We will have a few convenience functions to produce:
1. For test cases with a `Failure` outcome, produce the string
   describing the failure message
2. For test cases with an `Error` outcome, produce the `exnMessage`
   for the associated exception that was caught; and
3. The empty string for everything else.

If we wanted to be _strictly_ proper functional programmers, we should
return a `string option` --- specifically `NONE` instead of the empty
string. This just causes extra busy work, so I'm being sloppy ("do as
I say, not as I do", etc.).

```sml
  fun msg (Case (_,_,Failure msg)) = msg
    | msg _ = "";

  fun exn_message (Case (_,_,Error e)) = exnMessage e
    | exn_message _ = ""; 
```

## Reporting a test result

When we report a test result, we expect from the user two functions:

1. `report_case : t -> string` describing what we should do when
   reporting the result for a test case;
2. `report_suite : t -> t list -> string` which takes a test suite and
   all the results in that particular suite (observe --- the test
   results in a suite is otherwise inaccessible), then produce a
   string for the test suite.
   
This can be implemented as a function taking these two functions as
parameters, then produces a function `TestResult.t -> string` using
these reporting functions to produce the result.

```sml
  fun report case_report suite_report =
    fn (c as Case _) => case_report c
    | (s as Suite (_,_,results)) =>
      suite_report s results;
```

...and that's all! That's all we need for describing a test result.

```sml
end;
```

The reader might find it a fun exercise to capture anything written to
the `stdout` (and `stderr`) streams, and allow the user to access
these as strings. But I am content with what we have produced thus far.

<footer>

**[**
[Back](./test.md) **|** [Up](./index.md) **|** [Next](./reporter.md)
**]**

</footer>

