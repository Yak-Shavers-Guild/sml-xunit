---
title: xUnit Framework in Standard ML
---

# xUnit Framework in Standard ML

## Why bother testing software?

Motivating unit testing is a strange discussion. For programmers, it's
like motivating brushing your teeth or washing your hands: it's good
hygene and pays dividends in your long run health. For
non-programmers, it can feel like an empty ritual.

Let me try to address the non-programmers.

First, in my experience, we often develop software little-by-little,
articulating the problem, outlining functions and data structures
needed to solve the problem, then implementing them. Very frequently,
we have some example usage in mind when writing the code. It's useful
to document these examples somewhere. But it's even more useful to
make sure these examples work as intended. Unit testing allows us to
do this.

Second, requirements change as new features are added, or technology
changes, or libraries change (or...). Change is part of life. It's
easy to just "hack" some code to make it work with the changed
requirements. But it's even better to have some unit tests to show
that (a) the pre-existing requirements still are satisfied, and (b)
the new requirements are satisfied.

Third, as time goes on, "future you" will forget why some lines of
code are written as they are. It's easy to just "clean up" those lines
of code, only to discover everything breaks. Unit testing will protect
us from these situations. (Although, to be fair, you should either
improve the code or document it if you cannot understand what's going on.)

For our Mathematician friends, they may ask, "Why not just _prove_ the
correctness of the code? Then you won't need unit tests, and all will
be well."

While this is easy to say, it is hard to do in practice. A good
compromise is to partition the space of inputs into finitely many
equivalence classes (based on behaviour of the program), and then take
a few representative samples from each equivalence class for unit
testing.

In short, for our non-programmer friends, the need for testing
software is to find bugs, prevent bugs, and providing examples on how
to use the software. I think we can all agree, these are useful things
indeed.

## Problem Statement

So let us try to articulate what we want from a library for unit
testing.

The basic idea is that we will have a function, `fun foo args`, which
we want to test. How do we "test" it? We give specific example inputs
and corresponding expected outputs, and if `expected = foo example_inputs`
then we say the test succeeded (otherwise, it failed).

We call this `expected = foo example_inputs` an <dfn>Assertion</dfn>.
Ostensibly, if we were doing numerical analysis, we could have some
margin of error, like `|expected - foo example_inputs| <= tolerance`,
but we will not need this.

But what is more, a <dfn>Test Case</dfn> is a self-contained function
which consists of four phases:

1. **Fixture setup.** 
   We set up the "test fixture" (the "before" picture) that is
   required for the system-under-test to exhibit the desired behaviour
   --- for a lot of unit tests this is as minimal as possible, but
   could require creating fake objects which resemble possible inputs.
2. **Exercise.**
   We interact with the system-under-test (e.g., invoke `foo example_inputs`)
3. **Result verification.**
   We determine the expected outcome has been achieved --- usually we
   construct the expected outputs, and determine if the actual
   outputs correspond to the expected outputs.
4. **Fixture teardown.**
   We "tear down the test fixture" (close files, whatever) to put "the world"
   back into its original state.

It's important that this is self-contained, repeatable, and
independent of externalities as much as possible. The test should not
succeed or fail depending on the time of day, city it was executed in,
etc. The only thing it should depend on are the "fixtures" in the
test.

Each test case should test a single condition, i.e., contain a single
assertion. This makes it easier to identify more exactly points of
failure in "production code". Consequently, we want many test cases.

We also want to "bundle" test cases together when they logically
relate to the same system (e.g., we're testing the same structure).
This gives us a notion of <dfn>Test Suites</dfn> as a collection of
"tests" (either test cases or nested test suites --- the analogy to
grasp towards are files and folders).

In effect, we want to be able to write down tests like:

```sml {example}
test "lowercase_test1"
     (fn () =>
       let
         (* fixture setup (none) *)
         (* exercise system *)
         val actual = lowercase("ExPeCtEd OUTCOME");
         (* verify outcome *)
         val expected = "expected outcome";
         val fail_msg = concat ["EXPECTED: \""
                               , expected
                               , "\"\nACTUAL: \""
                               , actual
                               , "\"\n"];
        in
         Assert.eq expected actual fail_msg
         (* fixture teardown (none) *)
        end);
```

Fixtures occur when we want to have a "fake database" which stores
known records in memory [RAM] and behaves in so simple a way as cannot
be itself a source of bugs. If we had any, we would need to take care
to wrap the "exercise system" and "verify outcome" in parentheses, and
have a `handle _ => tear_down_fixtures` wrap things up.

## More about the Architecture of xUnit Testing

The basic architecture could be found in Ken Beck's [Simple Smalltalk Testing:
With Patterns](https://web.archive.org/web/20150315073817/http://www.xprogramming.com/testfram.htm)
and discussed exhaustively in Gerard Meszaros's wonderful book 
<cite class="book">xUnit Test Patterns: Refactoring Test Code</cite>
(2007). 

Originally, the SUnit library (designed by Beck) offered unit tests
for Smalltalk. This was adapted to Java in JUnit. The original designs
(in SUnit and early JUnit) was for the Test Suite to run and for
Smalltalk report the results directly to the user (just print it to
the screen) and for JUnit it accumulated the results in a [`TestResult`](https://www.eg.bucknell.edu/~cs475/F2000-S2001/hyde/JUnit/javadoc/test.framework.TestResult.html)
object parameter (for the user to do whatever they wish with).

## Directory Tree

<div class="tree">

├── [..](../index.md) <br>
├── index.md (you are here) <br>
├── [assert.md](./assert.md) <br>
├── [test.md](./test.md) <br>
├── [test-result.md](./test-result.md)<br>
├── [reporter.md](./reporter.md) <br>
└── [runner.md](./runner.md) <br>

</div>
