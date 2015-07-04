#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
use Image::Magick;
use IO::Handle;

# TODO Find a way to make lighter gifs

our $VERSION = '1.0';
sub HELP_MESSAGE
{
    print "Usage: $0 [OPTION]... INPUT_FILE...\n\n";
    print "  -f         set the animation framerate (in seconds)\n";
    print "  -r         resize to a given size (in px)\n";
    print "  -c         outline color (by color name or hex)\n";
    print "  -i         outline iterations (width)\n";
    print "  --help     display this message and exit\n";
}
sub VERSION_MESSAGE
{
    print "SFWGEC (Skype for Web GIF emotes converter)  ${VERSION}\n";
}

HELP_MESSAGE() if (!@ARGV);
$Getopt::Std::STANDARD_HELP_VERSION = 1;
our ($opt_f, $opt_r, $opt_c, $opt_i);
getopts('f:r:c:i:');

my $fps = $opt_f || 25;
my $outline_color = $opt_c;
my $outline_iterations = $opt_i || 1;

foreach my $ARG (@ARGV)
{
    my $starttime = time();
    print("Processing '$ARG'. ") && STDOUT->flush() if (@ARGV > 1);
    my $im = Image::Magick->new();
    if (!$im->Read($ARG))
    {
    	my ($size, $height) = $im->Get('width', 'height');
	my $oSize = $opt_r || $size;

    	my $max = $height / $size;
    	for (my $frame = 0; $frame < $max; ++$frame)
    	{
    	    push(@$im, $im->[$frame]->Clone()) if (@$im < $max);
    	    $im->[$frame]->Crop(width => $size, height => $size, y => $size * $frame);
	    if ($outline_color)
	    {
    		my $mask = $im->[$frame]->Clone();
		$mask->Morphology(method => 'EdgeOut', kernel => 'Diamond', channel => 'Alpha', iterations => $outline_iterations);
    		$mask->LevelColors('black-point' => $outline_color, 'white-point' => $outline_color, invert => 'True');
		$im->[$frame]->Composite(image => $mask, compose => 'DstOver');
		undef $mask;
	    }
    	}
	$im->Set(
	    page => "${size}x${size}",
	    delay => 100 / $fps
	);
	if ($oSize != $size)
	{
    	    $im->Resize(width => $oSize, height => $oSize);
	    $im->UnsharpMask('1.5x1+0.7+0.02'); # http://www.imagemagick.org/Usage/resize/#resize_unsharp
	}
	$im = $im->Layers(method => 'optimize-plus');
	$im->Layers(method => 'optimize-transparency');

    	$im->Write(
    	    filename => "$ARG.gif",
    	    loop => 0
    	);
	print 'Done! (' . (time() - $starttime) . " sec)\n" if (@ARGV > 1);
    }
    else
    {
	print "Couldn't open/read the file!\n";
    }
    undef $im;
}
