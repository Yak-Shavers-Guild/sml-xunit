---
title: Test architecture
---
<nav class="crumbs">
- [ysg](../index.html)
- [sml](../sml/index.html)
- [xunit](./index.html)
- test
</nav>

# Test architecture

The basic architecture for xUnit testing consists of:

- Tests, which are either "test cases" or "test suites"
- Running tests, which takes a test then executes each test case,
  finally producing a "result" (a "result" being the data describing a
  _particular_ "run")
- Reporting results (printing to the screen, writing to a file)

We want to design a simple library with this architecture.

There are many "obvious" simple extensions to this library --- the
user may wish to write the output as an XML file, and capture the
`stdout` (and/or `stderr`) stream(s), and so on. All these desired
qualities are simple, straightforward, and reasonable requests. But
designing software that will support _every_ simple, straightforward,
and reasonable request _prior_ to the request being made is an
exercise in futility: the reader is recommended to consult
Laura Numeroff's _If You Give a Mouse a Cookie_.

Now, we will suppose that a test case is just a name (string) and a
function which if executed successfully produces the unit value `()`. 
This function is precisely the four-phases of a unit test represented
as an ML function. So if there is an assertion failure, an
`Assert.Failure reason` exception is raised --- which will be handled
here.

And a test suite is "just" a collection of tests labeled with a name
(string). 

Taken together, these form a recursive algebraic data type describing
tests:

```sml {file=test.sml}
structure Test :> TEST = struct
  datatype Test = Case of string*(unit -> unit)
                | Suite of string*(Test list);
  type t = Test;
  structure Result : TEST_RESULT = TestResult;
```

Why do we have this redundant `type t = Test`? Well, the signature for
the `Test` lists function specifications, and it's easier to parse
`Test -> string` rather than `t -> string` --- and in general we want
to _help_ the reader make sense of our code.

The `structure Result` is the test result module describing the
associated abstract data type. We will discuss it in a moment.

## Specification for Test Module

What exactly do we expect in a signature describing the specification
for a `Test` module?

We want:
- smart constructors `Test.new` for creating new test cases and
  `Test.suite` for creating new test suites
- `Test.register_suite` will create a new test suite, and register it
  with the test runner
- `Test.run_all : unit -> TestResult.t list` will run all the tests
  and produce the associated result artifacts (which will later be
  reported to the reader)
- `Test.path` is a pretty printer for helping locate a unit test
  inside nested test suites
- `Test.exit_status` determines if there was any test failure or
  error, and only if there are no failures and no errors will we exit
  the program successfully.
  
We formalize this with the signature:

```sml {file=test.sig}
signature TEST = sig
  type Test;
  type t = Test;
  structure Result : TEST_RESULT;

  val suite : string -> Test list -> Test;
  val new : string -> (unit -> unit) -> Test;
  val register_suite : string -> Test list -> Test;
  val run_all : unit -> Result.t list;
  val path : string -> string -> string;
  val exit_status : Result.t list -> OS.Process.status;
end;
```

Let us implement these in order.

## Smart constructors

We can implement the first couple smart constructors in the "obvious"
way:

```sml {file="test.sml"}
  fun new name f = Case(name,f);
  
  fun suite name tests = Suite(name, tests);
```

Now we can register a suite to make it run by the "main" function at
the end of our literate program. Towards that end, we need a variable
tracking all the test suites to be run.

I'm lazy, I gave up being clever and decided to use a mutable
reference. Registering a suite simply creates a new test suite, pushes
it on top of this mutable reference, then returns the test suite.

```sml
  val all : (Test list) ref = ref [];

  fun register_suite name tests =
    let
      val s = suite name tests
    in
      all := s::(!all);
      s
    end;
```

## Running tests

We will construct test results for each test suite, which recursively
constructs new results for each test in the suite. The `TestResult`
module will take care of executing a test _once_, and store the result
of that particular execution.

This means that `Test.run` will take a `Test.t` object, and produce a
`TestResult.t` object describing what happened when we performed the
test. The hard work will be found in the `TestResult.for_case` and
`TestResult.for_suite` constructors.

This pushes off the hard work to another module, but that's a common
trick in programming (in politics it's called "delegation").

``` sml
  fun run (Case (name, assertion)) =
      Result.for_case name assertion
    | run (Suite (name, tests)) =
      Result.for_suite name
                       (fn () => map run tests);
```

We have a publicly available function which will produce the test
results obtained by running all suites registered with the test
runner.

``` sml
  fun run_all () = map run (!all);
```

## Path to a test

The "path" of a test is an idiosyncratic notion useful for helping us
locate a failing unit test when it is in a deeply nested test suite.

The analogy is with the "path" to a file [test] in a directory [suite].

```sml
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
```

## Determine Exit Status

The last step in the game is to determine the exit status --- the
program will indicate to the world if the tests ran successfully or if
there was a failure (or error) encountered.

This can be done by simply checking that all test results are recorded
as all "successes".

```sml
  (* Exit successfully iff all tests are successful. *)
  fun exit_status results =
    if List.all Result.is_success results
    then OS.Process.success
    else OS.Process.failure;
```

...and that's all! The `Test` module closes here, and we're off to the
next exciting portion

```sml
end;
```

# Appendix: Busywork for encapsulation

SML/NJ requires everything to be in a module, so we need to bundle a
test suite as a module when we're writing unit tests. It must have a
signature, so we give it a simple one:

```sml {file=suite.sig}
(*
SML/NJ requires putting everything into structures, so
when we have a test suite, we need to put it into a structure
for pointless bureacracy.
*)

signature SUITE = sig
  val suite : Test.t;
end;
```

<footer>

**[** [Back](./assert.md) **|** [Up](./index.md) **|** [Next](./test-result.md) **]**

</footer>
