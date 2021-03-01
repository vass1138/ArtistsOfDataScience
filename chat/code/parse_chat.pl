#!/usr/bin/perl

# Created 2021.02.25
# Parse Artist of Data Science chat files to extract hyperlink resources.
# Output text and html versions.

use strict;

use Getopt::Long;
use Time::Piece;
use File::Basename;
use Cwd;

my ($THIS_DIR) = getcwd;

sub usage {
    print("Usage: $0 --file=chat-file --start=start-time --link=video-link \n");
    print("  file : timestamped chat file\n");
    print("  start: start time 24-hr format hh:mm:ss\n");
    print("  link : YouTube video link WITHOUT time cursor\n\n");
    exit();
}

my ($input_file, $start_time, $video_link);

# command line options
GetOptions ("file=s" => \$input_file, 
            "start=s" => \$start_time,      # string
            "link=s"   => \$video_link)      # string
or usage();

# command line parameter formatting
if (not -e $input_file) {
    print("ERROR: File not found \n\n");
    usage();
}

if ($start_time !~ m/\d{2}:\d{2}:\d{2}/) {
    print("ERROR: Invalid time format\n\n");
    usage();
}

if ($video_link !~ m/^https:\/\//) {
    print("ERROR: Invalid link format\n\n");
    usage();
}

# remove trailing time cursor from link
$video_link =~ s/&t=\d+s//;

# Parameters

# Start time
my ($t0) = Time::Piece->strptime($start_time,"%T");

# Update for each file!!!!!
# my ($url_template) = "https://www.youtube.com/watch?v=mKWtJb_mxJQ&t={SECONDS}s";

#
# Subroutines
#

# https://stackoverflow.com/questions/5167602/in-perl-what-is-the-easiest-way-to-turn-x-seconds-into-format-hhmmss
sub format_seconds {

    # Format seconds as hh:mm:ss

    my ($args) = @_;

    my $seconds = $args->{seconds};

    my ($hours, $hourremainder) = (($seconds/(60*60)), $seconds % (60*60));
    my ($minutes, $seconds) = (int $hourremainder / 60, $hourremainder % 60);

    ($hours, $minutes, $seconds) = (sprintf("%02d", $hours), sprintf("%02d", $minutes), sprintf("%02d", $seconds));

    return $hours . ':' . $minutes . ':' . $seconds;
}

sub write_files {

    # dump array content to output files

    my (@data) = @_;
    my ($current_file) = shift(@data);
    my ($newext) = shift(@data);

    my ($name,$dir,$ext) = fileparse($current_file,'\..*');

    my ($newname) = "../output/" . $name . $newext;
    my ($output) = $THIS_DIR . "/" . $newname;

    open(my $fh,'>',$output);
    print $fh @data;
    close($fh);

    
    print("$current_file $newname\n");
}

#
# MAIN
#

my(@text, @html);

open(FILE, $input_file) or die "Couldn't open $input_file: $!\n";

while (<FILE>) {

    # process lines that contain http only

    if ($_ =~ /http/) {

        # process lines with links

        # split times and name from comment
        my ($myheader, $mystring) = split(/ : /);

        my ($mytimestamp) = substr($myheader,0,8);
        my ($myname) = substr($myheader,14);

        # adjust 24-hour clock to elapsed time
        my ($t) = Time::Piece->strptime($mytimestamp,"%T");
        my ($tdelta) = $t - $t0;
        my ($tformatted) = format_seconds({seconds=>$tdelta});

        # append time cursor to YouTube url
        my ($url) = $video_link . "&t=" . $tdelta . "s";

        # extract one or more links from comment
        my (@links) = $mystring =~ m{(https:\/\/.*)\s?}g;
        
        # save html and text content
        
        push(@html,sprintf ("[<a href=\"%s\">%s</a>] %s\n",$url,$tformatted,$myname));

        for my $link (@links) {
            push(@html,sprintf ("<a href=\"%s\">%s</a>\n",$link,$link)); 
        }

        push(@html,"<BR/>\n");

        push(@text,sprintf ("%s %s\n",$tformatted,$myname));

        for my $link (@links) {
            push(@text,sprintf ("%s\n",$link)); 
        }       

        push(@text,"\n");

    }
}

close(FILE);

# one final commit after loop ends
write_files($input_file,".html",@html);
write_files($input_file,".txt",@text);