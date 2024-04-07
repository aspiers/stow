Contributing to GNU Stow
========================

Development of Stow, and GNU in general, is a volunteer effort, and
you can contribute.  If you'd like to get involved, it's a good idea to join
the [stow-devel](https://lists.gnu.org/mailman/listinfo/stow-devel)
mailing list.

Bug reporting
-------------

Please follow the procedure described in [the "Reporting Bugs"
section](https://www.gnu.org/software/stow/manual/html_node/Reporting-Bugs.html#Reporting-Bugs)
of [the manual](README.md#documentation).

Development
-----------

For [development sources](https://savannah.gnu.org/git/?group=stow)
and other information, please see the [Stow project
page](http://savannah.gnu.org/projects/stow/) at
[savannah.gnu.org](http://savannah.gnu.org).

There is also a
[stow-devel](https://lists.gnu.org/mailman/listinfo/stow-devel)
mailing list (see [Mailing lists](README.md#mailing-lists)).

Please be aware that all program source files (excluding the test
suite) end in `.in`, and are pre-processed by `Makefile` into
corresponding files with that prefix stripped before execution.  So if
you want to test any modifications to the source, make sure that you
change the `.in` files and then run `make` to regenerate the
pre-processed versions before doing any testing.  To avoid forgetting
(which can potentially waste a lot of time debugging the wrong code),
you can automatically run `make` in an infinite loop every second via:

    make watch

(You could even use fancier approaches like
[`inotifywait(1)`](https://www.man7.org/linux/man-pages/man1/inotifywait.1.html)
or [Guard](https://guardgem.org/).  But those are probably overkill in
this case where the simple `while` loop is plenty good enough.)

Testing
~~~~~~~

The test suite can be found in the [`t/`](t/) subdirectory.  You can
run the test suite via:

    make check

Tests can be run individually as follows.  First you have to ensure
that the `t/`, `bin/`, and `lib/` directories are on Perl's search path.
Assuming that you run all tests from the root of the repository tree,
this will do the job:

    export PERL5LIB=t:bin:lib

(Not all tests require all of these, but it's safer to include all of
them.)

Secondly, be aware that if you want to test modifications to the
source files, you will need to run `make watch`, or `make` before each
test run as explained above.

Now running an individual test is as simple as:

    perl t/chkstow.t

or with a given debugging verbosity corresponding to the `-v` / `--verbose`
command-line option:

    TEST_VERBOSE=4 perl t/chkstow.t

The [`prove(1)` test runner](https://perldoc.perl.org/prove) is another
good alternative which provides several handy extra features.  Invocation
is very similar, e.g.:

    prove t/stow.t

or to run the whole suite:

    prove

However currently there is an issue where this interferes with
`TEST_VERBOSE`.

If you want to create test files for experimentation, it is
recommended to put them in a subdirectory called `playground/` since
this will be automatically ignored by git and the build process,
avoiding any undesirable complications.

Translating Stow
----------------

Stow is not currently multi-lingual, but patches would be very
gratefully accepted. Please e-mail
[stow-devel](https://lists.gnu.org/mailman/listinfo/stow-devel) if you
intend to work on this.

Maintainers
-----------

Stow is currently being maintained by Adam Spiers.  Please use [the
mailing lists](README.md#mailing-lists).

Helping the GNU project
-----------------------

For more general information, please read [How to help
GNU](https://www.gnu.org/help/).
