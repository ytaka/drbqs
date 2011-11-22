# Test and profiler

## Test

When we are developing program,
we want to execute tasks in single process and check errors.
For that purpose we use the option --test.
For example,

    drbqs-server server.rb --test exec

In order to execute only two tasks, we type

    drbqs-server server.rb --test exec,2

## Profiler

At a time we can use profiler.

    drbqs-server server.rb --test exec --profile

Then drbqs creates drbqs_prof.txt that has profile data.

To profile a program and show the result by kcachegrind,

    drbqs-server server.rb --test exec --profile --profile-printer calltree

and then

    kcachegrind drbqs_prof.txt
