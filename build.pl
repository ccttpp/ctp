#!/usr/bin/perl

use strict;
use warnings;

build();

sub build {
    my $outdir = "../criticalthinkers.github.io";
    my $siteurl = "https://criticalthinkers.github.io";
    my %article_index_lists = ();
    my %all_tags = ();
    my %tagcloud_class_lookup;
    my $saw_first_essay_for_index = 0;
    my $continue_processing_index = 1;
    my $main_index_content;
    my $tagcloud = "";
    my $key;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $year += 1900;

    $main_index_content = read_as_string("./template/index", 1);

    `find $outdir/?* -maxdepth 0 -exec rm -rf {} \\;`;

    foreach (split /\n/, `find . -regex "\./[a-z]+/[0-9]+-.*" | sort -nr -t "/" -k3`) {
        my $filepath = $_;
        my ($dot, $sectionname, $articlename) = split /\//, $filepath;
        my %lookup = ();
        my $data;
        my $list;
        my $fill;
        my @parts;

        $data = read_as_string($filepath, 1);

        $lookup{year} = $year;
        $lookup{filepath} = $filepath;
        $lookup{filename} = substr($articlename, length("yyyymmdd-")) . ".html";
        $lookup{section} = $sectionname;
        $lookup{pageurl} = "$siteurl/$sectionname/$lookup{filename}";
        $lookup{$1} = $2 while ($data =~ /<(\w+)>(.+?)<\/\1>/g);

        @parts = split /\//, $lookup{date};
        @parts = map { (length($_) < 2 && ($_ * 1) < 10) ? "0$_" : $_ } @parts;
        $lookup{date} = join("/", @parts);

        if (exists $article_index_lists{$sectionname}) {
            $list = $article_index_lists{$sectionname};
        } else {
            `mkdir $outdir/$sectionname`;
            $list = "";
        }
        $list .= fill($filepath, "./template/" . $sectionname . "_item", \%lookup);
        $article_index_lists{$sectionname} = $list;

        if (exists $lookup{tags}) {
            foreach (split /,/, $lookup{tags}) {
                $_ =~ s/^\s+//;
                $_ =~ s/\s+$//;
                if (exists $all_tags{$_}) {
                    $all_tags{$_} += 1;
                } else {
                    $all_tags{$_} = 1;
                }
            }
        }

        if ($continue_processing_index and $main_index_content =~ /{{$sectionname}}/) {
            if ($sectionname eq "essay") {
                $lookup{first} = $saw_first_essay_for_index ? "" : " first";
                $saw_first_essay_for_index = 1;
            }

            $fill = fill($filepath, "./template/" . $sectionname . "_in_index", \%lookup);
            $main_index_content =~ s/{{$sectionname}}/$fill/;
        } else {
            $continue_processing_index = 0;
        }

        open FILE, ">", "$outdir/$sectionname/$lookup{filename}" or die $!;
        print FILE fill($filepath, "./template/" . $sectionname, \%lookup);
        close FILE
    }

    foreach (keys %article_index_lists) {
        open FILE, ">", "$outdir/$_/index.html" or die $!;
        print FILE fill("\$article_index_lists{$_}", "./template/" . $_ . "_index", {
            year => $year,
            list => $article_index_lists{$_},
            pageurl => "$siteurl/$_"
        });
        close FILE;
    }

    %tagcloud_class_lookup = get_tagcloud_class_lookup(\%all_tags);
    foreach (sort keys %all_tags) {
        $tagcloud .= "<span class=\"hide\">,</span> " if length($tagcloud) > 0;
        $tagcloud .= "<span class=\"" . $tagcloud_class_lookup{$all_tags{$_}} . "\">" . $_ . "</span>";
    }

    $main_index_content =~ s/{{pageurl}}/$siteurl/;
    $main_index_content =~ s/{{tags}}/$tagcloud/;
    $main_index_content =~ s/{{year}}/$year/;
    if ($main_index_content =~ /{{(.+?)}}/) {
        $key = $1;
        die "'$key' value needed by ./template/index not substituted";
    }
    open FILE, ">", "$outdir/index.html" or die $!;
    print FILE $main_index_content;
    close FILE;

    `mkdir $outdir/css`;
    `cp ./css/all.css $outdir/css`;

    `cp ./LICENSE.site $outdir/LICENSE`;
    `cp ./README.site $outdir/README`;
}

sub read_as_string {
    my ($file, $flatten) = @_;
    my $data;
 
    $data = do { local $/ = undef; open my $fh, "<", $file or die $!; <$fh>; };
    $data =~ s/[\n\r]/ /g if $flatten;

    return $data;
}

sub fill {
    my $valuesfile = $_[0];
    my $templatefile = $_[1];
    my %lookup = %{$_[2]};
    my $template;
    my $data;
    my $key;

    $template = read_as_string($templatefile);

    while ($template =~ /{{(.+?)}}/) {
        $key = $1;
        die "'$key' value needed by $templatefile not in $valuesfile" if !exists $lookup{$key};
        $template =~ s/{{$key}}/$lookup{$key}/;
    }

    $template =~ s/([^-])--([^-])/$1&mdash;$2/g;

    return $template;
}

sub get_tagcloud_class_lookup {
    my %tags = %{$_[0]};
    my %lookup = ();
    my $max = 1;
    my $min = 1;
    my @classes = ("max", "big", "above", "normal", "below", "small", "min");

    foreach (keys %tags) {
        $max = $tags{$_} if $tags{$_} > $max;
        $min = $tags{$_} if $tags{$_} < $min;
    }
# TODO: remove: print "max: $max\nmin: $min\n";

    $lookup{1} = "below";
    $lookup{2} = "normal";
    $lookup{4} = "above";

# TODO: how to return a function count -> class?
    return %lookup;
}
