# What's this

This is a deploy sample using Cinnamon, and also used for testing Cinnamon.

# Setup

It's very easy to setup local server to deploy.

```
$ vagrant up
```

This command launch 3 local servers using vagrant.

After launching servers, you must configure your SSH settings to deploy code to local server.  Execute following command.

```
$ perl script/setup-ssh-config.pl
```

# Deploy Application

You can deploy application by following commands.

First time,

```
$ cinnamon production setup
```

From the 2nd time,

```
$ cinnamon production deploy
```

After deploying, you can access
- localhost:8001
- localhost:8002
- localhost:8003