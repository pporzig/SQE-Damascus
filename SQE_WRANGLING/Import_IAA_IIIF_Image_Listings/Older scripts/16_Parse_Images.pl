#!/usr/bin/perl

# Bronson Brown-deVost, 02.06.2017 with emendations by James M. Tucker Dec-27-2017 1131
# This script is mainly for Göttingen IT use.
# This parses a directory of images files, IAA or PAM, and formats
# entries into a CSV file.  PAM Images are processed 
# separately in the damascus database because of a different
# database design structure.

## Dependencies on CPAN External Modules
# Image::ExifTool
# Image::Size


use warnings;
use Image::ExifTool;
use Image::Size;
use Data::Dumper;
use utf8; #script is written in utf8 (no BOM)


#second command line argument is Inventory Number (aka Plate Number)
my $inv = @ARGV ? $ARGV[0] : "701";

## 1.0 Get Directory of Images (use conditional for command line if desired)
my $dir	=	@ARGV ? $ARGV[1] : "/Volumes/TuckerJ/IAA-IMAGES/p$inv/";

#second command line argument is a PCRE expression for image type
my $imageType = @ARGV ? $ARGV[2] : qr{jpg|tif};

#open dir to $ARGV[0] (line 14)
opendir(DIR, $dir) or die ("$dir: $!");

#read directory contents
my @images = readdir(DIR);

#quick list for EXIF tags (EXIFTool is rather slow so the more tags here the longer the script will run)
my @tagList = qw( FileName XResolution );

#intiate an $id for cross-referencing
my $idNum = 1;
my $id = 1;

#Create Object Oriented EXIF Tool to parse image data
my $exifTool = new Image::ExifTool;

#declare Array for ouput
my @csvOut;

#default CSV list is as follows
push @csvOut, "id,plate_min_id,plate_num,iaa_file,width,height,dpi,iaa_frg,side,date,time,master,type,wavelength_e,wavelength_s\n\r";

#iterate through directory contents
foreach my $image (@images) {
	#skip the following
	next if $image eq '.';
	next if $image eq '..';
	next if $image eq '.DS_Store';
	
	my $oldImage = $image;
	if ($image =~ m{^P.*$imageType$}){
		my $fileLoc = $dir . $image;

		#call object $exifTool and routine ImageInfo to get Tuples
		my $info = $exifTool->ImageInfo($fileLoc, \@tagList);

		#check EXIF tags to examine info
		# foreach (keys %$info) {
		# 	print "$_ => $$info{$_}\n";
		# }
		
		my $dpi = $$info{XResolution}; #dpi is normally 1215 for images provided by the IAA 
		
		#Get image width and height
		my ($width, $height) = imgsize($fileLoc);

		#format CSV Line with the following variables
		my $csvLine = &formatCSVLine($image, $idNum, $oldImage, $width, $height, $dpi);
		push @csvOut, $csvLine;
	}
	$idNum++;
}
my $csvOut = join("", @csvOut);
my $outFile ="/Users/jamestucker/Desktop/P$inv.csv";

open my $out, ">:encoding(utf8)", "$outFile" or die "Cannot find location: $!";
print $out $csvOut;
close($out);

sub formatCSVLine {
	my $img	=	shift;
	my $id	=	shift;
	my $file	=	shift;
	my $w		=	shift;
	my $h		=	shift;
	my $dpi		=	shift;
	my @csv;
	my $wvl_start;
	my $wv_end;
		
	my $fileType = &getFileType($img);
	
	if ($img =~ m{P\d+_nFrag.*?}){
		next; #skip these
	} else {
		#split on hypen: this creates a problem with 3.0
		my @imgAttr = split (/-/m, $img);
	
		#get plate numeric
		my $plate = $imgAttr[0];
		$plate =~ s{^P}{}; 		#clean superfluous data
		$plate =~ s{_Vrs|_Rec}{}; #truncate superfluous data (note also these images do not have the full EXIF information)
	
		#push to array the following:
		push @csv, "$id,,$plate,$file,$w,$h,$dpi,";	
	
		#get item 1 from array
		my $frag = $imgAttr[1];
		$frag =~ s{^Fg0+}{}; 	#clean superfluous data
		push @csv, "$frag,";
		
		#get item 2 from array
		my $side = $imgAttr[2];
		push @csv, "$side,";
		
		#get substring of item 5
		my $date = substr($imgAttr[5], 1);
		push @csv, "$date,";

		#get substring of item 6		
		my $time = substr($imgAttr[6], 1);
		push @csv, "$time,";
		
		#get item 7 from array
		my $type = $imgAttr[7];
		$type =~ s{ _(.*)$|__(.*)$}{}g;
		
		my $master = $type =~ /LR445|ML445/ && $side =~ /R|M/ ? 1 : 0;
		push @csv, "$master,";
		
		if ($fileType == 0){
			$wvl_start = 445;
			$wvl_end = 704;
		} elsif ($fileType == 2){
	        $wvl_start = 924;
	        $wvl_end = 924;
	  	} elsif ($fileType == 3){
	        $wvl_start = 924;
	        $wvl_end = 924;
	    } else {
	        $wvl_start = 924;
	        $wvl_end = 924;
	    }
		push @csv, "$fileType,$wvl_start,$wvl_end,";
		push @csv, "\n";
	}
	my $csv = join("", @csv);
	return $csv;
}

sub getFileType {
	my $f	=	shift;
	my $type;
	
	my %options = (
		0	=> qr/_Col|_PSC/, 	#colour
		1		=>	qr/_012/,	#multispectral
		2		=>	qr/_026/,	#left raking
		3		=>	qr/_028/	#right raking
	);
	foreach my $kind (keys (%options)){
		while ($f =~ m{ ($options{$kind}) }xmsgi){
			$type = $kind; 
		}
	}
	return $type;
}
