This is a simple XUnit Framework for Standard ML.

# Usage in five minutes

Basically: you will write `SUITE` structures, and use
`Test.register_suite` to register the tests with the test runner.

A test case usually is constructed with `Test.new name (fn () => ...)`
where the anonymous function will invoke `Assert.!! msg_on_fail test_result`
or `Assert.eq(expected,actual,fail_msg)`.

Test suites are lists of tests, formed by `Test.suite name test_list`.

You need to register test suites for them to be run by the `struct Runner`
test runner.

The test reporter will summarize the results, print it to the screen,
save an artifact, or whatever. You can change which reporter is used
by changing the "constructor functor" from
`structure Runner :> RUNNER = MkRunner(JUnitTt);` to whatever reporter
you want: `structure Runner :> RUNNER = MkRunner(YourReporterHere);`.

The possible test reporters are a JUnit-like summarizer which prints
out any failures (and the relevant failure messages) to the screen, as
well as a summary of the number of tests run, number of failures,
etc., per suite.

If you want to roll a reporter to produce XML artifacts, you can do
that! It should be straight forward.

# License

This uses the MIT License.

# Goodbye

This is part of a larger...ecosystem? No, that's too majestic and
organized an expression. It's part of a larger project.

This library is so simple, it's hard to imagine this being a perfect
tool, but it's a "good enough" tool.
