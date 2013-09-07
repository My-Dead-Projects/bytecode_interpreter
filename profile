export PATH=$PATH:/var/lib/stickshift/522644dbe0b8cd4b81000054/app-root/data/602538

git config --global alias.s "status -s"
git config --global alias.l "log --oneline --graph"
git config --global alias.c "commit -m"
git config --global push.default simple

alias run="ruby bct.rb < prog.bc"
