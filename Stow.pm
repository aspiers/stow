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
# $Id$
# $Source$
# $Date$
# $Author$

#####################################################################
# Wed Nov 23 2005 Adam Spiers <stow@adamspiers.org>
# Hacked to ignore anything listed in ~/.cvsignore
#
# Thu Dec 29 2005 Adam Spiers <stow@adamspiers.org>
# Hacked into a Perl module
#####################################################################

use strict;
use warnings;

use File::Spec;
use FindBin qw($RealBin $RealScript);
use Getopt::Long;

use lib "$RealBin/../lib/perl5";
use Sh 'glob_to_re';
my $ignore_file = File::Spec->join($ENV{HOME}, ".cvsignore");
my $ignore_re = get_ignore_re_from_file($ignore_file);

require 5.005;

our %opts;

sub SetOptions {
  %opts = @_;
}

sub Init {
  # Changing dirs helps a lot when soft links are used
  my $current_dir = &getcwd;
  if ($opts{stow}) {
    chdir($opts{stow}) || die "Cannot chdir to target tree $opts{stow} ($!)\n";
  }

  # This prevents problems if $opts{target} was supplied as a relative path
  $opts{stow} = &getcwd;

  chdir($current_dir) || die "Your directory does not seem to exist anymore ($!)\n";

  $opts{target} = Stow::parent($opts{stow}) unless $opts{target};

  chdir($opts{target}) || die "Cannot chdir to target tree $opts{target} ($!)\n";
  $opts{target} = &getcwd;
}

sub CheckCollections {
  foreach my $package (@_) {
    $package =~ s,/+$,,;		# delete trailing slashes
    if ($package =~ m,/,) {
      die "$RealScript: slashes not permitted in package names\n";
    }
  }
}

sub CommonParent {
  my($dir1, $dir2) = @_;
  my($result, $x);
  my(@d1) = split(/\/+/, $dir1);
  my(@d2) = split(/\/+/, $dir2);

  while (@d1 && @d2 && (($x = shift(@d1)) eq shift(@d2))) {
    $result .= "$x/";
  }
  chop($result);
  return $result;
}

# Find the relative patch between
# two paths given as arguments.

sub RelativePath {
  my($a, $b) = @_;
  my($c) = &CommonParent($a, $b);
  my(@a) = split(/\/+/, $a);
  my(@b) = split(/\/+/, $b);
  my(@c) = split(/\/+/, $c);

  # if $c == "/something", scalar(@c) >= 2
  # but if $c == "/", scalar(@c) == 0
  # but we want 1
  my $length = scalar(@c) ? scalar(@c) : 1;
  splice(@a, 0, $length);
  splice(@b, 0, $length);

  unshift(@b, (('..') x (@a + 0)));
  &JoinPaths(@b);
}

# Basically concatenates the paths given
# as arguments

sub JoinPaths {
  my(@paths, @parts);
  my ($x, $y);
  my($result) = '';

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

sub Unstow {
  my($targetdir, $stow, $Collections) = @_;
  my($pure, $othercollection) = (1, '');
  my($subpure, $subother);
  my($empty) = (1);
  my(@puresubdirs);

  return (0, '') if (&JoinPaths($opts{target}, $targetdir) eq $opts{stow});
  return (0, '') if (-e &JoinPaths($opts{target}, $targetdir, '.stow'));
  warn sprintf("Unstowing in %s\n", &JoinPaths($opts{target}, $targetdir))
    if ($opts{verbose} > 1);
  my $dir = &JoinPaths($opts{target}, $targetdir);
  if (!opendir(DIR, $dir)) {
    warn "Warning: $RealScript: Cannot read directory \"$dir\" ($!). Stow might leave some links. If you think, it does. Rerun Stow with appropriate rights.\n";
  }	
  my @contents = readdir(DIR);
  closedir(DIR);
  foreach my $content (@contents) {
    next if (($content eq '.') || ($content eq '..'));
    $empty = 0;
    if (-l &JoinPaths($opts{target}, $targetdir, $content)) {
      (my $linktarget = readlink(&JoinPaths($opts{target},
					 $targetdir,
					 $content)))
	|| die sprintf("%s: Cannot read link %s (%s)\n",
		       $RealScript,
		       &JoinPaths($opts{target}, $targetdir, $content),
		       $!);
      if (my $stowmember = &FindStowMember(&JoinPaths($opts{target},
						   $targetdir),
					$linktarget)) {
	my @stowmember = split(/\/+/, $stowmember);
	my $collection = shift(@stowmember);
	if (grep(($collection eq $_), @$Collections)) {
	  &DoUnlink(&JoinPaths($opts{target}, $targetdir, $content));
	} elsif ($pure) {
	  if ($othercollection) {
	    $pure = 0 if ($collection ne $othercollection);
	  } else {
	    $othercollection = $collection;
	  }
	}
      } else {
	$pure = 0;
      }
    } elsif (-d &JoinPaths($opts{target}, $targetdir, $content)) {
      ($subpure, $subother) = &Unstow(&JoinPaths($targetdir, $content),
				      &JoinPaths('..', $stow));
      if ($subpure) {
	push(@puresubdirs, "$content/$subother");
      }
      if ($pure) {
	if ($subpure) {
	  if ($othercollection) {
	    if ($subother) {
	      if ($othercollection ne $subother) {
		$pure = 0;
	      }
	    }
	  } elsif ($subother) {
	    $othercollection = $subother;
	  }
	} else {
	  $pure = 0;
	}
      }
    } else {
      $pure = 0;
    }
  }
  # This directory was an initially empty directory therefore
  # We do not remove it.
  $pure = 0 if $empty;
  if ((!$pure || !$targetdir) && @puresubdirs) {
    &CoalesceTrees($targetdir, $stow, @puresubdirs);
  }
  ($pure, $othercollection);
}

sub CoalesceTrees {
  my($parent, $stow, @trees) = @_;

  foreach my $x (@trees) {
    my ($tree, $collection) = ($x =~ /^(.*)\/(.*)/);
    &EmptyTree(&JoinPaths($opts{target}, $parent, $tree));
    &DoRmdir(&JoinPaths($opts{target}, $parent, $tree));
    if ($collection) {
      &DoLink(&JoinPaths($stow, $collection, $parent, $tree),
	      &JoinPaths($opts{target}, $parent, $tree));
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

  warn "Stowing contents of $dir\n" if ($opts{verbose} > 1);
  my $joined = &JoinPaths($opts{stow}, $dir);
  opendir(DIR, $joined)
    || die "$RealScript: Cannot read directory \"$dir\" ($!)\n";
  my @contents = readdir(DIR);
  closedir(DIR);
  foreach my $content (@contents) {
    # Wed Nov 23 2005 Adam Spiers
    # hack to ignore stuff in ~/.cvsignore
    next if $content eq '.' or $content eq '..';
    if ($content =~ $ignore_re) {
      # FIXME: We assume -r implies the open succeeded but this is not
      # true if we're stowing cvs as .cvsignore only gets created
      # halfway through.
      warn "Ignoring $joined/$content", (-r $ignore_file ? " via $ignore_file" : ""), "\n"
        if $opts{verbose} > 2;
      next;
    }
    if (-d &JoinPaths($opts{stow}, $dir, $content)) {
      &StowDir(&JoinPaths($dir, $content), $stow);
    } else {
      &StowNondir(&JoinPaths($dir, $content), $stow);
    }
  }
}

sub StowDir {
  my($dir, $stow) = @_;
  my(@dir) = split(/\/+/, $dir);
  my($collection) = shift(@dir);
  my($subdir) = join('/', @dir);
  my($linktarget, $stowsubdir);

  warn "Stowing directory $dir\n" if ($opts{verbose} > 1);
  if (-l &JoinPaths($opts{target}, $subdir)) {
    ($linktarget = readlink(&JoinPaths($opts{target}, $subdir)))
      || die sprintf("%s: Could not read link %s (%s)\n",
		     $RealScript,
		     &JoinPaths($opts{target}, $subdir),
		     $!);
    ($stowsubdir =
     &FindStowMember(sprintf('%s/%s', $opts{target},
			     join('/', @dir[0..($#dir - 1)])),
		     $linktarget))
      || (&Conflict($dir, $subdir, 1), return);
    if (-e &JoinPaths($opts{stow}, $stowsubdir)) {
      if ($stowsubdir eq $dir) {
	warn sprintf("%s already points to %s\n",
		     &JoinPaths($opts{target}, $subdir),
		     &JoinPaths($opts{stow}, $dir))
	  if ($opts{verbose} > 2);
	return;
      }
      if (-d &JoinPaths($opts{stow}, $stowsubdir)) {
	&DoUnlink(&JoinPaths($opts{target}, $subdir));
	&DoMkdir(&JoinPaths($opts{target}, $subdir));
	&StowContents($stowsubdir, &JoinPaths('..', $stow));
	&StowContents($dir, &JoinPaths('..', $stow));
      } else {
	(&Conflict($dir, $subdir, 2), return);
      }
    } else {
      &DoUnlink(&JoinPaths($opts{target}, $subdir));
      &DoLink(&JoinPaths($stow, $dir),
	      &JoinPaths($opts{target}, $subdir));
    }
  } elsif (-e &JoinPaths($opts{target}, $subdir)) {
    if (-d &JoinPaths($opts{target}, $subdir)) {
      &StowContents($dir, &JoinPaths('..', $stow));
    } else {
      &Conflict($dir, $subdir, 3);
    }
  } else {
    &DoLink(&JoinPaths($stow, $dir),
	    &JoinPaths($opts{target}, $subdir));
  }
}

sub StowNondir {
  my($file, $stow) = @_;
  my(@file) = split(/\/+/, $file);
  my($collection) = shift(@file);
  my($subfile) = join('/', @file);
  my($linktarget, $stowsubfile);

  if (-l &JoinPaths($opts{target}, $subfile)) {
    ($linktarget = readlink(&JoinPaths($opts{target}, $subfile)))
      || die sprintf("%s: Could not read link %s (%s)\n",
		     $RealScript,
		     &JoinPaths($opts{target}, $subfile),
		     $!);
    ($stowsubfile =
     &FindStowMember(sprintf('%s/%s', $opts{target},
			     join('/', @file[0..($#file - 1)])),
		     $linktarget))
      || (&Conflict($file, $subfile, 4), return);
    if (-e &JoinPaths($opts{stow}, $stowsubfile)) {
      (&Conflict($file, $subfile, 5), return)
	unless ($stowsubfile eq $file);
      warn sprintf("%s already points to %s\n",
		   &JoinPaths($opts{target}, $subfile),
		   &JoinPaths($opts{stow}, $file))
	if ($opts{verbose} > 2);
    } else {
      &DoUnlink(&JoinPaths($opts{target}, $subfile));
      &DoLink(&JoinPaths($stow, $file),
	      &JoinPaths($opts{target}, $subfile));
    }
  } elsif (-e &JoinPaths($opts{target}, $subfile)) {
    &Conflict($file, $subfile, 6);
  } else {
    &DoLink(&JoinPaths($stow, $file),
	    &JoinPaths($opts{target}, $subfile));
  }
}

sub DoUnlink {
  my($file) = @_;

  warn "UNLINK $file\n" if $opts{verbose};
  (unlink($file) || die "$RealScript: Could not unlink $file ($!)\n")
    unless $opts{not_really};
}

sub DoRmdir {
  my($dir) = @_;

  warn "RMDIR $dir\n" if $opts{verbose};
  (rmdir($dir) || die "$RealScript: Could not rmdir $dir ($!)\n")
    unless $opts{not_really};
}

sub DoLink {
  my($target, $name) = @_;

  warn "LINK $name to $target\n" if $opts{verbose};
  (symlink($target, $name) ||
   die "$RealScript: Could not symlink $name to $target ($!)\n")
    unless $opts{not_really};
}

sub DoMkdir {
  my($dir) = @_;

  warn "MKDIR $dir\n" if $opts{verbose};
  (mkdir($dir, 0777)
   || die "$RealScript: Could not make directory $dir ($!)\n")
    unless $opts{not_really};
}

sub Conflict {
  my($a, $b, $type) = @_;

  my $src = &JoinPaths($opts{stow}, $a);
  my $dst = &JoinPaths($opts{target}, $b);

  if ($opts{conflicts}) {
    warn "CONFLICT: $src vs. $dst", ($type ? " ($type)" : ''), "\n";
    #system "ls -l $src $dst";
  } else {
    die "$RealScript: CONFLICT: $src vs. $dst", ($type ? " ($type)" : ''), "\n";
  }
}

sub FindStowMember {
  my($start, $path) = @_;
  my(@x) = split(/\/+/, $start);
  my(@path) = split(/\/+/, $path);
  my($x);
  my(@d) = split(/\/+/, $opts{stow});

  while (@path) {
    $x = shift(@path);
    if ($x eq '..') {
      pop(@x);
      return '' unless @x;
    } elsif ($x) {
      push(@x, $x);
    }
  }
  while (@x && @d) {
    if (($x = shift(@x)) ne shift(@d)) {
      return '';
    }
  }
  return '' if @d;
  return join('/', @x);
}

sub parent {
  my($path) = join('/', @_);
  my(@elts) = split(/\/+/, $path);
  pop(@elts);
  return join('/', @elts);
}

sub get_ignore_re_from_file {
  my ($file) = @_;
  # Bootstrap issue - first time we stow, we will be stowing
  # .cvsignore so it won't exist in ~ yet.  At that time, use
  # a sensible default instead.
  open(REGEXPS, $file) or return qr!\.cfgsave\.|^(CVS)$!;
  my @regexps;
  while (<REGEXPS>) {
    chomp;
    push @regexps, glob_to_re($_);
  }
  close(REGEXPS);
  my $re = join '|', @regexps;
  warn "#% ignore regexp is $re\n" if $opts{verbose};
  return qr/$re/;
}

1;
