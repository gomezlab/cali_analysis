#!/usr/bin/perl

################################################################################
# Global Variables and Modules
################################################################################

use strict;
use File::Basename;
use Getopt::Long;

my %opt;
$opt{debug} = 0;
GetOptions(\%opt, "template=s", "debug|d") or die;

################################################################################
# Main
################################################################################

my $revision_num = &get_revision_number();

open INPUT, "$opt{template}" or die $!;
my @template_file = <INPUT>;
close INPUT;

my @temp = shift @template_file;
push @temp, "%Revision Number: $revision_num\n";
push @temp, @template_file;
@template_file = @temp;

my $template_filename = basename($opt{template});
my $template_dirname = dirname($opt{template});

my @files_text;

for (<$template_dirname/*>) {
	if ($_ =~ /$template_filename/) {
		next;
	}
	open INPUT, "$_" or die "$!";
	push @files_text, <INPUT>;
	close INTUT;

	push @files_text, "\n\n";
}

for (<"shared/*">) {
	if ($_ =~ /$template_filename/) {
		next;
	}

	open INPUT, "$_" or die "$!";
	push @files_text, <INPUT>;
	close INTUT;

	push @files_text, "\n\n";
}

my $output_file = "temp.m";
if ($opt{template} =~ /(.*\/.*)_template.m/) {
	$output_file = $1 . ".m";
}

open OUTPUT, ">$output_file";
print OUTPUT @template_file;
print OUTPUT @files_text;
close OUTPUT;

################################################################################
# Functions
################################################################################

sub get_revision_number {
	my @rev_data = `svn info`;
	
	my $rev;
	for (@rev_data) {
		if (/Revision: (\d+)/) {
			$rev = $1;
		}
	}
	return $rev;
}
