#!/usr/bin/perl -w

# Bronson Brown-deVost, 02.06.2017
# This script is mainly for Göttingen IT use.
# This parses a directory of images files, IAA or PAM, and adds entries
# into the SQE_image table of the SQE database.  In the case of PAM images,
# it also creates an entry in the image_catalog table.
# This script depends on the perl CPAN modules File::Find, DBI, Image::ExifTool,
# Image::Size, and Data::Dumper.  Once compiled, this program may be subject
# to the licenses of those modules.

use strict;
use warnings;
use File::Find;
use DBI;
use DBI qw(:sql_types);
use Image::ExifTool;
use Image::Size;
use lib qw(/home/perl_libs);
use SQE_database;
use Data::Dumper;

my $dbh  = SQE_database::get_dbh;

print 'Starting:'  . "\n";
my @failed_images;
my $image_file_type = "tif"; #Change this to search for other file types, like tiff
my $iiif_url = 0; #id 0 points to "http://134.76.19.179/cgi-bin/iipsrv.fcgi" in the database.

my $dir = $ARGV[0] ? $ARGV[0] : "/var/www/html/iiif-images/";
if (! -e $dir and ! -d $dir) {
    print "\"" . $dir . "\" is not a valid directory!\n";
    print "Please type a valid directory:\n";
    print "perl parse-image-to-SQE-db.pl /Users/user/images\n";
    exit;
}

my $exifTool = new Image::ExifTool;
my @tagList = qw(FileName ExifImageHeight ExifImageWidth XResolution YResolution);
find(\&wanted, $dir);
sub wanted {
  if (!-d $_) {
    #Process IAA images
    if($_ =~ m/^P.*$image_file_type$/) {
      #Image data
      my $info = $exifTool->ImageInfo($File::Find::name, @tagList);
      my $dpi = $$info{XResolution};
      my $name = $$info{FileName};
      my ($width, $height) = imgsize($dir . $name);
      print "Parsing: " . $name . "\n";

      #Data from filename
      my @subStr = split /-/, $_;
      my $plate = $subStr[0];
  		$plate =~ s/^P//g;
      my $fragment = $subStr[1];
  		$fragment =~ s/^Fg//g;
      $fragment =~ s/^0+//;
      my $side = $subStr[2];
      my $date = substr($subStr[5], 1);
      my $time = substr($subStr[6], 1);
      my $type = $subStr[7];
  		$type =~ s/__(.*)$//g;
      my $master = $type =~ /LR445/ && $side =~ /R/ ? 1 : 0;

      #Adjustments to accommodate SQE database structure
      if ($side eq 'R'){ #Side is a boolean 0=Recto, 1=Verso.
        $side = 0;
      } else {
        $side = 1;
      }

      my $wvl_start;
      my $wvl_end;
      if ($type =~ /LR445/) { #We will probably need a legend for types, 0=color, 1=IR, 2 and 3 are raking light.
        $type = 0;
        $wvl_start = 445;
        $wvl_end = 704;
      } elsif ($type =~ /RLIR/) {
        $type = 2;
        $wvl_start = 924;
        $wvl_end = 924;
      } elsif ($type =~ /RRIR/){
        $type = 3;
        $wvl_start = 924;
        $wvl_end = 924;
      } else {
        $type = 1;
        $wvl_start = 924;
        $wvl_end = 924;
      }
      
      #We find the catalog_id and edition_id corresponding to the current plate and fragment.
      my $sth = $dbh->prepare('CALL getCatalogAndEdition(?,?,?);')
          or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth->execute($plate, $fragment, $side);
      my $catalogInfo = $sth->fetchall_arrayref({});
      my $imageCatalogID;
      my $editionCatalogID;
      if (@{$catalogInfo}[0]->{image_catalog_id}){
        $imageCatalogID = @{$catalogInfo}[0]->{image_catalog_id};
      }
      if (@{$catalogInfo}[0]->{edition_catalog_id}){
        $editionCatalogID = @{$catalogInfo}[0]->{edition_catalog_id};
      }

      if ($imageCatalogID) {
        #We insert the record if it doesn't already exist, the URL+filename is unique.
        $sth = $dbh->prepare('INSERT INTO SQE_image (url_code, filename, native_width, native_height, dpi, type, wavelength_start, wavelength_end, is_master, image_catalog_id, edition_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE sqe_image_id=LAST_INSERT_ID(sqe_image_id)')
         or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth->execute($iiif_url, $name, $width, $height, $dpi, $type, $wvl_start, $wvl_end, $master, $imageCatalogID, $editionCatalogID);
        
        my $imageID = $sth->{ mysql_insertid };
        if ($imageID){
          print ("Wrote " . $name . " to database at id:" . $imageID . ".\n");
        } else {
          print ("Failed to write " . $name . " to database.\n");
          push @failed_images, $name;
        }
      } else {
        push @failed_images, $name;
      }
    }
    # Parse PAM image
    if($_ =~ m/^M.*$image_file_type$/) {
      #Image data
      my $info = $exifTool->ImageInfo($File::Find::name, @tagList);
      my $dpi = 0;
      my $name = $$info{FileName};
      print "Parsing: " . $name . "\n";
      my ($width, $height) = imgsize($dir . $name);

      #Data from filename
      my @id_data = split /-/, $_;
      my $series = substr($id_data[0], 1, 2);
      my $number = substr($id_data[0], 3);
      $number =~ s/^0+//;
      my $side = 0; # Always recto, which = 0
      my $type = 1; # Always grayscale, which = 1
      my $wvl_start = 700;
      my $wvl_end = 900;
      my $master = 0; # Never master, so always 0
      my $institution = "PAM";

      # Insert a new record in image_catalog and get the primary key
      my $sth = $dbh->prepare('INSERT INTO image_catalog (institution, catalog_number_1, catalog_number_2, catalog_side) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE image_catalog_id=LAST_INSERT_ID(image_catalog_id)')
         or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth->execute($institution, $series, $number, $side);

      my $imageCatalogID = $sth->{ mysql_insertid };
      print ("Added entry: " . $institution . ", series: " . $series . ", number: " . $number . ", side: " . $side . ", with catalog_id: " . $imageCatalogID . ".\n");

      if ($imageCatalogID) {
        #We insert the record if it doesn't already exist, the URL+filename is unique.
        $sth = $dbh->prepare('INSERT INTO SQE_image (url_code, filename, native_width, native_height, dpi, type, wavelength_start, wavelength_end, is_master, image_catalog_id, edition_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE sqe_image_id=LAST_INSERT_ID(sqe_image_id)')
         or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth->execute($iiif_url, $name, $width, $height, $dpi, $type, $wvl_start, $wvl_end, $master, $imageCatalogID, undef);
        my $imageID = $sth->{ mysql_insertid };
        if ($imageID){
          print ("Wrote " . $name . " to database at id:" . $imageID . ".\n");
        } else {
          print ("Failed to write " . $name . " to database.\n");
          push @failed_images, $name;
        }
      } else {
        push @failed_images, $name;
      }
    }
  }
}

$dbh->disconnect();

# Return a list of failures that must be fixed
if (scalar @failed_images > 0){
  print "Some images were not added to database:\n";
  print Dumper \@failed_images;
}
