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

Testing
~~~~~~~

The test suite can be found in the [`t/`](t/) subdirectory.  You can
run the test suite via:

    make check

Individual tests can be run as follows:

    perl -It t/stow.t

or with a given debugging verbosity corresponding to the `-v` / `--verbose`
command-line option:

    TEST_VERBOSE=4 perl -It t/stow.t

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
