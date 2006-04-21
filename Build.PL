use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Authentication::Store::DBIC',
    requires           => {
        'Catalyst'                         => '5.49',
        'Catalyst::Plugin::Authentication' => '0.06',
        'Set::Object'                      => '1.14',
    },
    recommends         => {
        'Catalyst::Plugin::Authorization::Roles'  => '0.03',
        'Catalyst::Plugin::Session'               => '0.02',
        'DBIx::Class'                             => 0,
        'Class::DBI'                              => 0,
    },
    create_readme => 1,
);
$build->create_build_script;

