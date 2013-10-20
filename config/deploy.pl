use strict;
use warnings;

# Exports some commands
use Cinnamon::DSL;

my $application = 'cinnamon-deploy-sample';

# It's required if you want to login to remote host
set user     => 'vagrant';

# User defined params to use later
set application => $application;
set repository  => 'git://github.com/shibayu36/cinnamon-deploy-sample.git';

set deploy_to => sub {
    return '/home/vagrant/' . get('application');
};
set daemontools_dir => sub {
    return '/etc/service/' . get('application');
};

set concurrency => {
    update => 2,
};

role production => ['cinnamon-deploy-sample-web1', 'cinnamon-deploy-sample-web2', 'cinnamon-deploy-sample-web3'], {
    deploy_to         => "/home/vagrant/$application",
    branch            => "master",
    daemontools_dir   => "/etc/service/$application",
};

# Tasks
task setup => sub {
    my ($host) = @_;
    call "update", $host;
    call "installdeps", $host;
    call "daemontools:setup", $host;
    call "daemontools:start", $host;
};

task deploy => sub {
    my ($host) = @_;
    call "update", $host;
    call "installdeps", $host;
    call "daemontools:restart", $host;
};

task update => sub {
    my ($host) = @_;

    my $repository = get('repository');
    my $deploy_to = get('deploy_to');
    my $branch = 'master';
    remote {
        run "if [ -d $deploy_to ]; then " .
            "cd $deploy_to && git fetch origin && git checkout -q origin/$branch; " .
            "else git clone -q $repository $deploy_to && cd $deploy_to && git checkout -q origin/$branch; fi";
    } $host;
};

task echo => sub {
    my ($host) = @_;

    run "echo", "1";
    remote {
        run "echo 1";
        run "echo 2";
    } $host;
};

task installdeps => sub {
    my ($host) = @_;
    my $deploy_to  = get('deploy_to');

    remote {
        run "cd $deploy_to && cpanm --quiet -n -L local --mirror '$deploy_to/cpan' --mirror-only --installdeps . < /dev/null; true";
    } $host;
};

task clean => sub {
    my ($host) = @_;
    my $deploy_to   = get('deploy_to');
    my $application = get('application');

    remote {
        run "rm -rf $deploy_to";
        sudo "mv /etc/service/$application /etc/service/.$application";
        sudo "svc -x /etc/service/.$application /etc/service/.$application/log";
        sudo "svc -d /etc/service/.$application /etc/service/.$application/log";
        sudo "rm -rf /etc/service/.$application";
    } $host;
};

task daemontools => {
    setup => sub {
        my ($host) = @_;
        my $daemontools_dir = get('daemontools_dir');
        my $deploy_to       = get('deploy_to');

        remote {
            sudo "mkdir -p $daemontools_dir/log/main";
            sudo "ln -sf $deploy_to/bin/run $daemontools_dir/run";
            sudo "ln -sf $deploy_to/bin/log/run $daemontools_dir/log/run";
            sudo "chown -R vagrant:vagrant $daemontools_dir/log";
        } $host;
    },
    start => sub {
        my ($host) = @_;
        my $daemontools_dir = get('daemontools_dir');

        remote {
            sudo "svc -u $daemontools_dir";
        } $host;
    },
    stop => sub {
        my ($host) = @_;
        my $daemontools_dir = get('daemontools_dir');

        remote {
            sudo "svc -d $daemontools_dir";
        } $host;
    },
    restart => sub {
        my ($host) = @_;
        my $daemontools_dir = get('daemontools_dir');

        remote {
            sudo "svc -t $daemontools_dir";
        } $host;
    },
};
