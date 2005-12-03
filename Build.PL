use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'passthrough',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Authentication::Store::DBIC',
    requires           => {
        'Catalyst'                         => '5.49',
        'Catalyst::Plugin::Authentication' => '0.02',
    },
    recommends         => {
        'Catalyst::Plugin::Authorization::Roles'  => 0,
        'Catalyst::Plugin::Session'               => '0.02',
    },
    create_readme => 1,
);
$build->create_build_script;
 
