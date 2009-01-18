use strict;
use warnings;

use Module::Build;

use List::MoreUtils qw/ apply uniq /;

my $builder = Module::Build->new(
    module_name  => 'Git::CPAN::Patch',
    license      => 'perl',
    dist_author  => 'Yanick Champoux <yanick@cpan.org>',
    requires     => {
        perl                       => '5.10.0',
        'autodie'                  => 0,
        'Parse::BACKPAN::Packages' => 0,
        'Pod::Usage'               => 0,
    },
    script_files => [
        'git-backpan-init',
        map "git-cpan-$_" => qw/
          format-patch  init          send-email
          squash        which         sendpatch
          import        last-version  update
          /
    ],

    meta_merge => {
        resources => {
            repository => 'git://github.com/yanick/git-cpan-patch.git',
            bugtracker =>
              'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Git-CPAN-Patch',
        },
    },
);

locate_git( $builder );

$builder->create_build_script();


sub locate_git {

    my $builder = shift;

    print <<'END_MESSAGE';

When programs named 'git-<something>' are put in the 
same directory than git's own commands, they are  
considered as part of the family. Which means that 
you can type

    $ git something

and Git will do the right thing.  Bash expansion, 
if you have it configured, will work on the new commands
as well.

END_MESSAGE

    $builder->prompt( 
        q{install Git::CPAN::Patch's scripts in Git's commands directory?},
        'n' 
    ) =~ /^y/i or return;

    print "\nokay, let's see where that directory could be...\n";

    # let's find where the git-* commands are
    my @dirs =  uniq
                grep { -f "$_/git-init" }
                map { 
                        my $original = $_;
                        s#/bin/?$##; 
                        $_ .= "/libexec/git-core";
                        $_ => $original;
            } 
            apply { y#/#/#s } 
                    split( ':' => $ENV{PATH} ), qw( /usr /usr/local );

    if ( @dirs ) {
        print "git commands detected in the following directories:\n";
        print "\t$_\n" for @dirs;
    }

    my $path = $builder->prompt(
        'git commands directory', $dirs[0] 
    );

    $builder->install_path( script => $path );

}