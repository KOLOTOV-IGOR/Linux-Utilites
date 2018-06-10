#!/usr/bin/env perl
use 5.016;
use warnings;
use Getopt::Long;
#use Filesys::DiskUsage qw(du);

our ($cpu, $disk, $charge, $net);
GetOptions( 	'disk=s' => \$disk, 
		'cpu=s' => \$cpu, 
		'ch|charge=s' => \$charge,
		'net=s' => \$net,
		'h|help' => sub { &help; },
);

sub help {
	say "Usage:";
        say "\t --disk print name of file or directory to know size of directory or file in kB";
	say "\t --cpu print total/free/percent to know cpu size";
	say "\t -ch | --charge print the charge of laptop battery";
        say "\t -h | --help    - print usage";
}

sub test {
	say $_[0];
	my %con = (1=>"one", 2=>"two");
	my $r = \%con;
	return $r;	
}

sub cpu {
	my ($option) = @_;
	if ($option eq "total") {
		my $cpu_info = "/proc/meminfo";
		#say "Yes" if (-f $cpu_info);
		my $cpu_total;
		open(my $fh, '<', $cpu_info) or die $!;	
		while(<$fh>) {
			my $data = $_;
			if ($data =~ /^MemTotal/) {
				$cpu_total = $data;
				last;
			}
		}
		close($fh) or warn $!;
		my ($size) = $cpu_total =~ /(\d+\skB)$/;
		return $size;
	} elsif ($option eq "free") {
		my $cpu_info = "/proc/meminfo";
		my $cpu_free;
		open(my $fh, '<', $cpu_info) or die $!;	
		while(<$fh>) {
			my $data = $_;
			if ($data =~ /^MemFree/) {
				$cpu_free = $data;
				last;
			}
		}
		close($fh) or warn $!;
		my ($size) = $cpu_free =~ /(\d+\skB)$/;
		return $size;
	} elsif ($option eq "percent") {
		my $cpu_info = "/proc/meminfo";
		my ($cpu_total, $cpu_free);
		open(my $fh, '<', $cpu_info) or die $!;	
		while(<$fh>) {
			my $data = $_;
			my $f = 0; my $t = 0;
			if ($data =~ /^MemTotal/) {
				($cpu_total) = $data =~ /(\d+)\skB$/;
				$t = 1;
			}
			if ($data =~ /^MemFree/) {
				($cpu_free) = $data =~ /(\d+)\skB$/;
				$f = 1;
			}
			last if ($t and $f);
		}
		close($fh) or warn $!;
		#say $cpu_total." ".$cpu_free;
		my $occupation = ($cpu_total - $cpu_free)/$cpu_total * 100;
		return $occupation." %";
	} else {
		say "NO!";
	}
}

sub size_of_content {
	my ($path) = @_;
	if (-f $path) {
		say "$path is a File!";
	} elsif (-d $path) {
		say "$path is a Directory!";
		opendir(my $dh, $path) or die "Cannot open dir: $!";
		my @list = readdir($dh);
		@list = grep(!/^\.\.?$/, @list);
		#say "@list";
		my @sizes; my $total_size;
		foreach my $v (@list) {
			my $file = join('/', $path, $v);	
			my $size = -s $file;
			push(@sizes, $size);
			$total_size += $size;
		}
		closedir($dh);	
		#say "@sizes";
		return $total_size;
	} else {
		say "$path is not a directory or file!";
	}	
}

sub battery {
	my $res = qx("acpi");
	my @temp = split(",", $res);
	my ($charge) = $temp[1] =~ /\s(\d+%)/; 
	return $charge;
}

sub net_interfaces {
	my $str = qx(ifconfig);
	my @list;
	@list = split(/\n/, $str);
	@list = grep(!/^\s+/, @list);
	@list = map($_ =~ /^([^\s]+)/, @list);
	return "@list";
}

sub monitor {
	my ($disk, $cpu, $net, $charge) = @_;

	my $size = size_of_content($disk) if (defined $disk);
	my $size_cpu = cpu($cpu) if (defined $cpu);
	my $battery =  battery() if (defined $charge and $charge eq "%");
	my $net_interfaces = net_interfaces() if (defined $net and $net eq "net");
	my %config = (	"Size of $disk" => $size." kB", 
			"The occupation of CPU(%): " => $size_cpu, 
			"Battery charge: " => $battery,
			"Available network interfaces: " => $net_interfaces,
	);
	while (my ($k,$v) = each %config) {
		say $k."\t".$v if (defined $k && $v);
	}
}


monitor($disk, $cpu, $net, $charge);









#my $r = test();
#say $r->{1};
__END__
