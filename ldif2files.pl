#!/usr/bin/perl
use warnings;
use strict;

#use Data::Dump qw(dump);
use MIME::Base64;

our $out;
our $type = '';
our $export;

sub dump_out {
	#warn "# out = ",dump($out);

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

		push @{ $export->{'shadow'} }, join(':',
			$out->{uid},
			$out->{password},
			int( time() / ( 24 * 60 * 60 ) ),	# date of last password change
			0,		# minimum password age
			99999,	# maximum password age
			7,		# password warning period
			'',	# password inactivity period
			'',	# account expiration date
			'',	# reserved field
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
		} elsif ( m/(gecos):: (.+)/ ) {
			$out->{$1} = decode_base64( $2 );
		} elsif ( m/userPassword:: (.+)/ ) {
			my $password = $1;
			if ( length($_) == 79 ) { # line probably continues in next one
				my $add = <>; chomp($add);
				if ( $add =~ s{^\s}{} ) { # yes, remove leading space
					$password .= $add;
				}
			}
			$out->{password} = decode_base64( $password );
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

#warn "# export = ",dump( $export );

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
