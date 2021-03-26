#!/usr/bin/perl
use warnings;
use strict;

use Data::Dump qw(dump);

our $out;
our $type = '';
our $export;

sub dump_out {
	warn "# out = ",dump($out);

	if ( $type eq 'passwd' ) {
		push @{ $export->{$type} }, join(':',
			$out->{uid},
			'*',
			$out->{uidNumber},
			$out->{gidNumber},
			$out->{gecos},
			$out->{homeDirectory},
			$out->{loginShell},
		);
	} elsif ( $type eq 'group' ) {
		my @members;
		@members = @{ $out->{member} } if $out->{member};
		push @{ $export->{$type} }, join(':',
			$out->{cn},
			'*',
			$out->{gidNumber},
			join(',', @members)
		);
	} elsif ( $type ) {
		die "unknown $type";
	}
	undef $out;
}



while(<>) {
	chomp;

	if ( m/^$/ && $out ) {
		dump_out;
		$type = '';
	}

	if ( m/objectClass: posixgroup/ ) {
		$type = 'group';
	} elsif ( m/objectClass: posixaccount/ ) {
		$type = 'passwd';
	}

	if ( $type eq 'passwd' ) {
		if ( m/(uid|uidNumber|gidNumber|homeDirectory|loginShell|gecos): (.+)/ ) {
			$out->{$1} = $2;
		}
	} elsif ( $type eq 'group' ) {
		if ( m/(cn|gidNumber): (\S+)/ ) {
			$out->{$1} = $2;
		} elsif ( m/member: uid=([^,]+),/ ) {
			push @{ $out->{member} }, $1;
		}
	}
}

dump_out if $out;

warn "# export = ",dump( $export );

foreach my $file ( keys %$export ) {
	my $filename = $file . '.from-ldap';
	my $entries = 0;
	open(my $fh, '>', "$file.from-ldap");
	foreach my $line ( @{ $export->{$file} } ) {
		print $fh $line . "\n";
		$entries++;
	}
	close($fh);
	print "$filename has $entries entries and ", -s $filename, " bytes\n";
}
