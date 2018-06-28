#
# spec file for package yast2-boot-server
#
# Copyright (c) 2014 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

Name:           yast2-boot-server
Version:        4.0.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
BuildRequires:	update-desktop-files
BuildRequires:  yast2
BuildRequires:  yast2-devtools >= 3.0.6
BuildRequires:  yast2-testsuite
Requires:	yast2

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Network Booting and Wake-On-Lan Configuration

%description
YaST2 module for network booting and Wake-On-Lan.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install

%files
%defattr(-,root,root)
%{yast_clientdir}/wol.rb
%{yast_moduledir}/WOL.rb
%{yast_desktopdir}/wol.desktop

%dir %{yast_docdir}
%doc %{yast_docdir}/COPYING
