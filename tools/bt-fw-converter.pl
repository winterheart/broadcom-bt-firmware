#!/usr/bin/perl

use warnings;
use strict;
use 5.10.0;

use Regexp::Grammars;
use Getopt::Long;
use File::Basename;
use File::Path;

my $parser = qr{
	<nocontext:>
	<InfFile>
	<rule: InfFile>	<[Element]>*
	<rule: Element> <Section> | <Comment>
	<rule: Section> <SectionDeclaration> <[SectionContent]>*
	<rule: SectionContent> <Parameter> \= <Value> <[Comment]>? | <Parameter> | <Comment>
	<rule: SectionDeclaration> \[ <SectionName> \]
	<rule: SectionName> .+
	<rule: Parameter> [.\w\d\.\%\&\$\"\,\\\{\}]+ 
	<token: Value> [.\w\d\.\%\&\$\"\,\\\{\}\ -\/]+
	<rule: Comment> ;.+
}xm;

my $filename;
my $hex2hcd = '/usr/bin/hex2hcd';
my $output = ".";

GetOptions ("inf_file|f=s"	=> \$filename,
	"hex2hcd=s"		=> \$hex2hcd,
	"output|o=s"		=> \$output);


if (! $filename) {
	die "You need to specify INF-file!\n";
}


open(my $in,"<",$filename) or die "$! on $filename";
my $inf_file = do {
	local $/; 
	<$in>;
};

$inf_file =~ s/\cM//g;

my $parsed;

if($inf_file =~ $parser) {
	$parsed = \%/;
} else {
	die "Can't parse file\n" . @!;
}


sub find_section {
	my @inf = @{ shift() };
	my $section_name = shift();

	foreach my $name (@inf) {
		if ($$name{Section}{SectionDeclaration}{SectionName} eq $section_name) {
			return $name;
		}
	}
}

sub find_value {
	my %section = %{ shift() };
	my $key = shift();
	my @result;
	foreach my $name ($section{Section}{SectionContent}) {
		foreach my $i (@$name) {
			if ($$i{Parameter} eq $key) {
				push(@result, $$i{Value});
			}
		}
	}
	return @result;

}

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $inf_content = $$parsed{'InfFile'}{'Element'};

my $section = find_section($inf_content, 'Version');
my @version = find_value($section, 'DriverVer');

print Dumper @version;
#(undef, $version) = split(',', $version);

$section = find_section($inf_content, 'Broadcom.NTamd64.10.0');

my %devices;

# Initial information
foreach my $name ($$section{Section}{SectionContent}) {
	foreach my $i (@$name) {
		if ($$i{Parameter}) {
			my ($device_name, $device_id) = split(',', $$i{Value});
			$device_id =~ /USB\\VID_([0-9a-fA-F]{4})&PID_([0-9a-fA-F]{4})/;
			$devices{$device_name}{VID} = lc($1);
			$devices{$device_name}{PID} = lc($2);
			$$i{Comment}[0] =~ s/; //;
			$devices{$device_name}{comment} = $$i{Comment}[0];
		}
	}
}

# Find HEX files from sections
foreach my $device (keys %devices) {
	$section = find_section($inf_content, "$device.NTamd64");
	my @copyfiles = find_value($section, "CopyFiles");
	foreach my $copy (@copyfiles) {
		$section = find_section($inf_content, $copy);
		foreach my $name ($$section{Section}{SectionContent}) {
			foreach my $i (@$name) {
				if (($$i{Parameter}) and ($$i{Parameter} =~ /\.hex/)) {
					$devices{$device}{hex} = $$i{Parameter};
					my ($hcd, undef) = split('_', $$i{Parameter});
					$devices{$device}{hcd} = "$hcd-$devices{$device}{VID}-$devices{$device}{PID}.hcd";
				}
			}
		}
	}
}

# Last step - convert HEX to HCD

my $base_path = dirname($filename);

if (! -d $output) {
	mkpath($output);
}

foreach my $device (keys %devices) {
	system($hex2hcd, "$base_path/$devices{$device}{hex}" , "-o", "$output/$devices{$device}{hcd}");
}

