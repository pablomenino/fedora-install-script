#!/usr/bin/perl

#----------------------------------------------------------------------------------------
# Fedora Install Script
# Version: 0.4.1
# 
# WebSite:
# https://git.mfwlab.com/lab/fedora-install-script/
# 
# Copyright © 2020 - Pablo Meniño <pablo.menino@mfwlab.com>
#----------------------------------------------------------------------------------------

#----------------------------------------------------------------------
# Use declaration -----------------------------------------------------

use strict;
use warnings;
use Time::Local;
use Cwd;
use Cwd qw(abs_path);
use File::Basename;
use Switch;
use File::Path;
use Fcntl;
use Time::Progress;
use Term::ReadKey;

#----------------------------------------------------------------------
# Variables -----------------------------------------------------------

# Version Control
my $version = "0.4";
my $config_version = "0.4";
my $package_version = "0.4";

# Configuration file format ... that can be opened
my @version_check = ("0.1", "0.2", "0.3", "0.4");

# Package file format ... that can be opened
my @package_check = ("0.1", "0.2", "0.3", "0.4");

# Home directory
my $home = $ENV{"HOME"};

# Get Install Directory
my $script_dir = dirname(abs_path($0));

# Creates an unusual filename based on nanoseconds so that
# you don't accidentally overwrite another logfile.
my $nano = `date '+%d-%m-%Y_%H-%M-%S'`;
# Remove return line
chomp($nano);
$nano = "_" . $nano;

# Configuration variables
my ($GenerateLog, $LogPath, $LogMask, $Update, $InstallBasedOnHostName, $RunSudo, $ShowProgressWindows) = "";

# Configuration dir
my $cfg_dir_filename = $script_dir . "/";

# Configuration File
my $cfg_filename = $cfg_dir_filename . "fedora-install-script.config" ;

# Package variables
my ($PackageName, $CatName) = "";

# Command to execute
my $command = "" ;

# Get hostanme
my $host_name = `hostname`;
# Remove return line
chomp($host_name);

# Package list dir
my $pkg_dir_filename = $script_dir . "/";

# The location of executable
my $sudo = `which sudo`;
my $dnf = `which dnf`;
# Remove return line
chomp($sudo);
chomp($dnf);

# Get terminal size
my ($cols,$rows) = GetTerminalSize();

#----------------------------------------------------------------------
# Functions - print_help --------------------------------------------------------

sub print_help()
{
	print_version();
	print "Usage: $0 [options]\n";
	print "\n";
	print "options:\n";
	print "  --print_help                       - Print this help\n";
	print "  --print_version                    - Print version info\n";
	print "  --install_pkg                      - Install all packages from file\n";
	print "  --install_pkg_cat 'category_name'  - Install only the packages in the selected category\n";
	print "\n";
}

#----------------------------------------------------------------------
# Functions - print_version --------------------------------------------------------

sub print_version()
{
	print "Fedora Install script - Version $version\n";
	print "Copyright © 2020 - Pablo Meniño <pablo.menino\@mfwlab.com>\n";
	print "\n";
}

#----------------------------------------------------------------------
# Functions - read_config --------------------------------------------------------

sub read_config()
{
	# Return values:
	# 0: OK
	# 1: Not a valid config file
	# 2: Config File version not supported
	# 3: Executed failed

	my $nth = "";
	my $is_cfg_file = "false";
	my $version_cfg_file = "";
	my $return_value = 3;

	if (! -e $cfg_filename)
	{
		die "ERROR: File $cfg_filename doesn\'t exist\n";
	}

	# CFG
	open (FILECFG, $cfg_filename);
	while (<FILECFG>)
	{
		chomp($_);
		$nth = substr($_, 0, 1);
	
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($GenerateLog, $LogPath, $LogMask, $Update, $InstallBasedOnHostName, $RunSudo, $ShowProgressWindows) = split( "\t", $_, 7);
		
			if ( $GenerateLog eq "ConfVersion" )
			{
				$is_cfg_file = "true";
				$version_cfg_file = $LogPath;
			}

		}

	}
	close (FILECFG);

	# If value version_check is found in cfg file ... then check if this is supported.
	if ($is_cfg_file eq "true" )
	{
		# Not supported version by default
		my $cfg_file_support = 1;
		my $version_check = "";
		foreach $version_check (@version_check)
		{
			if ( ($cfg_file_support == 1) && ($version_check eq $version_cfg_file) )
			{
				$cfg_file_support = 0;
			}
		}
		
		# If old version, then migrato to new.
		if ( $cfg_file_support == 1 )
		{
			# Not supported version
			$return_value = 2;
		}
		elsif ( $cfg_file_support == 0 )
		{
			# All checks are ok, continue
			$return_value = 0;
		}
		
	}
	else
	{
		# Not a valid config file
		$return_value = 1;
	}

	return $return_value;
}

#----------------------------------------------------------------------
# Functions - read_config_and_check --------------------------------------------------------

sub read_config_and_check()
{
	my $exit_code = read_config;

	if ( $exit_code == 1 )
	{
		die "ERROR: Not a valid config file\n";
	}
	elsif ( $exit_code == 2 )
	{
		die "ERROR: Config File version not supported\n";
	}
	elsif ( $exit_code == 3 )
	{
		die "ERROR: Executed failed\n";
	}
}

#----------------------------------------------------------------------
# Functions - read_package --------------------------------------------------------

sub read_package()
{
	
	my $category_pkg = $_[0];
	my $pkg_list_file = "";
	# Return values:
	# 0: OK
	# 1: Not a valid package file
	# 2: Package File version not supported
	# 3: Executed failed

	my $nth = "";
	my $is_cfg_file = "false";
	my $version_cfg_file = "";
	my $return_value = 3;

	# If InstallBasedOnHostName is true in config then load the file for that host
	if ( $InstallBasedOnHostName eq "true" )
	{
		$pkg_list_file = $pkg_dir_filename . $host_name . ".config";
	}
	else
	{
		$pkg_list_file = $pkg_dir_filename . "general.config";
	}

	if (! -e $pkg_list_file)
	{
		die "ERROR: File $pkg_list_file doesn\'t exist\n";
	}

	# PackageFile
	my @pkg_to_install;
	open (FILEPKG, $pkg_list_file);
	while (<FILEPKG>)
	{
		chomp($_);
		$nth = substr($_, 0, 1);
	
		# If not caracter NULL or #, then read config.
		if ( $nth ne "#" and $nth ne "" )
		{

			($PackageName, $CatName) = split( "\t", $_, 2);
		
			if ( $PackageName eq "PackageSelectionVersion" )
			{
				$is_cfg_file = "true";
				$version_cfg_file = $CatName;
			}
			elsif ( $category_pkg eq "default_all" )
			{
				push @pkg_to_install, $PackageName;
			}
			elsif ( $CatName eq $category_pkg )
			{
				push @pkg_to_install, $PackageName;
			}
		}

	}
	close (FILEPKG);
		
	# If value package_check is found in file ... then check if this is supported.
	if ($is_cfg_file eq "true" )
	{
		# Not supported package by default
		my $cfg_file_support = 1;
		my $version_check = "";
		foreach $version_check (@version_check)
		{
			if ( ($cfg_file_support == 1) && ($version_check eq $version_cfg_file) )
			{
				$cfg_file_support = 0;
			}
		}
		
		# If old version, then migrato to new.
		if ( $cfg_file_support == 1 )
		{
			# Not supported version
			$return_value = 2;
		}
		elsif ( $cfg_file_support == 0 )
		{
			# All checks are ok, continue
			# Install packages - Begin
			my $pkg_name;
			my $cmd;
			my $cmd_result = 0;
			my $cmd_result_0 = 0;
			my $cmd_result_other = 0;
			my $pkg_name_fix = "";
			
			my $pkg_number = 0;
			my $pkg_size = scalar @pkg_to_install;
			
			if ($pkg_size < 1)
			{
				die "ERROR: No packages to install. Check configuration files.\n";
			}

			# Check config for Update parameter, if this is true, run dnf update -y
			if ($Update eq "true")
			{
				print "Running DNF update\n";
	
				$cmd_result = update_cmd();
				if ($cmd_result != 0 )
				{
					die "ERROR: DNF update failed, check DNF logs for more information.\n";
				}
				else
				{
					print "\nDNF update done.\n\n";
				}

			}
			
			print "Install packages: The selected category is $category_pkg\n";
			
			$| = 1;
			my $p = new Time::Progress;

			$p->attr( min => 0, max => $pkg_size );

			# Fix size for progress bar
			my $cols_section1 = 0;
			if ($cols > 51)
			{
				$cols_section1 = int($cols-50);
			}
			
			foreach $pkg_name (@pkg_to_install)
			{
				
				$pkg_number=$pkg_number+1;

				my $sudo_tmp="";
				if ( $RunSudo eq "true" )
				{
					$sudo_tmp=$sudo;
				}
				else
				{
					$sudo_tmp="";
				}

				$cmd = $sudo_tmp . " " . $dnf. " -y install " . $pkg_name . " >/dev/null 2>&1";
												
				# Terminal size - cut string if more than 20 caracters
				$pkg_name_fix = pack("A20",$pkg_name);
			
				# If terminal size is lower than 51, auto adjust progress bar size
				if ($cols_section1 == 0)
				{
					print $p->report("[" . $pkg_number . "/" . $pkg_size ."] $pkg_name_fix |" . "%L %p\r", $pkg_number);
				}
				else
				{
					print $p->report("[" . $pkg_number . "/" . $pkg_size ."] $pkg_name_fix |" . "%L %". $cols_section1 ."b %p\r", $pkg_number);
				}

				$cmd_result = &execute_cmd( $cmd );
				if ($cmd_result == 0 )
				{
					$cmd_result_0=$cmd_result_0+1;
				}
				else
				{
					$cmd_result_other=$cmd_result_other+1;
				}
			}
			# Install packages - End
			print $p->report("done %p elapsed: %L (%l sec)", $pkg_number);
			print "\n\nInstalled packages:\n";
			print "Successful: " . $cmd_result_0 . " | Failed: " . $cmd_result_other . "\n";
			
			if ($cmd_result_other > 0)
			{
				print "\nWARNING: They are $cmd_result_other packages failed, see log file for more information.\n";
			}
			
			$return_value = 0;

		}
		
	}
	else
	{
		# Not a valid package file
		$return_value = 1;
	}

	return $return_value;
}

#----------------------------------------------------------------------
# Functions - read_package_and_check --------------------------------------------------------

sub read_package_and_check()
{
	my $category_pkg = $_[0];
	my $exit_code = &read_package($category_pkg);

	if ( $exit_code == 1 )
	{
		die "ERROR: Not a valid package file\n";
	}
	elsif ( $exit_code == 2 )
	{
		die "ERROR: Package File version not supported\n";
	}
	elsif ( $exit_code == 3 )
	{
		die "ERROR: Executed failed\n";
	}
}

#----------------------------------------------------------------------
# Functions - execute_cmd --------------------------------------------------------

sub execute_cmd()
{
	my $systemCommand = $_[0];
    my $returnCode = system( $systemCommand );
    return $returnCode;
}

#----------------------------------------------------------------------
# Functions - update_cmd --------------------------------------------------------

sub update_cmd()
{
	my $sudo_tmp="";

	if ( $RunSudo eq "true" )
	{
		$sudo_tmp=$sudo;
	}
	else
	{
		$sudo_tmp="";
	}

	my $returnCode = &execute_cmd($sudo_tmp . " " . $dnf. " -y update");
	return $returnCode;
}

#----------------------------------------------------------------------
# Functions - install_pkg_cat --------------------------------------------------------

sub install_pkg_cat()
{
	my $category_pkg = $_[0];
	# Install Packages
	&read_package_and_check($category_pkg);
}

#----------------------------------------------------------------------
# Functions - check_software --------------------------------------------------------

sub check_software()
{
	if ( $sudo eq "" or $dnf eq "" )
	{
		die "ERROR: DNF or SUDO binary files not found.\n";
	}
}

#----------------------------------------------------------------------
# Main - Begin --------------------------------------------------------

# Check script arguments.
if ($#ARGV < 0)
{
	print_help();
}
else
{
	switch ($ARGV[0])
	{
		case "--print_help"
		{
			print_help();
		}
		case "--print_version"
		{
			print_version();
		}
		case "--install_pkg"
		{
			# Print version
			print_version();
			# Check SUDO and DNF
			check_software();
			# Read Config
			read_config_and_check();
			# Install
			&install_pkg_cat( "default_all" );
		}
		case "--install_pkg_cat"
		{
			# Print version
			print_version();
			# Check SUDO and DNF
			check_software();
			# Check category input string
			if ( $#ARGV >= 1 )
			{
				# Read Config
				read_config_and_check();
				# Install
				&install_pkg_cat($ARGV[1]);
			}
			else
			{
				die "ERROR: No category selected\n";
			}
		}
		else
		{
			print_help();
		}
	}
}

#----------------------------------------------------------------------
# Main - End ----------------------------------------------------------
#----------------------------------------------------------------------
