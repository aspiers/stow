# This file is part of GNU Stow.
#
# GNU Stow is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# GNU Stow is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/.

use strict;
use warnings;

use Module::Build;

# These are required by the test suite.
use lib "t";
use lib "bin";

my $build = Module::Build->new(
    module_name => 'Stow',
    keywords    => [ qw/stow symlink software package management install/ ],
    license     => 'gpl',

    # Module::Build forces us to use v1.4 of the CPAN Meta Spec:
    # https://rt.cpan.org/Ticket/Display.html?id=71502
    # 'meta-spec' =>  {
    #     version => '2.0',
    #     url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    # },
    meta_add => {
        resources => {
            license => 'http://www.gnu.org/licenses/gpl-2.0.html' ,
            homepage => 'https://savannah.gnu.org/projects/stow',

            # Module::Build forces us to use v1.4 of the CPAN Meta Spec:
            # https://rt.cpan.org/Ticket/Display.html?id=71502
            # bugtracker => {
            #     web    => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Stow',
            #     mailto => 'stow-devel@gnu.org',
            # },
            #bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Stow',

            # Module::Build forces us to use v1.4 of the CPAN Meta Spec:
            # https://rt.cpan.org/Ticket/Display.html?id=71502
            # repository => {
            #     url  => 'git://git.savannah.gnu.org/stow.git',
            #     web  => 'https://savannah.gnu.org/git/?group=stow',
            #     type => 'git',
            # },
            repository => 'git://git.savannah.gnu.org/stow.git',
        },
    },
    requires => {
        'perl'        => '5.006',
        'Carp'        => 0,
        'IO::File'    => 0,
    },
    script_files => [ 'bin/stow', 'bin/chkstow' ],
    all_from => 'lib/Stow.pm.in',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'   => 0,
        'Test::Output' => 0,
        'IO::Scalar'   => 0,
    },
);

if (system('grep', '-q', '^use lib ', 'bin/stow') >> 8 == 0) {
  die <<'EOF';

ERROR: bin/stow contains 'use lib' line which could interfere
with CPAN-style installation via Module::Build.  To avoid this,
you should run ./configure with parameters which result in
--with-pmdir's value being in Perl's built-in @INC, and then run
'make' (NOT 'make install') to regenerate bin/stow, e.g.

    eval `perl -V:siteprefix`
    ./configure --prefix=$siteprefix && make

or

    ./configure --with-pmdir=`PERL5LIB= perl -le 'print $INC[0]'` && make

Then re-run this script.

Note that these parameters are chosen purely to regenerate
bin/stow without a 'use lib' line, so don't run 'make install'
while Stow is configured in this way unless you really want an
installation using these parameters.

EOF
}

$build->create_build_script();
