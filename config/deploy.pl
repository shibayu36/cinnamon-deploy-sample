use strict;
use warnings;

# Exports some commands
use Cinnamon::DSL;

my $application = 'cinnamon-deploy-sample';

# It's required if you want to login to remote host
set user     => 'vagrant';
set password => 'vagrant';

# User defined params to use later
set application => $application;
set repository  => 'git://github.com/shibayu36/cinnamon-deploy-sample.git';

set deploy_to => sub {
    return '/home/vagrant/' . get('application');
};
set daemontools_dir => sub {
    return '/etc/service/' . get('application');
};

role production => ['cinnamon-deploy-sample-web1', 'cinnamon-deploy-sample-web2'], {
    deploy_to         => "/home/vagrant/$application",
    branch            => "master",
    daemontools_dir   => "/etc/service/$application",
};

# Tasks
task update => sub {
    my ($host, @args) = @_;

    my $repository = get('repository');
    my $deploy_to = get('deploy_to');
    my $branch = 'master';
    remote {
        run "if [ -d $deploy_to ]; then " .
            "cd $deploy_to && git fetch origin && git checkout -q origin/$branch; " .
            "else git clone -q $repository $deploy_to && cd $deploy_to && git checkout -q origin/$branch; fi";
    } $host;
};

task daemontools => {
    setup => sub {
        my ($host, @args) = @_;
        my $daemontools_dir   = get('daemontools_dir');
        my $current_path      = get('current_dir');

        remote {
            sudo "mkdir -p $daemontools_dir/log/main";
            sudo "ln -sf $current_path/bin/run $daemontools_dir/run";
            sudo "ln -sf $current_path/bin/log/run $daemontools_dir/log/run";
            sudo "chown -R vagrant:vagrant $daemontools_dir/log";
        } $host;
    },
    start => sub {
        my ($host, @args) = @_;
        my $daemontools_dir = get('daemontools_dir');

        remote {
            sudo "svc -u $daemontools_dir";
        } $host;
    },
    stop => sub {
        my ($host, @args) = @_;
        my $daemontools_dir = get('daemontools_dir');

        remote {
            sudo "svc -d $daemontools_dir";
        } $host;
    },
    restart => sub {
        my ($host, @args) = @_;
        my $daemontools_dir = get('daemontools_dir');

        remote {
            sudo "svc -t $daemontools_dir";
        } $host;
    },
};

task installdeps => sub {
    my ($host, @args) = @_;
    my $deploy_to  = get('deploy_to');

    remote {
        run "cd $deploy_to && carton install --deployment";
    } $host;
};

task clean => sub {
    my ($host, @args) = @_;
    my $deploy_to = get('deploy_to');
    my $cpan_lib = get('cpan_lib');

    remote {
        run "rm -rf $deploy_to";
        run "rm -rf $cpan_lib";
    } $host;
};