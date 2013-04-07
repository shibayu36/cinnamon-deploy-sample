#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Path::Class;
use IO::Prompt::Simple;

my $ssh_config_file = file("$ENV{HOME}/.ssh/config");
my $ssh_config = $ssh_config_file->slurp;

$ssh_config =~ s{### cinnamon-deploy-sample config begin ###.*### cinnamon-deploy-sample config end ###\n}{
    my $config = `./script/print-ssh-config.sh`;
}mse;

print $ssh_config;

my $confirm = prompt("overwrite ssh config?", { anyone => [qw/y n/]});
exit if $confirm ne 'y';

my $fh = $ssh_config_file->openw;
print $fh $ssh_config;
