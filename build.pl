#!/usr/bin/perl

use strict;
use warnings;

build();

sub build {
    my $outdir = "./site";
    my %article_index_lists = ();
    my $continue_processing_index = 1;
    my $main_index_content;

    $main_index_content = read_as_string("./template/index", 1);

    `rm -rf $outdir`;
    `mkdir $outdir`;

    foreach (split /\n/, `find . -regex "\./[a-z]+/[0-9]+-.*" | sort -nr -t "/" -k3`) {
        my $filepath = $_;
        my ($dot, $sectionname, $articlename) = split /\//, $filepath;
        my %lookup = ();
        my $data;
        my $list;
        my $fill;

        $data = read_as_string($filepath, 1);

        $lookup{filepath} = $filepath;
        $lookup{filename} = substr($articlename, length("yyyymmdd-")) . ".html";
        $lookup{section} = $sectionname;
        $lookup{pageurl} = "https://ctp.herokuapp.com/$sectionname/$lookup{filename}";
        $lookup{$1} = $2 while ($data =~ /<(\w+)>(.+?)<\/\1>/g);

        if (exists $article_index_lists{$sectionname}) {
            $list = $article_index_lists{$sectionname};
        } else {
            `mkdir $outdir/$sectionname`;
            $list = "";
        }
        $list .= fill("./template/" . $sectionname . "_item", \%lookup);
        $article_index_lists{$sectionname} = $list;

        if ($continue_processing_index and $main_index_content =~ /{{$sectionname}}/) {
            $fill = fill("./template/" . $sectionname . "_in_index", \%lookup);
            $main_index_content =~ s/{{$sectionname}}/$fill/;
        } else {
            $continue_processing_index = 0;
        }

        open FILE, ">", "$outdir/$sectionname/$lookup{filename}" or die $!;
        print FILE fill("./template/" . $sectionname, \%lookup);
        close FILE
    }

    foreach (keys %article_index_lists) {
        open FILE, ">", "$outdir/$_/index.html" or die $!;
        print FILE fill("./template/" . $_ . "_index", {
            list => $article_index_lists{$_}
        });
        close FILE;
    }

    open FILE, ">", "$outdir/index.html" or die $!;
    print FILE $main_index_content;
    close FILE;

    `cp ./misc/robots.txt $outdir`;

    `mkdir $outdir/misc`;
    `cp ./misc/setup.html $outdir/misc`;
    `cp ./misc/todo.html $outdir/misc`;
}

sub read_as_string {
    my ($file, $flatten) = @_;
    my $data;
 
    $data = do { local $/ = undef; open my $fh, "<", $file or die $!; <$fh>; };
    $data =~ s/[\n\r]/ /g if $flatten;

    return $data;
}

sub fill {
    my $templatefile = $_[0];
    my %lookup = %{$_[1]};
    my $template;
    my $data;
    my $key;

    $template = read_as_string($templatefile);

    while ($template =~ /{{(.+?)}}/) {
        $key = $1;
        die "'$key' value needed by $templatefile not in lookup" if !$lookup{$key};
        $template =~ s/{{$key}}/$lookup{$key}/;
    }

    return $template;
}
