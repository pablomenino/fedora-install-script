<h3 align="center">fedora-install-script</h3>
<p align="center">Personal Fedora Installation Script based on pre-configured list selecting the hostname like input and/or filter by category of packages.</p>

<p align="center">
<a href="https://github.com/pablomenino/fedora-install-script/releases"><img src="https://img.shields.io/github/release/pablomenino/fedora-install-script.svg"></a>
<a href="./LICENSE"><img src="https://img.shields.io/github/license/pablomenino/fedora-install-script.svg"></a>
</p>

Personal Fedora Installation Script based on pre-configured list selecting the hostname like input and/or filter by category of packages.

I have several VM whit Fedora, this scripts are to automatically install the based packages on this new installed OS, to make this systems ready to compile and test applications.

## Table of contents

* [How to Use](#how-to-use)
* [ToDo](#todo)

## <a name="how-to-use">How to Use

#### Requirements

* Fedora 22/23
* DNF
* User whit SUDO credentials
* Perl
* perl-Switch
* perl-Time-Progress

#### Usage

###### Application configuration

See example file fedora-install-script.config

Separate the columns with TAB (tab-delimited)

This 2 parameters are the version of the configuration file:

```bash
# Reserved values:
ConfVersion	0.4
```

Configuration parameter documentation:

```
CFG Values:
  GenerateLog: Enable logs (true or false)
  LogPath: Directory to store the logfile
  LogMask: Mask for logging file
  Update: Update OS before install packages, this execute dnf update before process package input file (true or false)
  InstallBasedOnHostName: true or false
     NOTE: If this value is false, the script read the imput packages to install from the file general.config
     Otherwise the script read the imput packages from the file whit the current hostname in the filename
     Example: if the hostname command return this:
     $ hostname
     crt72339xx
     Then the imput file is crt72339xx.config
  RunSudo: run sudo command? (true or false)
  ShowProgressWindows: Show progress Message, otherwise only run in terminal. (true or false)
```

General Configuration:

Separate the columns with TAB (tab-delimited)

```bash
# GenerateLog	LogPath	LogMask	Update	InstallBasedOnHostName	RunSudo	ShowProgressWindows
true	$HOME/fedora-install.log	0600	true	true	true	true
```

Package selection configuration (the software to install in the OS)

See examples files general.config and NORC.config

general.config is the input file when the parameter InstallBasedOnHostName is false on the configuration file.

NORC.config is the input file when the parameter InstallBasedOnHostName is true on the configuration file and the hostname is NORC on the computer that is running this script.

This 2 parameters are the version of the PackageSelection file:

```bash
# Reserved values:
PackageSelectionVersion	0.4
```

Configuration parameter documentation:

Values: <br />
  PackageName: Name of package <br />
  Category: Optional Category (see documentation) <br />

Configuration:

```bash
# PackageName	Category
screen	utility
mc	utility2
```

###### Running the script

Target hostname:

If you run the script on the computer whit hostname NORC and the parameter InstallBasedOnHostName true in the configuration file, the file NORC.config is used like input list for install the packages in the OS.

```bash
/PATH-TO-SCRIPT/fedora-install-script.pl
```

General package selection:

If you run the script on any computer whit the parameter InstallBasedOnHostName false, the file general.config is used like input list for install the packages in the OS.

```bash
/PATH-TO-SCRIPT/fedora-install-script.pl
```

Target hostname and filter install list by category:

If you run the script on the computer whit hostname NORC and the parameter InstallBasedOnHostName true in the configuration file, the file NORC.config is used like input list for install the packages in the OS but only the packages that matches whit the category selected are installed.

```bash
/PATH-TO-SCRIPT/fedora-install-script.pl utility2
```

NOTE: Based on the configuration example on this documentation, only the package mc is installed.

General package selection  and filter install list by category:

If you run the script on any computer whit the parameter InstallBasedOnHostName false, the file general.config is used like input list for install the packages in the OS but only the packages that matches whit the category selected are installed

```bash
/PATH-TO-SCRIPT/fedora-install-script.pl utility
```

NOTE: Based on the configuration example on this documentation, only the package terminator is installed.

## <a name="todo">ToDo

* Log to file
* disable ShowProgressWindows implementation (show terminal output)
