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

set current_dir => sub {
    return get('deploy_to') . '/current';
};

set releases_dir => sub {
    return get('deploy_to') . '/releases';
};

set cpan_lib => "/home/vagrant/lib/$application";

role production => ['cinnamon-deploy-sample-web1', 'cinnamon-deploy-sample-web2'], {
    deploy_to         => "/home/vagrant/$application",
    branch            => "master",
    daemontools_dir   => "/etc/service/$application",
};

# Tasks
task update => sub {
    my ($host, @args) = @_;
    my $deploy_to    = get('deploy_to');
    my $release_path = get('releases_dir');
    my $current_path = get('current_dir');
    my $current_release = $release_path . "/" . time;

    my $branch       = "origin/" . get('branch');
    my $repository   = get 'repository';

    # Executed on remote host
    remote {
        run "git clone --depth 0 $repository $current_release";
        run "cd $current_release && git fetch origin && git checkout -q $branch && git submodule update --init";
        run "ln -nsf $current_release $current_path";

        # delete old release
        my ($stdout) = run "ls -x $release_path";
        my $releases = [sort {$b <=> $a} split /\s+/, $stdout];
        return if scalar @$releases < 5;

        my @olds = splice @$releases, 5;
        for my $dir (@olds) {
            run "rm -rf $deploy_to/releases/$dir";
        }
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
    my $current  = get('current_dir');
    my $cpan_lib = get('cpan_lib');

    remote {
        run "mkdir -p $cpan_lib";
        run "cd $current && cpanm --notest --verbose -L $cpan_lib --installdeps . < /dev/null; true";
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
