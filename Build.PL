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
            #     mailto => 'mysqldiff@adamspiers.org',
            # },
            #bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Stow',

            # Module::Build forces us to use v1.4 of the CPAN Meta Spec:
            # https://rt.cpan.org/Ticket/Display.html?id=71502
            # repository => {
            #     url  => 'git:github.com/aspiers/stow.git',
            #     web  => 'http://github.com/aspiers/stow',
            #     type => 'git',
            # },
            repository => 'http://github.com/aspiers/stow',
            #repository => 'https://savannah.gnu.org/git/?group=stow',
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
    },
);

$build->create_build_script();
