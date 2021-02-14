function list_mount_points_below() { # directory_pn

	local directory_pn=${1:?missing value for directory_pn} ; shift 1

	cat /proc/self/mountinfo | perl -e '

		my $directory_pn = "'"${directory_pn:?}"'";

		$directory_pn =~ s#/+$##;

		while( <> ) {

			@F = split;

			my $mount_point = $F[5-1]; # see proc(5) for field layout

			next unless ($mount_point =~ m#^\Q${directory_pn}\E/.+$#);

			print $mount_point . $/;
		}
	';
}
