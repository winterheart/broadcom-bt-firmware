#!/usr/bin/perl

# This tool is part of broadcom-bt-firmware project 
# https://github.com/winterheart/broadcom-bt-firmware
# 
# MIT License
#
# Copyright (c) 2016 Azamat H. Hackimov <azamat.hackimov@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use warnings;
use strict;
use 5.10.0;

use Regexp::Grammars;
use Getopt::Long;
use File::Basename;
use File::Path;
use Pod::Usage;
#use Data::Dumper;

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
my $help = 0;
my $device_list;

GetOptions ("inf_file|f=s"	=> \$filename,
	"hex2hcd=s"		=> \$hex2hcd,
	"output|o=s"		=> \$output,
	"devices=s"		=> \$device_list,
	"help|h"		=> \$help,
);

if (! -x $hex2hcd) {
	say ("hex2hcd ($hex2hcd) is not found. Install bluez package and try again. You can also define hex2hcd to --hex2hcd option.");
	exit 1;
}

if ($help) {
	pod2usage(-verbose=>2, -exitval=>0);
}


if (! $filename) {
	pod2usage(-verbose=>1, -exitval=>1, -message => "You need to specify INF-file!");
}

open(my $in,"<",$filename) or die "$! on $filename";
my $inf_file = do {
	local $/; 
	<$in>;
};

# Convert to UNIX \n
$inf_file =~ s/\cM//g;
# FIXME - Remove all strings with beginning comments - parsers can't handle them
$inf_file =~ s/^;.*//gm;

my $parsed;

if ($inf_file =~ $parser) {
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
	return 0;
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

my $inf_content = $$parsed{'InfFile'}{'Element'};
my $section = find_section($inf_content, 'Version');

my @versions = find_value($section, 'DriverVer');
my (undef, $version) = split(',', $versions[0]);
say("Version is $version.");

$section = find_section($inf_content, 'Manufacturer');

my @names = ('%MfgName%', '%MfgName64%');
my @os_sections;

foreach my $name (@names) {
	my @manufacturer = find_value($section, $name);
	foreach my $i (@manufacturer) {
		my @strings = split(',', $i);
		# trim leading and trailing spaces
		foreach my $i (@strings) {
			$i =~ s/^\s+|\s+$//g;
		}
		for my $i (1..$#strings) {
			push(@os_sections, "$strings[0].$strings[$i]");
		}
	}
}

my %devices;

foreach my $os_section (@os_sections) {
	$section = find_section($inf_content, $os_section);
	if ($section == 0) {
		say("There no [$os_section] section");
		next;
	}

# Initial information
	say("Getting general information in section [$os_section]");
	foreach my $name ($$section{Section}{SectionContent}) {
		foreach my $i (@$name) {
			if ($$i{Parameter}) {
	#			print "$$i{Parameter} -- $$i{Value}\n";
				my ($device_name, $device_id) = split(',', $$i{Value});
				$device_id =~ /USB\\[Vv][Ii][Dd]_([0-9a-fA-F]{4})&[Pp][Ii][Dd]_([0-9a-fA-F]{4})/;
				$devices{$device_name}{VID} = lc($1);
				$devices{$device_name}{PID} = lc($2);
				if ($$i{Comment}[0]) {
					$$i{Comment}[0] =~ s/; //;
				}
				$devices{$device_name}{comment} = $$i{Comment}[0];
			}
		}
	}

	say("Searching devices");
	# Find HEX files from sections
	foreach my $device (keys %devices) {
		$section = find_section($inf_content, "$device.NT");
		my @copyfiles = find_value($section, "CopyFiles");
		foreach my $copy (@copyfiles) {
	#		print "$copy\n";
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
}


# Last step - convert HEX to HCD
my $base_path = dirname($filename);

if (! -d $output) {
	mkpath($output);
}

foreach my $device (keys %devices) {
	if($devices{$device}{hex}) {
		system($hex2hcd, "$base_path/$devices{$device}{hex}" , "-o", "$output/$devices{$device}{hcd}");
	}
}

# Generate list of supported devices 
if ($device_list) {
	open(my $DEV_FILE, ">", $device_list);

	print($DEV_FILE "# Supported devices\n\n");
	print($DEV_FILE "This file is autogenerated from Broadcom Bluetooth driver version $version\n\n");
	print($DEV_FILE "| Device ID | Firmware file            | Device name |\n");
	print($DEV_FILE "| --------- | ------------------------ | ----------- |\n");

	my @sorted = sort { "$devices{$a}{VID}:$devices{$a}{PID}" cmp "$devices{$b}{VID}:$devices{$b}{PID}" } keys %devices;

	foreach my $i (@sorted) {
		if ($devices{$i}{hcd}) {
			print($DEV_FILE "| $devices{$i}{VID}:$devices{$i}{PID} | $devices{$i}{hcd} | $devices{$i}{comment} |\n");
		}
	}

	close($DEV_FILE);
}

__END__

=head1 NAME

bt-fw-converter - script that generates hcd-files from hex ones based on
information from inf-file for Broadcom Bluetouth devices

=head1 SYNOPSIS

bt-fw-converter <-f FILENAME> [OPTIONS]

Options:

=over 30

=item -f,--filename I<FILENAME>

path to INF-file that contain inforamtion about Bluetouth drivers (usually,
bcbtums-win8x64-brcm.inf)

=item --devices I<FILENAME>

generate list of supported devices (Markdown syntax)

=item -o,--output I<OUTPUT>

path for generated HCD-files

=item --hex2hcd I<PATH>

path to hex2hcd utility ('/usr/bin/hex2hcd' by default)

=item -h,--help

this help

=back

=head1 DESCRIPTION

This tool is part of L<broadcom-bt-firmware|https://github.com/winterheart/broadcom-bt-firmware>
project intentended to provide firmware of Broadcom WIDCOMM Bluetooth devices
(including BCM20702, BCM20703, BCM43142 chipsets and other) for Linux kernel.

=head1 LICENSE

Firmware files are licensed under
L<Broadcom WIDCOMM Bluetooth Software License Agreement|LICENSE.broadcom_bcm20702>.
Other parts of project are licensed under standard MIT license.

=head2 MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 AUTHOR

Copyright (c) 2016 Azamat H. Hackimov <azamat.hackimov@gmail.com>

<https://github.com/winterheart/broadcom-bt-firmware>

=cut
