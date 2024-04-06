[![Build Status](https://travis-ci.org/aspiers/stow.svg)](https://travis-ci.org/aspiers/stow)
[![Coverage Status](https://coveralls.io/repos/aspiers/stow/badge.svg?branch=master&service=github)](https://coveralls.io/github/aspiers/stow?branch=master)

README for GNU Stow
===================

This README describes GNU Stow.  This is not the definitive
documentation for Stow; for that, see the [info
manual](https://www.gnu.org/software/stow/manual/).

Stow is a symlink farm manager program which takes distinct sets
of software and/or data located in separate directories on the
filesystem, and makes them all appear to be installed in a single
directory tree.

Originally Stow was born to address the need to administer, upgrade,
install, and remove files in independent software packages without
confusing them with other files sharing the same file system space.
For instance, many years ago it used to be common to compile programs
such as Perl and Emacs from source and install them in `/usr/local`.
By using Stow, `/usr/local/bin` could contain symlinks to files within
`/usr/local/stow/emacs/bin`, `/usr/local/stow/perl/bin` etc., and
likewise recursively for any other subdirectories such as `.../share`,
`.../man`, and so on.

While this is useful for keeping track of system-wide and per-user
installations of software built from source, in more recent times
software packages are often managed by more sophisticated package
management software such as
[`rpm`](https://en.wikipedia.org/wiki/Rpm_(software)),
[`dpkg`](https://en.wikipedia.org/wiki/Dpkg), and
[Nix](https://en.wikipedia.org/wiki/Nix_package_manager) / [GNU
Guix](https://en.wikipedia.org/wiki/GNU_Guix), or language-native
package managers such as Ruby's
[`gem`](https://en.wikipedia.org/wiki/RubyGems), Python's
[`pip`](https://en.wikipedia.org/wiki/Pip_(package_manager)),
Javascript's [`npm`](https://en.wikipedia.org/wiki/Npm_(software)),
and so on.

However Stow is still used not only for software package management,
but also for other purposes, such as facilitating [a more controlled
approach to management of configuration files in the user's home
directory](http://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html),
especially when [coupled with version control
systems](http://lists.gnu.org/archive/html/info-stow/2011-12/msg00000.html).

Stow was inspired by Carnegie Mellon's Depot program, but is
substantially simpler and safer.  Whereas Depot required database files
to keep things in sync, Stow stores no extra state between runs, so
there's no danger (as there was in Depot) of mangling directories when
file hierarchies don't match the database.  Also unlike Depot, Stow will
never delete any files, directories, or links that appear in a Stow
directory (e.g., `/usr/local/stow/emacs`), so it's always possible
to rebuild the target tree (e.g., `/usr/local`).

Stow is implemented as a combination of a Perl script providing a CLI
interface, and a backend Perl module which does most of the work.

You can get the latest information about Stow from the home page:

    http://www.gnu.org/software/stow/

Installation
------------

See [`INSTALL.md`](INSTALL.md) for installation instructions.

Documentation
-------------

Documentation for Stow is available
[online](https://www.gnu.org/software/stow/manual/), as is
[documentation for most GNU
software](https://www.gnu.org/software/manual/).  Once you have Stow
installed, you may also find more information about Stow by running
`info stow` or `man stow`, or by looking at `/usr/share/doc/stow/`,
`/usr/local/doc/stow/`, or similar directories on your system.  A
brief summary is available by running `stow --help`.

Mailing lists
-------------

Stow has the following mailing lists:

-   [help-stow](https://lists.gnu.org/mailman/listinfo/help-stow) is for
    general user help and discussion.
-   [stow-devel](https://lists.gnu.org/mailman/listinfo/stow-devel) is
    used to discuss most aspects of Stow, including development and
    enhancement requests.
-   [bug-stow](https://lists.gnu.org/mailman/listinfo/bug-stow) is for
    bug reports.

Announcements about Stow are posted to
[info-stow](http://lists.gnu.org/mailman/listinfo/info-stow) and also,
as with most other GNU software, to
[info-gnu](http://lists.gnu.org/mailman/listinfo/info-gnu)
([archive](http://lists.gnu.org/archive/html/info-gnu/)).

Security reports that should not be made immediately public can be
sent directly to the maintainer.  If there is no response to an urgent
issue, you can escalate to the general
[security](http://lists.gnu.org/mailman/listinfo/security) mailing
list for advice.

The Savannah project also has a [mailing
lists](https://savannah.gnu.org/mail/?group=stow) page.

Getting involved
----------------

Please see the [`CONTRIBUTING.md` file](CONTRIBUTING.md).

License
-------

Stow is free software, licensed under the GNU General Public License,
which can be found in the file [`COPYING`](COPYING).

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty provided the copyright
notice and this notice are preserved.  This file is offered as-is,
without any warranty.

Brief history and authorship
----------------------------

Stow was inspired by Carnegie Mellon's "Depot" program, but is
substantially simpler.  Whereas Depot requires database files to keep
things in sync, Stow stores no extra state between runs, so there's no
danger (as there is in Depot) of mangling directories when file
hierarchies don't match the database.  Also unlike Depot, Stow will
never delete any files, directories, or links that appear in a Stow
directory (e.g., `/usr/local/stow/emacs`), so it's always possible to
rebuild the target tree (e.g., `/usr/local`).

For a high-level overview of the contributions of the main developers
over the years, see [the `AUTHORS` file](AUTHORS).

For a more detailed history, please see the `ChangeLog` file.
