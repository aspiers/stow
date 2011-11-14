#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Stow'); }

is(Stow::RelativePath("/",      "/a"),         "a");
is(Stow::RelativePath("/",      "/a/b"),       "a/b");
is(Stow::RelativePath("/",      "/"),          ".");

is(Stow::RelativePath("/a",     "/a"),         ".");
is(Stow::RelativePath("/a",     "/a/b"),       "b");
is(Stow::RelativePath("/a",     "/a/b/c"),     "b/c");
is(Stow::RelativePath("/a",     "/"),          "..");
is(Stow::RelativePath("/a",     "/b"),         "../b");
is(Stow::RelativePath("/a",     "/b/c"),       "../b/c");

is(Stow::RelativePath("/a/b/c", "/a/b"),       "..");
is(Stow::RelativePath("/a/b/c", "/a"),         "../..");
is(Stow::RelativePath("/a/b/c", "/a/b/c/d"),   "d");
is(Stow::RelativePath("/a/b/c", "/a/b/c/d/e"), "d/e");
is(Stow::RelativePath("/a/b/c", "/a/b/d"),     "../d");
is(Stow::RelativePath("/a/b/c", "/a/b/d/e"),   "../d/e");
is(Stow::RelativePath("/a/b/c", "/a/d"),       "../../d");
is(Stow::RelativePath("/a/b/c", "/a/d/e"),     "../../d/e");

is(Stow::RelativePath("a", "a"),               ".");
is(Stow::RelativePath("a", "a/b"),             "b");
is(Stow::RelativePath("a", "a/b/c"),           "b/c");
is(Stow::RelativePath("a", "b"),               "../b");
is(Stow::RelativePath("a", "b/c"),             "../b/c");

eval { Stow::RelativePath("a", "/") };
like($@, qr/Both paths must be/);

done_testing();
