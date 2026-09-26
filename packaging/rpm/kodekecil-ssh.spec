Name:           kodekecil-ssh
Version:        0.1.0
Release:        1%{?dist}
Summary:        Open source SSH client for Linux — the budget Termius
License:        MIT
URL:            https://github.com/vhmns14/kodekecil-ssh
BuildArch:      x86_64
Requires:       gtk3, libsecret
# _bundle: path to `flutter build linux --release` output (the bundle directory)

%description
KodeKecil SSH — an open source SSH client for Linux (and Android).
Local-first, no account required, private keys stored in Secret Service.
Lightweight, no Electron.

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/kodekecil-ssh
cp -r %{_bundle}/* %{buildroot}%{_datadir}/kodekecil-ssh/
cat > %{buildroot}%{_bindir}/kodekecil-ssh <<'EOF'
#!/bin/sh
exec /usr/share/kodekecil-ssh/kodekecil_ssh "$@"
EOF
chmod +x %{buildroot}%{_bindir}/kodekecil-ssh
mkdir -p %{buildroot}%{_datadir}/applications
cat > %{buildroot}%{_datadir}/applications/kodekecil-ssh.desktop <<'EOF'
[Desktop Entry]
Name=KodeKecil SSH
Comment=Open source SSH client — the budget Termius
Exec=kodekecil-ssh
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Network;RemoteAccess;
EOF

%files
%{_bindir}/kodekecil-ssh
%{_datadir}/kodekecil-ssh/
%{_datadir}/applications/kodekecil-ssh.desktop

%changelog
* Sat Sep 26 2026 Vahmi Sofyan - 0.1.0-1
- Initial v0.1.0: host list, SSH terminal, SFTP browser, snippets
