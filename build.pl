#!/usr/bin/perl

use strict;
use warnings;

&build;

sub build {
    my $outdir = "./build";

    `rm -rf $outdir`;
    `mkdir $outdir`;

    &index($outdir, &sections($outdir));
    &misc($outdir);
}

sub misc {
    my ($outdir) = @_;

    `mkdir $outdir/misc`;
    `cp ./misc/* $outdir/misc`;
}

sub index {
    my ($outdir, $articles) = @_;
    my @articles = @{$articles};
    my $i = 0;
    my $found;
    my %seen = ();
    my $template;
    my $data;
    my %lookup = ();
    my $key;

    open IN, "<", "./template/index.template" or die $!;
    open OUT, ">", "$outdir/index.html" or die $!;
    while (<IN>) {
        if ($_ =~ /{(.+)}/) {
            $found = 0;
            for ($i = 0; !$found and $i <= $#articles; $i++) {
                my @arr = @{${\@{$articles}}[$i]};

                next if $seen{$arr[2]};

                if ($arr[1] eq $1) {
                    $found = 1;
                    $seen{$arr[2]} = 1;

                    $template = &read("./template/$arr[1]_in_index.template");
                    $data = &read($arr[2]);
                    $data =~ s/[\n\r]/ /g;

                    while ($data =~ /<(\w+)>(.+?)<\/\1>/g) {
                        $lookup{$1} = $2;
                    }

                    while ($template =~ /{(.+)}/) {
                        $key = $1;
                        die "$arr[2] does not contain value for '$key'" if !$lookup{$key};
                        $template =~ s/{$key}/$lookup{$key}/;
                    }

                    print OUT $template;
                }
            }
            die "$1 not found" if !$found;
        } else {
            print OUT $_;
        }
    }
    close IN;
    close OUT;
}

sub read {
    my ($file) = @_;

    return do { local $/ = undef; open my $fh, "<", $file or die $!; <$fh>; };
}

sub sections {
    my ($outdir) = @_;
    my @sections = split /\n/, `find . -type d | grep -v build | grep -v template | grep -v misc`;
    my @articles = ();

    foreach (@sections) {
        if ($_ =~ /^\.\/(.+)$/) { # "./sectionname"
            foreach(@{&section($outdir, $1)}) {
                push @articles, \@{$_};
            }
        }
    }

    my @sorted = reverse sort { @{$a}[0] cmp @{$b}[0] } @articles;
    return \@sorted;
}

sub section {
    my ($outdir, $sectionname) = @_;
    my @articles = split /\n/, `find ./$sectionname -type f`;
    my @articleinfos = ();

    `mkdir $outdir/$sectionname`;

    foreach (@articles) {
        push @articleinfos, \@{&article($outdir, $_)};
    }

    open FILE, ">", "$outdir/$sectionname/index.html" or die $!;
    foreach (reverse sort { @{$a}[0] cmp @{$b}[0] } @articleinfos) {
        print FILE "- " . @{$_}[2] . "\n";
    }
    close FILE;

    return \@articleinfos;
}

sub article {
    my ($outdir, $articlepath) = @_;
    my ($ignore, $sectionname, $articlename) = split /\//, $articlepath; # (".", "$sectionname", "articlename")
    my $date = "2013/";
    my $rnd = 1 + int(12*rand());

    $date .= "0" if $rnd < 10;
    $date .= $rnd . "/";
    $rnd = 1 + int(28*rand());
    $date .= "0" if $rnd < 10;
    $date .= $rnd;

    `touch $outdir/$sectionname/$articlename.html`;

    return [$date, $sectionname, $articlepath];
}
