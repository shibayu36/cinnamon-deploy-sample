#!/bin/bash

sudo aptitude update
sudo aptitude install -y build-essential
sudo aptitude install -y curl
sudo aptitude install -y git-core git-doc
sudo aptitude install -y daemontools daemontools-run
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
cpanm Carton
