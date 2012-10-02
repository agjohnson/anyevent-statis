use 5.010;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name => 'AnyEvent::Statis',
    license => 'mit',
    dist_author => q{Anthony Johnson <aj@ohess.org>},
    dist_version_from => 'lib/AnyEvent/Statis.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.010,
        'JSON' => 0,
        'AnyEvent' => 0,
        'AnyEvent::Redis' => 0,
        'List::MoreUtils' => 0,
        'Mouse' => 0,
    },
    add_to_cleanup => [ 'AnyEvent-Statis-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
