#!/bin/bash

sudo aptitude update
sudo aptitude install -y build-essential
sudo aptitude install -y curl
sudo aptitude install -y git-core git-doc
sudo aptitude install -y svtools daemontools daemontools-run
sudo /sbin/initctl start svscan
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
cpanm Carton
