my $version = "finishOp.pl ver 2011.06.01";
my $opbase = 'D:/';
my $oplogs = "Logs/";

# Updated 12/09/2010
# 
# 3/3/09 -- Stores data in to_pp instead of thumbdrive
# 3/4/09 -- Grabs BZ2 from smb share.
# 3/16/09 -- fixed prompt related to bz2 tarballs
# 3/20/09 -- Clarified the share mounting prompts
# 3/24/09 -- copy op.done.by* from share also
# 12/09/10 -- DSZ 1.1 support.
# 01/10/11 -- bugfixes, tweaked zipping for DSZ 1.1 folders to save base folder name in zip dir structure
#             detect DSZ 1.1 connection conflicts
# 01/21/11 -- bug fix for systype (search SYSTYPEBUGFIX)
#

# find all IP directories
use FindBin;			
#use lib "$FindBin::Bin/../tools/library';
use File::Copy;
use File::Path;
use File::Compare;
use Cwd;

use strict;

system ("title=$version");
print "\n$version\n\n";

my $mainpath=cwd();

my (@dirs, $answer, %TargetInOpnotes, @TargetInfo, $line);
my $OpStatus = 'successful';

if (not(-d "y:/")) {
	print "\n\n** UNABLE TO DETECT LINUX SHARE **\n\n";
	print "** Mount it now to copy PITCH data.\n\n";
	print "Hit ENTER when ready or to continue with none.\n\n";
	<STDIN>;
}

my $zipdisk='d:\\to_pp';
print "Please enter final output directory [$zipdisk]:  ";
$answer = <STDIN>;
chomp($answer);
$zipdisk = $answer if $answer;
$zipdisk =~ s/([^\/\\])$/$1\//;

if (not(-e $zipdisk)) {
	mkpath($zipdisk);
}

#while (! -e $zipdisk) {
#	print "Can't find media in $zipdisk\nPlease enter drive of removable media:  ";
#	$zipdisk = <STDIN>;
#	chomp($zipdisk);
#	$zipdisk =~ s/[^\/\\]$/$1\//;
#}

# print "Note: Please place *nix bz2 file in \"$zipdisk\" if applicable.\n\n";

my $phoneLog="$zipdisk/phonelog.txt";
my $deleteMe="$zipdisk/deleteme.txt";


#this script is in the Tools dir, so go up one directory to get the opdisk root dir
#(my $opsdisk = $mainpath) =~ s/[\/\\]+[^\/\\]+$//;
my $opsdisk = "D:\\DSZOPSDisk";

print "Please Enter Root Directory of the DSZOPSDisk [$opsdisk]:  ";
$answer = <STDIN>;
chomp($answer);
$opsdisk = $answer if $answer;
while (!( -e $opsdisk)){
	print "Can't find DSZOPSDisk in $opsdisk\nPlease Enter Root Directory of the OPSDisk:  ";
	$opsdisk = <STDIN>;
	chomp($opsdisk);
}

#<DSZ1.1>
opendir OPS, $opbase;
my @files = grep { s/^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/$opbase$1/ } readdir OPS;
closedir OPS;
opendir OPS, "$opbase$oplogs";
foreach my $file (readdir OPS) {
	if ($file eq '..' or $file eq '.') {
		next;
	}
	push @files, "$opbase$oplogs$file";
}
closedir OPS;
my @dirs;
while (my $dir = shift(@files)) {
	if (-d $dir) {
		push @dirs, $dir;
	}
}
#</DSZ1.1>

foreach my $dir (@dirs) {
	print "Found $dir\n";
}

# Note project of targets
my %project=();
# Note system type of targets
my %systype=();

######find opnotes and copy into all directories

print "Finding opnotes.\n";
my @opnotes=();
foreach my $dir (@dirs) {
	if (-e "$dir/opnotes.txt") {
		push @opnotes, "$dir/opnotes.txt";
	}
	if (-e "$dir/router.log") {
		$systype{$dir}="r";
	}
	if (-e "$dir/pbx.log") {
		$systype{$dir}="p";
	}
	if (-e "$dir/FTP_ScreenDump") {
		$systype{$dir}="p";
	}
}
my $opnotes=$opnotes[0];
if (scalar(@opnotes) > 1) {
	# TODO: decide on an opnotes to use; maybe most recently changed or largest
}

if (not(-e $opnotes)) {
	$opnotes="$mainpath/opnotes.txt";
	print "Couldn't find opnotes; trying opnotes in disk, $opnotes\n";
}

if (not(-e $opnotes)) {
	print STDERR "Couldn't find any opnotes!!!!\n";
	print STDERR "Hit return to continue, or ^C and go put your opnotes where I can find them (named opnotes.txt, in\n";
	print STDERR "  $zipdisk or the top-level of one of the ops directories.\n";
	<STDIN>;
}

########## get project name 
# TODO: write this into top of opnotes.txt if it's not already there
#any IPs with nonstandard projects should ask for later
my $defaultProject="";

open OPNOTES, $opnotes;
while ($line=<OPNOTES>) {
	chomp($line);
	if ($line =~ /^project:\s*(\S+?)\s*$/i) {
		$defaultProject=$1;
		last;
	}
}
close OPNOTES;

while ($defaultProject eq "") {
	print "!!!! Whoa!  Couldn't find default project name!  You may want to check $opnotes and cancel out here!\n";
	print "Please enter the project name for this op: ";
	$defaultProject=<STDIN>;
	chomp($defaultProject);
	$defaultProject =~ s/\s*$//;
	$defaultProject =~ s/^\s*//;
}

$defaultProject=lc($defaultProject);




#### get true project names
foreach my $dir (@dirs) {
	#<DSZ1.1>
	if ($dir !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
		# project folders are easy
		$dir =~ /.+[\/\\]([^\/\\]+)$/;
		$project{$dir} = $1;
		next;
	}
	#</DSZ1.1>
	print "Enter project for $dir [$defaultProject]: ";
	my $project=<STDIN>;
	chomp($project);
	if ($project eq "") {
		$project=$defaultProject;
	}
	$project{$dir}=$project;
	
	# Also get system type
	unless ($systype{$dir}) {
		$systype{$dir}="w";
	}
	# Override system type with directory name if it's named appropriately
	if ($dir =~ /\b[\d._]+([a-zA-Z])$/) {
		$systype{$dir}=$1;
	}
}




#print "Adding in local information.\n";
my $phoneWaiting=0;
#if (!(-e $phoneLog)) {
#	my $tempp;
#	print "$phoneLog Not Found!\r\n Is there a phonelog for finishOP to insert into the OP notes?[y/n]: ";
#	$tempp = <STDIN>;
#	$tempp =~ s/\n//g;
#	if($tempp =~ /y/i){
#		print "Please enter in the full path to phonelog.txt: ";
#		$tempp = <STDIN>;
#		$tempp =~ s/\n//g;
#		$phoneLog = $tempp;
#		$phoneWaiting=1;
#	}
#}
#else{
#	$phoneWaiting=1;
#}
my $hostWaiting=1;
my $hostname=`hostname`;
chomp($hostname);
$hostname=uc($hostname);
my $hostline="Ops Machine: $hostname";
open OPOLD, "$opnotes";
my @oldopnotes=<OPOLD>;
close OPOLD;
if (grep /^$hostline$/, @oldopnotes) {
	$hostWaiting=0;
} else {
	$hostWaiting=1;
}

my $newopnotes="$opnotes.new";
open OPNEW, ">$opnotes.new";
open OPOLD, "$opnotes";
while ($line=<OPOLD>) {
	# capture target notes
	if ($line =~ /^(NOTE|DONOTRUN|ERROR|IGNORE)\s*\(([^\(\)]*?)\)\s*:?\s*(\S.*)$/) {
		my ($type, $target, $comment) = ($1,$2,$3);
		if (-d "$opbase/$target") {
			open TARGETNOTES, ">>$opbase/$target/targetnotes.txt";
			print TARGETNOTES "$type: $comment\n";
			close TARGETNOTES;
		} else {
			print STDERR "Error!  Couldn't find directory $opbase/$target to put target comment in:\n";
			print STDERR "  $line";
		}
	}
	if ($line =~ /Results/) {
		if ($phoneWaiting) {
			open PHONE, $phoneLog;
			print OPNEW "## From $phoneLog\n";
			while (my $line=<PHONE>) {
				print OPNEW $line;
			}
			print OPNEW "\n";
			close PHONE;
			$phoneWaiting=0;
		}
		if ($hostWaiting) {
			print OPNEW "$hostline\n";
			$hostWaiting=0;
		}
	}
	
	if ($line =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
		$TargetInOpnotes{$1}++ while ($line =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/g);
		push(@TargetInfo, $line) if ($line =~ /\>.+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/);
	}

	if ($line =~ /^\s*Op Status\:/) {
		$OpStatus = 'unsuccessful';
	}

	print OPNEW $line;
}
# Try printing out at the end, in case you didn't find a "Results" line in the opnotes
if ($phoneWaiting) {
	open PHONE, $phoneLog;
	print OPNEW "## From $phoneLog\n";
	while ($line=<PHONE>) {
		print OPNEW $line;
	}
	print OPNEW "\n";
	close PHONE;
	$phoneWaiting=0;
}
if ($hostWaiting) {
	print OPNEW "$hostline\n";
	$hostWaiting=0;
}

close OPOLD;
close OPNEW;
unlink($opnotes);
rename("$opnotes.new",$opnotes);
if (($phoneWaiting==0) and (-e $phoneLog)) {
	unlink($phoneLog);
}

print "\n\nOverall ops status is \"$OpStatus\" - is this correct? [Y/n]: ";
$answer = <STDIN>;
print "You can correct the status by answering \"y\" to edit the opnotes below.\n\n" if ($answer =~ /n/i);

my $opnotes_problem = 0;
#<DSZ1.1>
my @targets;
foreach my $dir (@dirs) {
	if ($dir !~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
		opendir OPS, $dir;
		# omit all IPs with a 0 at the start and trim the z
		my @iplist = grep { s/^z([1-9]\d{0,2}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/$1/ } readdir OPS;
		closedir OPS;
		push @targets, @iplist;
	} else {
		# old IP dir, add it to the list
		push @targets, $1;
	}
}
foreach my $targetip (@targets) {
	unless (exists($TargetInOpnotes{$targetip})) {
		print "\n$targetip wasn't found in the opnotes, though it has a data directory.\n";
		print "If this IP address was accessed (or even just attempted) during the op,\n";
		print "please add it and the full domain to the opnotes\n\n";
		$opnotes_problem = 1;
	}
}
#</DSZ1.1>

&EditOpNotes($opnotes) if ($opnotes_problem);


print "\n\n******************** target info from opnotes ********************\n";
print "Each target should have IP(s), full domain name, and appropriate labels:\n";
print "- project (if different than main project)\n";
print "- *nix/firewall/router (for non-Windows targets)\n";
print "- unsuccessful (if not reached)\n\n";
foreach $line (@TargetInfo) {
	print $line;

	print "^^^^^^ Incomplete or missing domain name? Please list if known. ^^^^^^\n" 
		unless $line =~ /\d*[a-zA-Z]+\d*\.\d*[a-zA-Z]+\d*/;
}
print "\n******************************************************************\n\n";
&EditOpNotes($opnotes);


# copy opnotes and writing project name into all directories
print "Copying opnotes and writing project name to all directories\n";
foreach my $dir (@dirs) {
	open PROJECT, ">$dir/project.txt";
	print PROJECT $project{$dir};
	print PROJECT "\n";
	close PROJECT;

	open PROJECT, ">$dir/systype.txt";
	# SYSTYPEBUGFIX
	if ($systype{$dir}) {
		print PROJECT $systype{$dir};
	} else {
		print PROJECT 'w';
	}
	print PROJECT "\n";
	close PROJECT;

	if ("$dir/opnotes.txt" eq $opnotes) {
		next;
	}
	if (-e "$dir/opnotes.txt") {
		rename("$dir/opnotes.txt","$dir/opnotes.orig.txt");
	}
	copy($opnotes,"$dir/opnotes.txt");
}



############ run renamer
print "Running renamer.exe and dotrenamer\n";
foreach my $dir (@dirs) {
	# check for any darkskyline logs
	# &doDSParser($dir);
	# check for any IDS systems on machine
	# should already be done in idslogger.eps
#	&doBootdepth($dir);
	# run renamer.exe in all directories
	&dorenamer($dir);
	# This also takes care of renaming copyget
	&dodotrenamer($dir);
}
chdir($mainpath);

########### detect DSZ 1.1 connection conflicts

print "Checking DSZ 1.1 data for connection conflicts... (no output is a good thing)\n";
while (1) {
	my $conflict = 0;
	foreach my $dir (@dirs) {
		next unless ($dir !~ /\d+\.\d+\.\d+\.\d+/);
		opendir OPS, "$dir";
		my @zdirs = grep { /^z/ } readdir OPS;
		closedir OPS;
		foreach my $z (@zdirs) {
			opendir OPS, "$dir/$z";
			my @hostinfos = grep { /^hostinfo.*\.txt$/ } readdir OPS;
			closedir OPS;
			my $master = shift @hostinfos;
			foreach my $hostinfo (@hostinfos) {
				if (compare_macs("$dir/$z/$master", "$dir/$z/$hostinfo") != 0) {
					print "Conflict detected! $dir/$z/$hostinfo differs from others.\n";
					$conflict = 1;
				}
			}
		}
	}
	if ($conflict) {
		system('color c');
		print "
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! CONNECTION CONFLICTS MUST BE RESOLVED. CANNOT CONTINUE. GET HELP! !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Here is a command shell. Exiting this shell will return to this script,
which will then recheck for conflicts.

Good luck.

";
		system('cmd');
	} else {
		last;
	}
}
system('color');

########### zip up directories

print "Remember to save the netmon capture.\n";
my $winzip="C:/Program Files/WinZip/WZZIP.EXE";
if (-e $winzip) {
	print "Remember to finish any op notes and save the capture file.\n";
	print "About to zip up directories.  (Hit enter to continue.)\n";
	<STDIN>;
	foreach my $dir (@dirs) {
		retryUntilOkay(\&zipDir,$dir);
	}
} else {
	print "Couldn't find $winzip; please install command-line winzip here.\n";
	print "Can't yet command-line zip up directories.  Do it yourself, please.  Hit return when done.\n";
	print "Remember to finish any op notes and save the capture file.\n";
	<STDIN>;
}

############### move directories

my $date=`date /t`;
if ($date =~ /(\d+)\/(\d+)\/(\d+)/) {
	$date="$3$1$2";
} else {
	$date="UNKNOWN";
}
my $tempNum=0;

my $opdir="${zipdisk}/${date}_$defaultProject";
while (-e $opdir) {
	print "$opdir exists; renaming\n";
	$opdir="${zipdisk}/$date$tempNum\_$defaultProject";
	$tempNum++;
}
if (not(-e $opdir)) {
	mkpath($opdir);
}

my $backpath="${opbase}/Old_ops";
#if (not(-d $backpath)) {
#	print STDERR "No backup directory $backpath!  Will backup to Zip drive.\n";
#	$backpath="${zipdisk}/Old_ops";
#}

my $backupdir="$backpath/$date/${date}_$defaultProject";
$tempNum=0;
while (-e $backupdir) {
	print "$backupdir exists; renaming\n";
	$backupdir = "$backpath/$date/${date}_$defaultProject$tempNum";
	$tempNum++;
}
if (not(-e $backupdir)) {
	mkpath($backupdir);
}

print "Backup dir is $backupdir\n";
print "Op dir is $opdir\n";

foreach my $dir (@dirs) {
	# copy zip
	retryUntilOkay(\&copyZip,$dir);
}

foreach my $dir (@dirs) {
	# move dir
	retryUntilOkay(\&moveFiles,$dir);
}

##### copy any UNIX .tar.bz2 files


if (-d "y:/")
{
	my $source = "y:/";
	opendir ZIP, "$source/";
	my @files=readdir ZIP;
	closedir ZIP;
	@files = grep /(^op.done.by|\d{8}-\d{4}\.tar\.bz2$)/, @files;
	foreach my $file (@files) {
		my $response = "";
		while ($response !~ /^[yn]$/i) {
			print "Move $file into $opdir? [y]/n: ";
			$response=<STDIN>;
			chomp($response);
			if ($response eq "") {
				$response = "y";
			}
		}
		if ($response =~ /y/i) {
			# copy $file into backup directory as well
			copy("$source/$file","$backupdir/$file");
			copy("$source/$file","$opdir/$file");
			#rename("$zipdisk/$file","$opdir/$file");
		}
	}

	unless (grep /bz2$/, @files) {
		print "\n\n**********************************************************************\n";
		print "\n\nNOTE: no Unix bz2 files found in $zipdisk.  If you have any Unix data,\n";
		print "including pitchimpair(s), you must move this manually to your media!!\n";
		print "**********************************************************************\n\n";
	}
}

my $remove="$mainpath/removeOldOps.pl";
unless (-e $remove) {
	$remove="${zipdisk}/working/removeOldOps.pl";
	unless (-e $remove) {
		$remove="C:/removeOldOps.pl";
		unless (-e $remove) {
			$remove="removeOldOps.pl";
		}
	}
}
if (-e $remove) {
	print "Removing old op files.\n";
	system("$remove > $deleteMe");
}

if (-e $deleteMe) {
	unlink($deleteMe);
}

#Make sure all files were copied to the zip - alert user if any are missing

opendir(DIR, $backupdir) or warn "Can't list $backupdir: $!\n";
while(defined($_ = readdir(DIR))) {
	next unless (/\.zip$/ || /\.bz2$/);
	if (! -e "$opdir\\$_") {
		warn "\n\n!!! $_ wasn't copied to your removable media !!!\n Make sure there is enough space, then copy this manually.\n\n";
	}
}
closedir DIR;

print "\n\n*Files moved. Run the copy script now.*\n\n";

print "All done.  Thank you, please come again.  (Hit return to exit)\n";
<STDIN>;
exit(0);

######################################################################################
######################################################################################
######################################################################################
######################################################################################
######################################################################################

sub zipDir {
	my $dir=shift();
	my $zipname="$dir.zip";
	if (-e $zipname) {
		print STDERR "Hey!  $zipname Already exists!  Remove it, then hit return to continue.\n";
		print STDERR "(Or enter 'skip' to skip this)\n";
		my $response=<STDIN>;
		chomp($response);
		if ($response eq 'skip') {
			return 1;
		} else {
			return 0;
		}
	} else {
		if ($dir =~ /(\d+\.){3}\d+/) {
			# if IP folder do it the old way
			if (system("\"$winzip\" -rp $zipname $dir/* > $deleteMe")!=0) {
				print STDERR "Error zipping!\n";
			}
		} else {
			# else DSZ 1.1 way (save base folder name)
			$dir =~ /[\/\\]([^\/\\]+)$/;
			my $projdir = $1;
			chdir "D:\\Logs";
			if (system("\"$winzip\" -rP $zipname $projdir/* > $deleteMe")!=0) {
				print STDERR "Error zipping!\n";
			}
		}
		return 1;
	}
	chdir "D:\\";
}

sub getIP {
	my $dir=shift();
	
	if ($dir =~ /\/([\d.]+)_?\w?\/?$/) {
		return $1;
	} else {
		return "";
	}
}

#<DSZ1.1>
sub moveFiles {
	my $dir=shift();
	my $ip=&getIP($dir);

	# if ($ip eq "") {
		# print STDERR "moveFiles could not get ip from $dir.  Skipping.\n";
		# return 1;
	# }
	
	my $backupname = $ip;
	if ($ip eq "") {
		$dir =~ /.{3}(.+)/;
		$backupname = $1;
	}
	
	while (-e "$backupdir/$backupname") {
		print STDERR "Renaming $backupname to $backupname\_, to avoid duplication\n";
		$backupname=$backupname."_";
	}
	if (not(-e $backupdir)) {
		print STDERR "$backupdir did not exist!\n";
		mkpath($backupdir);
	}
	if (not(-e "$backupdir\\Logs")) {
		mkpath("$backupdir\\Logs");
	}
	if (-e $dir) {
		if (not(rename("$dir","$backupdir/$backupname"))) {
			print STDERR "Couldn't rename $dir to $backupdir/$backupname: $!\n";
			print STDERR "Please close all access to the directory, then hit return.\n";
			print STDERR "(Or enter 'skip' to skip this)\n";
			my $response=<STDIN>;
			chomp($response);
			if ($response eq 'skip') {
				return 1;
			} else {
				return 0;
			}
		} else {
			my $project = $project{$dir};
			my $origZipName="$dir.zip";
			my $targetZipName;
			if ($ip eq "") {
				$targetZipName = "$backupdir/$project.zip";
			} else {
				$targetZipName = "$backupdir/$project.$ip.zip";
			}
			print "Archiving: $origZipName to $targetZipName\n";
			if (not(rename($origZipName,$targetZipName))) {
				print STDERR "Couldn't rename $origZipName to $targetZipName ($!)  Skipping.\n";
				return 1;
			} else {
				return 1;
			}
		}
	} else {
		print "There was an error moving $dir. Fix manually or find help.\n";
		return 1;
	}
	print STDERR "You are a monkey.\n";
	return 1;
}
#</DSZ1.1>


sub copyZip {
	my $dir=shift();
	
	my $ip=&getIP($dir);

	# if ($ip eq "") {
		# print STDERR "copyZip could not get ip from $dir.  Skipping.\n";
		# return 1;
	# }

	my $origZipName="$dir.zip";
	if (not(-e $origZipName)) {
		$origZipName="$dir.router.zip";
	}

	if (not(-e $origZipName)) {
		print STDERR "Whoa.  Did you forget about $dir?  Zip it now.  Hit return when you zipped it.\n";
		print STDERR "(Or enter 'skip' to skip this)\n";
		my $response=<STDIN>;
		chomp($response);
		if ($response eq 'skip') {
			return 1;
		} else {
			return 0;
		}
	}
	my $project=$project{$dir};
	#<DSZ1.1>
	my $zipName;
	if ($ip eq "") {
		$zipName = $project;
	} else {
		$zipName ="$project.$ip";
	}
	#</DSZ1.1>
	if (-e "$opdir/$zipName.zip") {
		print STDERR "Whoa!!!  $opdir/$zipName.zip already exists.  Please move it, then hit return to continue.\n";
		print STDERR "(Or enter 'skip' to skip this)\n";
		my $response=<STDIN>;
		chomp($response);
		if ($response eq 'skip') {
			return 1;
		} else {
			return 0;
		}
		return 0;
	}
	if (not(copy($origZipName,"$opdir/$zipName.zip"))) {
		print STDERR "!!! Couldn't copy $dir.zip to zipdisk ($!)!!!  Skipping.\n";
		return 1;
	} else {
		return 1;
	}
	print STDERR "You are a monkey.\n";
	return 1;
}


sub retryUntilOkay {
	my $subroutine=shift();
	my @args=@_;
	my $return=0;
	while ($return==0) {
		$return=&$subroutine(@args);
#		unless ($return) {
#			print STDERR "Bad retval ($return) with @args\n";
#		}
	}
	return 1;
}

#############

sub doBootdepth {
	my $dir=shift();
	if (not(-e "$dir/bootdepth.log")) {
		my $bootDir="$mainpath/bootdepth";
		my $bootdepth="$bootDir/bootdepth.pl";
		if (-e $bootdepth) {
			chdir($dir);
			my $sysline="perl $bootdepth -x $bootDir -d $dir";
			print "Running $bootdepth in $dir\n";
			system($sysline);
		}
	}
}

sub doDSParser {
	my ($dir,$maindir)=@_;
	if ((defined($dir)) and
		not(defined($maindir))) {
		return &doDSParser($dir,$dir);
	}

	print "DS parsing $dir ($maindir)\n";

	my $ip=&getIP($maindir);

	opendir DIR, $dir;
	my @files=readdir DIR;
	closedir DIR;
	
	foreach my $file (@files) {
#		print "  checking $file\n";
		if ($file =~ /^\.\.?$/) {
			next;
		}
		if ($file =~ /^vga_ds.tff_(?:all_)?(.*)/i) {
			my $sysline="$opsdisk/resources/darkskyline/DS_ParseLogs.exe $dir/$file ${ip}_$1";
			print "Found DarkSkyline log: parsing out capture files.\n";
			print "  running $sysline\n";
			my $dsDir="$maindir/darkskyline";
			if (not(mkdir($dsDir))) {
				print STDERR "Couldn't make directory $dsDir!\n";
				$dsDir=$maindir;
			}
			print "  results will be put in $dsDir\n";
			chdir($dsDir);
			system($sysline);
			rename("$dir/$file","$dsDir/$file");
		}
		if (-d "$dir/$file") {
			&doDSParser("$dir/$file",$maindir);
		}
	}
}

sub dorenamer {
	my ($dir,$maindir)=@_;
	if ((defined($dir)) and
		not(defined($maindir))) {
		return &dorenamer($dir,$dir);
	}

	my $renamerLog="$dir/FILE_NAME_CONVERSION.LOG";
	my $globalRenamerLog="$maindir/FILE_NAME_CONVERSION.LOG";

	if (not(-e $renamerLog)) {
		chdir($dir);
		my $tempdir=cwd();
		print("Running c:/batch/renamer.exe in $tempdir\n");
		if (system("c:/batch/renamer.exe > $deleteMe") != 0) {
			# TODO: put this back in once renamer doesn't break when not renaming any files
			print STDERR "Error running renamer in $tempdir!!!!!!\n";
			print STDERR "Run manually, please.  Hit return when ready to continue.\n";
			<STDIN>;
		}
	} else {
		# TODO: change this to always run (will append, not overwrite)
		print "$renamerLog already exists.\n";
	}

	if (-s $renamerLog) {
		&append($renamerLog,$globalRenamerLog);
	} else {
		unlink($renamerLog);
	}

	chdir($mainpath);

	opendir DIR, $dir;
	my @files=readdir DIR;
	closedir DIR;
	
	foreach my $file (@files) {
		if ($file =~ /^\.\.?$/) {
			next;
		}
		if (-d "$dir/$file") {
			&dorenamer("$dir/$file",$maindir);
		}
	}
}

# This actually does copyget as well
# TODO: incorporate main renamer in here as well
sub dodotrenamer {
	my ($dir,$maindir)=@_;

	if ((defined($dir)) and
		not(defined($maindir))) {
		return &dodotrenamer($dir,$dir);
	}

	my $renamerLog="$dir/FILE_NAME_CONVERSION.LOG";
	my $copygetRenamerLog="$dir/COPYGET_NAME_CONVERSION.LOG";
	my $globalRenamerLog="$maindir/FILE_NAME_CONVERSION.LOG";
	my $copygetLog="$dir/copyget.log";
	my $globalCopygetLog="$maindir/copyget.log";

	chdir($dir);
	my $tempdir=cwd();
#	print("Running c:/batch/dotrenamer.pl in $tempdir\n");
	if (system("c:/batch/dotrenamer.pl -pattern Q > $deleteMe") != 0) {
		print STDERR "Error running dotrenamer in $tempdir!!!!!!\n";
		print STDERR "Run manually, please.  Hit return when ready to continue.\n";
		<STDIN>;
	}
	chdir($mainpath);

	if (-s $renamerLog) {
		&append($renamerLog,$globalRenamerLog);
	} else {
		unlink($renamerLog);
	}

	if (-s $copygetLog) {
		&append($copygetLog,$globalCopygetLog);
	}
	if (-s $copygetRenamerLog) {
		&append($copygetRenamerLog,$globalRenamerLog);
	}

	opendir DIR, $dir;
	my @files=readdir DIR;
	closedir DIR;
	
	foreach my $file (@files) {
		if ($file =~ /^\.\.?$/) {
			next;
		}
		if (-d "$dir/$file") {
			&dodotrenamer("$dir/$file",$maindir);
		}
	}
}

sub append {
	my ($input, $mainfile)=@_;
	if ($input eq $mainfile) {
		return;
	}

	print "Appending $input to $mainfile\n";

	open INPUT, $input or print STDERR "Can't open $input for reading!\n";
	my $stripUniHeader=0;
	if (-e $mainfile) {
		$stripUniHeader=1;
	}
	open MAIN, ">>$mainfile" or print STDERR "Can't open $mainfile for appending!\n";
	binmode(INPUT);
	binmode(MAIN);
	my $line;
	if (defined($line=<INPUT>)) {
		if ($stripUniHeader) {
			$line =~ s/^\xff\xfe//;
		}
		if ($line) {
			print MAIN $line;
		}
	}
	while (defined($line=<INPUT>)) {
		print MAIN $line;
	}
	close MAIN;
	close INPUT;
	unlink($input);
}

sub EditOpNotes {
	my $opnotes = shift;
	print "Would you like to edit the $opnotes file now? y/[N] : ";
	my $temp = <STDIN>;
	chomp($temp);
	if ($temp =~ /\s*y/i) {
		print "exit opnotes to continue...\n\n";
		system("notepad $opnotes");
	}
}

sub compare_macs {
	my ($file1, $file2) = @_;
	my @macs;
	open FILE1, "<$file1";
	while (my $i = <FILE1>) {
		if ($i =~ /MAC/i ) {
			push @macs, $i;
		}
	}
	close FILE1;
	my $fail = 1;
	open FILE2, "<$file2";
	while (my $i = <FILE2>) {
		if ($i =~ /MAC/i) {
			foreach my $m (@macs) {
				if ($i eq $m) {
					$fail = 0;
					last;
				}
			}
		}
	}
	close FILE2;
	
	return $fail;
}

__END__
