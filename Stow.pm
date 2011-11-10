#!/usr/bin/perl

# GNU Stow - manage the installation of multiple software packages
# Copyright (C) 1993, 1994, 1995, 1996 by Bob Glickstein
# Copyright (C) 2000,2001 Guillaume Morin
# Copyright (C) 2005 Adam Spiers
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
# 

#####################################################################
# Wed Nov  9 2011 Adam Spiers <stow@adamspiers.org>
# Added support for stow local/global ignore files rather
# than depending on .cvsignore.
#
# Wed Nov 23 2005 Adam Spiers <stow@adamspiers.org>
# Hacked to ignore anything listed in ~/.cvsignore
#
# Thu Dec 29 2005 Adam Spiers <stow@adamspiers.org>
# Hacked into a Perl module
#####################################################################

package Stow;

use strict;
use warnings;

use File::Spec;
use FindBin qw($RealBin $RealScript);
use Getopt::Long;
use POSIX;

use lib "$RealBin/../lib/perl5";

require 5.6.0;

my $LOCAL_IGNORE_FILE         = '.stow-local-ignore';
my $GLOBAL_IGNORE_FILE        = '.stow-global-ignore';
my $defaultGlobalIgnoreRegexp = &GetDefaultGlobalIgnoreRegexp();

my $verbosity = 0;
my $dry_run   = 0;
my $prune     = 0;
my $conflicts = 0;
my $target_dir;
my $stow_dir;

sub SetOptions {
  my %opts = @_;
  $verbosity  = $opts{verbose};
  $target_dir = $opts{target};
  $stow_dir   = $opts{stow};
  $dry_run    = $opts{not_really};
  $prune      = $opts{prune};
  $conflicts  = $opts{conflicts};
}

sub CheckCollections {
  foreach my $package (@_) {
    $package =~ s,/+$,,;		# delete trailing slashes
    if ($package =~ m,/,) {
      die "$RealScript: slashes not permitted in package names ($package)\n";
    }
  }
}

sub CommonParent {
  my($dir1, $dir2) = @_;
  my $result = '';
  my(@d1) = split(/\/+/, $dir1);
  my(@d2) = split(/\/+/, $dir2);

  while (@d1 && @d2 && ((my $x = shift(@d1)) eq shift(@d2))) {
    $result .= "$x/";
  }
  return '/' if ! $result and $dir1 =~ m!^/! and $dir2 =~ m!^/!;
  chop($result);
  return $result;
}

# Find the relative path to $b from $a
sub RelativePath {
  my($a, $b) = @_;

  die "Both paths must be relative or absolute"
    if substr($a, 0, 1) ne '/' and substr($b, 0, 1) eq '/';

  return '.' if $a eq $b;

  my($c) = &CommonParent($a, $b);
  my(@a) = split(/\/+/, $a);
  my(@b) = split(/\/+/, $b);
  my(@c) = split(/\/+/, $c);

  # get rid of any empty 1st element due to absolute paths
  shift @a if substr($a, 0, 1) eq '/';
  shift @b if substr($b, 0, 1) eq '/';
  shift @c if substr($c, 0, 1) eq '/';

  # Trim common path segments from @c off @a and @b
  #
  # If $c == "/something", scalar(@c) == 1 after shift @c
  # If $c == "/something/else", scalar(@c) == 2 after shift @c
  # So in general, trim scalar(@c) segments off @a and @b
  my $length = @c;
  # but if $c eq "/", scalar(@c) == 0 but we want to remove the first undef:
  #$length = 1 if $c eq "/";
  # otherwise if $c eq "" we must have been dealing with at least one relative path:
  #$length = 1 if $c eq "";
  # and if $a eq $b, we want to keep the last element:
  $length-- if $a eq $b;
  splice @a, 0, $length;
  splice @b, 0, $length;

  unshift @b, (('..') x scalar(@a));
  return &JoinPaths(@b);
}

# Concatenates the paths given as arguments, removing double and
# trailing slashes.  Is subtlely different from File::Spec::join
# in other aspects, e.g. args ('', '/foo') yields 'foo' not '/foo'.
sub JoinPaths {
  my(@paths, @parts);
  my ($x, $y);
  my($result) = '';
  use Carp qw(carp cluck croak confess);
  confess "nothing to join" unless defined $_[0];

  $result = '/' if ($_[0] =~ /^\//);
  foreach $x (@_) {
    @parts = split(/\/+/, $x);
    foreach $y (@parts) {
      push(@paths, $y) if ($y ne "");
    }
  }
  $result .= join('/', @paths);
  return $result;
}

# This removes stow-controlled symlinks from $targetdir for the
# packages in the %$PkgsToUnstow hash, and is called recursively to
# process subdirectories.

sub Unstow {
  my($targetdir, $stow, $PkgsToUnstow) = @_;
  # $targetdir is the directory we're unstowing in, relative to the
  # top of the target hierarchy, i.e. $target_dir.
  #
  # $stow is the stow directory (the one containing the source
  # packages), and is always relative to $targetdir.  So as we
  # recursively descend into $target_dir, $stow gets longer because
  # we have to move up out of that hierarchy and back into the stow
  # directory.

  # Does this whole subtree only contain symlinks to a *single*
  # package collection *other* than one we are removing?  We assume so
  # and scan the tree recursively until we find out otherwise.  We
  # have to track this because if a subtree is found to be pure, we
  # can fold it into a single symlink.
  my $pure = 1;

  # If the directory is pure, we need to know which single other
  # package collection the contained symlinks point to, so we know how
  # to do our tree folding.
  my $othercollection = '';

  # We assume $targetdir is empty until we find something.
  my $empty = 1;

  my $targetdirPath = &JoinPaths($target_dir, $targetdir);

  return (0, '') if    $targetdirPath eq $stow_dir;
  return (0, '') if -e &JoinPaths($targetdirPath, '.stow');

  warn "Unstowing in $targetdirPath\n"
    if $verbosity > 1;

  if (!opendir(DIR, $targetdirPath)) {
    warn "Warning: $RealScript: Cannot read directory \"$targetdirPath\" ($!). Stow might leave some links. If you think, it does. Rerun Stow with appropriate rights.\n";
  }	
  my @contents = readdir(DIR);
  closedir(DIR);

  my @puresubdirs;
  foreach my $content (@contents) {
    next if ($content eq '.') || ($content eq '..');
    $empty = 0;
    my $contentPath = &JoinPaths($targetdirPath, $content);
    if (-l $contentPath) {
      # We found a link; now let's see if we should remove it.
      my $linktarget = readlink $contentPath;
      $linktarget or die "$RealScript: Cannot read link $contentPath ($!)\n";

      # Does the link point to somewhere within the stow directory?
      my $stowmember = &FindStowMember(
        $targetdirPath,
        $linktarget,
      );
      
      if ($stowmember) {
        # Yes it does, but does it point within one of the package
        # collections we are unstowing?
	my @stowmember = split(/\/+/, $stowmember);
	my $collection = shift(@stowmember);
	if ($PkgsToUnstow->{$collection}) {
          # Yep, so get rid of it.
	  &DoUnlink($contentPath);
	} else {
          # No, it points to another package collection.  Is there
          # still a chance this directory is pure and can be folded?
          if ($pure) {
            # Yes, so keep track of whether symlinks in the directory
            # point to more than one collection.
            if ($othercollection) {
              # More than one collection means impure => no folding possible.
              $pure = 0 if $collection ne $othercollection;
            } else {
              # This is the first reference to another collection
              # we've seen, so remember it for future comparison with
              # other symlink targets.
              $othercollection = $collection;
            }
          }
        }
      } else {
        # Link points outside the stow directory, therefore is not
        # managed by stow and cannot be touched.  So tree folding will
        # not be possible.
	$pure = 0;
      }
    }
    elsif (-d $contentPath && ! &PruneTree($targetdir, $content, $PkgsToUnstow)) {
      # recurse
      my ($subpure, $subother) = &Unstow(
        &JoinPaths($targetdir, $content),
        &JoinPaths('..', $stow),
        $PkgsToUnstow,
      );
      if ($subpure) {
	push @puresubdirs, "$content/$subother";
      }
      else {
        # Subtree is impure therefore this directory is impure.
        $pure = 0;
      }
      if ($pure && $subpure) {
        if ($othercollection) {
          # We already found a single other package collection
          # somewhere in this subtree but outside $contentPath.
          if ($subother and $othercollection ne $subother) {
            # Two collections pointed to from within one subtree,
            # so no tree folding will be possible.
            $pure = 0;
          }
        } elsif ($subother) {
          # This is the first other package collection we've found;
          # remember it as before for future comparison with other
          # symlinks.
          $othercollection = $subother;
        }
      }
    } else {
      # Current directory contains something other than a symlink or a
      # directory, therefore folding is not going to be possible.
      $pure = 0;
    }
  }
  # This directory was an initially empty directory therefore
  # we do not remove it.
  $pure = 0 if $empty;
  if ((!$pure || !$targetdir) && @puresubdirs) {
    &CoalesceTrees($targetdir, $stow, @puresubdirs);
  }
  return ($pure, $othercollection);
}

sub PruneTree {
  my ($targetdir, $subdir, $PkgsToUnstow) = @_;

  return 0 unless $prune;
  my $relpath = &JoinPaths($targetdir, $subdir);

  foreach my $pkg (keys %$PkgsToUnstow) {
    my $abspath = &JoinPaths($stow_dir, $pkg, $relpath);
    if (-d $abspath) {
      warn "# Not pruning $relpath since -d $abspath\n" if $verbosity > 4;
      return 0;
    }
  }
  warn "# Pruning $relpath\n" if $verbosity > 2;
  return 1;
}

# This is the tree folding which the stow manual refers to.
sub CoalesceTrees {
  my($parent, $stow, @trees) = @_;

  foreach my $x (@trees) {
    my ($tree, $collection) = ($x =~ /^(.*)\/(.*)/);
    &EmptyTree(&JoinPaths($target_dir, $parent, $tree));
    &DoRmdir(&JoinPaths($target_dir, $parent, $tree));
    if ($collection) {
      &DoLink(&JoinPaths($stow, $collection, $parent, $tree),
	      &JoinPaths($target_dir, $parent, $tree));
    }
  }
}

sub EmptyTree {
  my($dir) = @_;

  opendir(DIR, $dir)
    || die "$RealScript: Cannot read directory \"$dir\" ($!)\n";
  my @contents = readdir(DIR);
  closedir(DIR);
  foreach my $content (@contents) {
    next if (($content eq '.') || ($content eq '..'));
    if (-l &JoinPaths($dir, $content)) {
      &DoUnlink(&JoinPaths($dir, $content));
    } elsif (-d &JoinPaths($dir, $content)) {
      &EmptyTree(&JoinPaths($dir, $content));
      &DoRmdir(&JoinPaths($dir, $content));
    } else {
      &DoUnlink(&JoinPaths($dir, $content));
    }
  }
}

sub StowContents {
  my($dir, $stow) = @_;

  warn "Stowing contents of $dir\n" if $verbosity > 1;
  my $joined = &JoinPaths($stow_dir, $dir);
  opendir(DIR, $joined)
    || die "$RealScript: Cannot read directory \"$dir\" ($!)\n";
  my @contents = readdir(DIR);
  closedir(DIR);
  my $ignoreRegexp = &GetIgnoreRegexp($joined);
  die "ignore: $ignoreRegexp";
  foreach my $content (@contents) {
    next if $content eq '.' or $content eq '..';
    if ($content =~ $ignoreRegexp) {
      warn "Ignoring $joined/$content\n" if $verbosity > 2;
      next;
    }
    if (-d &JoinPaths($stow_dir, $dir, $content)) {
      &StowDir(&JoinPaths($dir, $content), $stow);
    } else {
      &StowNondir(&JoinPaths($dir, $content), $stow);
    }
  }
}

sub GetIgnoreRegexp {
  my($dir) = @_;

  # N.B. the local and global stow ignore files have to have different
  # names so that:
  #   1. the global one can be a symlink to within a stow
  #      package, managed by stow itself, and
  #   2. the local ones can be ignored via hardcoded logic in
  #      GlobsToRegexp(), so that they always stay within their stow packages.
  
  my $local_stow_ignore  = &JoinPaths($stow_dir, $dir, $LOCAL_IGNORE_FILE);
  my $global_stow_ignore = &JoinPaths($ENV{HOME}, $GLOBAL_IGNORE_FILE);
  my $cvs_ignore         = &JoinPaths($ENV{HOME}, ".cvsignore");

  for my $file ($local_stow_ignore, $global_stow_ignore, $cvs_ignore) {
    return &GetIgnoreRegexpFromFile($file) if -e $file;
  }
  return $defaultGlobalIgnoreRegexp;
}

sub StowDir {
  my($dir, $stow) = @_;
  my @dir = split(/\/+/, $dir);
  my $collection = shift(@dir);
  my $subdir = &JoinPaths('/', @dir);

  warn "Stowing directory $dir\n" if ($verbosity > 1);

  my $targetSubdirPath = &JoinPaths($target_dir, $subdir);
  if (-l $targetSubdirPath) {
    # We found a link; now let's see if we should remove it.
    my $linktarget = readlink($targetSubdirPath);
    $linktarget or die "$RealScript: Could not read link $targetSubdirPath ($!)\n";

    # Does the link point to somewhere within the stow directory?
    my $stowsubdir = &FindStowMember(
      &JoinPaths($target_dir, @dir[0..($#dir - 1)]),
      $linktarget,
    );
    unless ($stowsubdir) {
      # No, so we can't touch it.
      &Conflict($dir, $subdir,
                &AbbrevHome($targetSubdirPath)
                . " link doesn't point within stow dir; cannot split open");
      return;
    }

    # Yes it does.
    my $stowSubdirPath = &JoinPaths($stow_dir, $stowsubdir);
    if (-e $stowSubdirPath) {
      if ($stowsubdir eq $dir) {
	warn "$targetSubdirPath already points to $stowSubdirPath\n"
	  if $verbosity > 2;
	return;
      }
      if (-d $stowSubdirPath) {
        # This is the splitting open of a folded tree which the stow
        # manual refers to.
	&DoUnlink($targetSubdirPath);
	&DoMkdir($targetSubdirPath);
	&StowContents($stowsubdir, &JoinPaths('..', $stow));
	&StowContents($dir, &JoinPaths('..', $stow));
      } else {
	&Conflict($dir, $subdir,
                  &AbbrevHome($stowSubdirPath)
                  . " exists but not a directory");
        return;
      }
    } else {
      &DoUnlink($targetSubdirPath);
      &DoLink(&JoinPaths($stow, $dir),
	      $targetSubdirPath);
    }
  } elsif (-e $targetSubdirPath) {
    if (-d $targetSubdirPath) {
      &StowContents($dir, &JoinPaths('..', $stow));
    } else {
      &Conflict($dir, $subdir,
                &AbbrevHome($targetSubdirPath)
                . " exists but not a directory");
    }
  } else {
    &DoLink(&JoinPaths($stow, $dir),
	    $targetSubdirPath);
  }
}

sub StowNondir {
  my($file, $stow) = @_;
  my(@file) = split(/\/+/, $file);
  my($collection) = shift(@file);
  my($subfile) = &JoinPaths(@file);

  my $subfilePath = &JoinPaths($target_dir, $subfile);
  if (-l $subfilePath) {
    my $linktarget = readlink($subfilePath);
    $linktarget or die "$RealScript: Could not read link $subfilePath ($!)\n";
    my $stowsubfile = &FindStowMember(
      &JoinPaths($target_dir, @file[0..($#file - 1)]),
      $linktarget
    );
    if (! $stowsubfile) {
      &Conflict($file, $subfile,
                &AbbrevHome($subfilePath)
                . " symlink did not point within stow dir");
      return;
    }
    if (-e &JoinPaths($stow_dir, $stowsubfile)) {
      if ($stowsubfile ne $file) {
        &Conflict($file, $subfile,
                  &AbbrevHome($subfilePath)
                  . " pointed to something else within stow dir");
        return;
      }
      warn sprintf("%s already points to %s\n",
		   $subfilePath,
		   &JoinPaths($stow_dir, $file))
	if ($verbosity > 2);
    } else {
      &DoUnlink($subfilePath);
      &DoLink(&JoinPaths($stow, $file), $subfilePath);
    }
  } elsif (-e $subfilePath) {
    &Conflict($file, $subfile,
              &AbbrevHome($subfilePath)
              . " exists but is not a symlink");
  } else {
    &DoLink(&JoinPaths($stow, $file), $subfilePath);
  }
}

sub DoUnlink {
  my($file) = @_;

  warn "UNLINK $file\n" if $verbosity;
  (unlink($file) || die "$RealScript: Could not unlink $file ($!)\n")
    unless $dry_run;
}

sub DoRmdir {
  my($dir) = @_;

  warn "RMDIR $dir\n" if $verbosity;
  (rmdir($dir) || die "$RealScript: Could not rmdir $dir ($!)\n")
    unless $dry_run;
}

sub DoLink {
  my($target, $name) = @_;

  warn "LINK $name to $target\n" if $verbosity;
  (symlink($target, $name) ||
   die "$RealScript: Could not symlink $name to $target ($!)\n")
    unless $dry_run;
}

sub DoMkdir {
  my($dir) = @_;

  warn "MKDIR $dir\n" if $verbosity;
  (mkdir($dir, 0777)
   || die "$RealScript: Could not make directory $dir ($!)\n")
    unless $dry_run;
}

sub Conflict {
  my($a, $b, $type) = @_;

  my $src = &AbbrevHome(&JoinPaths($stow_dir,   $a));
  my $dst = &AbbrevHome(&JoinPaths($target_dir, $b));

  my $msg = "CONFLICT: $src vs. $dst" . ($type ? " ($type)" : '') . "\n";
  if ($conflicts) {
    warn $msg;
    #system "ls -l $src $dst";
  } else {
    die "$RealScript: $msg";
  }
}

sub AbbrevHome {
  my($path) = @_;
  $path =~ s!^$ENV{HOME}/!~/!;
  return $path;
}

# Given an absolute starting directory and a relative path obtained by
# calling readlink() on a symlink in that starting directory,
# FindStowMember() figures out whether the symlink points to somewhere
# within the stow directory.  If so, it returns the target of the
# symlink relative to the stow directory, otherwise it returns ''.
sub FindStowMember {
  my($startDir, $targetPath) = @_;
  my @startDirSegments = split(/\/+/, $startDir);
  my @targetSegments   = split(/\/+/, $targetPath);
  my @stowDirSegments  = split(/\/+/, $stow_dir);

  # Start in $startDir and navigate to target, one path segment at a time.
  my @current = @startDirSegments;
  while (@targetSegments) {
    my $x = shift(@targetSegments);
    if ($x eq '..') {
      pop(@current);
      return '' unless @current; # We can't go higher than /, must be
                                 # an invalid symlink.
    } elsif ($x) {
      push(@current, $x);
    }
  }

  # Now @current describes the absolute path to the symlink's target,
  # so if @current and @stowDirSegments have a common prefix, the
  # symlink points within the stow directory.
  while (@current && @stowDirSegments) {
    if (shift(@current) ne shift(@stowDirSegments)) {
      return '';
    }
  }
  return '' if @stowDirSegments;
  return join('/', @current);
}

sub parent {
  my($path) = join('/', @_);
  my(@elts) = split(/\/+/, $path);
  pop(@elts);
  return join('/', @elts);
}

sub GetIgnoreGlobsFromFile {
  my ($file) = @_;
  my %globs;
  if (open(GLOBS, $file)) {
    %globs = &GetIgnoreGlobsFromFH(\*GLOBS);
    close(GLOBS);
  }
  return %globs;
}

sub GetIgnoreGlobsFromFH {
  my ($fh) = @_;
  my %globs;
  while (<$fh>) {
    chomp;
    s/^\s+//;
    s/\s+$//;
    next if /^#/ or length($_) == 0;
    s/^\\#/#/;
    $globs{$_}++;
  }
  return %globs;
}

sub GetIgnoreRegexpFromFile {
  my ($file) = @_;
  my $regexp = &GlobsToRegexp(&GetIgnoreGlobsFromFile($file));
  warn "#% ignore regexp from $file is $regexp\n";# if $verbosity;
  return $regexp;
}

sub globToRegexp {
  local $_ = shift;

  # Escape special regexp meta-characters
  s/([.+{}^\$])/\\$1/g;

  # Convert glob meta-characters to regexp
  s/\*/.*/g;
  s/\?/./g;

  # Anchor start and end
  s/^/^/;
  s/$/\$/;

  return $_;
}

sub GlobsToRegexp {
  my (%globs) = @_;

  # Local ignore lists should *always* stay within the stow directory,
  # because this is the only place stow looks for them.
  $globs{$LOCAL_IGNORE_FILE}++;

  my $re = join '|', map globToRegexp($_), keys %globs;
  warn "#% ignore regexp is $re\n" if $verbosity;
  return qr/$re/;
}

sub GetDefaultGlobalIgnoreRegexp {
  # Bootstrap issue - first time we stow, we will be stowing
  # .cvsignore so it might not exist in ~ yet, or if it does, it could
  # be an old version missing the entries we need.  So we make sure
  # they are there by hardcoding some crucial entries.
  my $regexp = &GlobsToRegexp(&GetIgnoreGlobsFromFH(\*DATA));
  return $regexp;
}

1;
__DATA__
CVS
.cvsignore
.git
.gitignore
