---
title: Assertions
---
<nav class="crumbs">
- [ysg](../index.html)
- [sml](../sml/index.html)
- [xunit](./index.html)
- assert
</nav>

# Assertions

The basic idea is that we want to have tests raise a special exception
if the assertion fails to be true, which will be handled by the
`Test.run` function and processed to a `Test.Result.Failure`. Further,
we want this to have a message communicating the _reason_ for failure.

This is achieved with a simple module packaging a `Failure`
exception. We don't want to re-use to given `Fail` exception from the
Standard ML standard library, since the system under test might throw
that exception (and then how do we determine if this is an "assert
fail" or a "system-under-test fail"?). We avoid this problem with an
`Assert.Failure` exception.

We also want two simple helper functions:

- one (`Assert.!!`) will take a Boolean value representing whether we
  succeeded or failed (and a failure message to report upon failure);
- the other will `Assert.eq` take two values (an `actual` and an
  `expected` value) and a fail message, then if the two values are
  **not** equal to each other `raise Failure msg`.

A good practice is to have consistent argument ordering: the failure
message should always be first or always be last --- it doesn't
matter which convention is chosen, but one should be chosen. 

Since the heuristic we should bear in mind is "Assert [condition],
otherwise here's the reason why it failed", it makes sense to give the
failure message as the _last_ argument.

The signature for this plan is:

```sml {file="assert.sig"}
signature ASSERT = sig
  exception Failure of string;

  val !! : bool -> string -> unit;
  val eq : ''a -> ''a -> string -> unit;
end;
```

<details class="spec">
<summary>Tests for Assertions</summary>

As an example of "test-driven development", we should provide some
_specification_ for these two functions `Assert.!!` and `Assert.eq`.

We would expect `Assert.!! true "true should not fail" = ()`, so we
can make this into a unit test.

Similarly, we expect `Assert.!! false "false fails"` should throw an
`Assert.Failure "false fails"` exception.

```sml {file=assert_test.sml}
structure AssertTest : SUITE = struct
  val assert_bangbang_true_test =
    Test.new "assert_bangbang_true_test"
             (fn () =>
                 Assert.!! true "true should not fail");

  val assert_bangbang_false_test =
    Test.new "assert_bangbang_false_test"
             (fn () =>
                 let
                   val msg = "false fails";
                 in
                   Assert.!! false msg
                   handle (Assert.Failure s) =>
                          Assert.eq msg s ("EXPECTED: " ^
                                           msg ^
                                           "\nACTUAL: " ^
                                           s ^
                                           "\n")
                 end);

  val suite = Test.suite "assert_test" [
      assert_bangbang_true_test
    , assert_bangbang_false_test
    ];
end;
```

The `Assert.eq` function is just an abbreviation for `Assert.!!`, so
there's no need to test it.

</details>

The implementation for this plan is equally as simple:

```sml {file="assert.sml"}
structure Assert :> ASSERT = struct
  exception Failure of string;

  fun !! is_success fail_msg =
    if is_success then ()
    else raise Failure fail_msg;

  fun eq expected actual fail_msg =
    !! (expected = actual) fail_msg;
end;
```



<footer>

**[** [Up](./index.md) **|** [Next](./test.md) **]**

</footer>
