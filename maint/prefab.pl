#!/usr/bin/env perl

use IPC::System::Simple 'system', 'capture';
use File::pushd;
use File::Path 'remove_tree';
use YAML::XS qw(LoadFile DumpFile);
use Pod::Markdown;

if (my $out = capture(qw(git status --porcelain))) {
   die "changes in working directory:\n$out"
}

chomp(my $ref = capture(qw(git rev-parse HEAD)));
CORE::system(qw(git clone gh:frioux/app-adenosine-prefab ../app-adenosine-prefab));

{
   my $dir = pushd('../app-adenosine-prefab');
   CORE::system(qw(git remote add upstream ../app-adenosine));
   system(qw(git fetch upstream));

   system(qw(git checkout master));
   system(qw(git reset --hard), $ref);

   system('dzil listdeps | cpanm --reinstall -l extlib');
   system('cpanm --reinstall -l extlib Term::ANSIColor Time::HiRes');
   remove_tree('extlib/man');
   remove_tree('extlib/bin');
   remove_tree('extlib/lib/perl5/x86_64-linux');
   system(qw(git add -A));
   system(qw(git commit -m), 'build deps');

   my $data = LoadFile('.travis.yml');
   pop @{$data->{install}} for 1..2;
   push @{$data->{install}}, 'cpanm Devel::Cover';
   DumpFile('.travis.yml', $data);
   system(qw(git add .travis.yml));
   system(qw(git commit -m), 'mutate .travis.yml');

   {
      open my $in, '<', 'bin/adenosine';
      open my $out, '>', 'README.md';
      my $parser = Pod::Markdown->new;
      $parser->parse_from_filehandle($in);
      print {$out} $parser->as_markdown;
      system(qw(git add README.md));
      system(qw(git commit -m), 'generate README.md');
   }

   system(qw(git push origin HEAD -fu));
}
