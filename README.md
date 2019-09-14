# MPRM

MPRM (Mike's Package Repository Manager) is an OS-independent Package Repository tool.
It allows you to quickly build Debian and Yum Package Repositories.

## Purpose

MPRM can quickly build and regenerate apt or yum repositories without the need of apt-ftparchive, createrepo or crazy shell scripts.
MPRM currently has full functional support for Debian packages and package repository support for RPM packages.

MPRM for apt quickly regenerates package repositories by caching md5 hashes and checking against the cache each time Packages.gz is generated.
Usually this is unnecessary, but when there are large packages in a repository this can slow down generation times to 20-30 minutes.
MPRM proactively md5 caches.

The --directory (-d) flag can be used to move packages from a directory into your package repository.
 MPRM will look through the location passed into the -d flag and move any matching packages into their respective location.
Packages are moved based on their architecture (amd64, i386, etc).

Alternatively, you may choose to place your packages into path/dists/release/component/arch/.

## Install

```
gem install mprm
```

## Commands


```
Usage:
mprm [OPTIONS]

Options:
-t, --type TYPE               Type of repo to create
-p, --path PATH               Path to repo location
-r, --release RELEASE         OS version to create
-a, --arch ARCH               Architecture of repo contents
-c, --component COMPONENT     Component to create [DEB ONLY]
-l, --label LABEL             Label for generated repository [DEB ONLY]
-o, --origin ORIGIN           Origin for generated repository [DEB ONLY]
--nocache                     Don't cache md5 sums [DEB ONLY]
-d, --directory DIRECTORY     Move packages from directory to target (default: false)
-k, --gpg GPG KEY             Sign release files with this GPG key (default: false)
-x, --gpg_passphrase          Provide GPG passphrase to prevent prompt by GPG (default: false)
-n, --gpg_sign_algorithm      Provide GPG hash digest signing algorithm (default: false)
-h, --help                    print help
```

## Examples

```
mprm --type deb --path pool --component dev,staging --release precise --arch amd64 --gpg

mprm -t deb -p pool -c stable -r precise -a amd64 --directory unstable

mprm -t deb -p pool -c stable -r precise -a amd64 --directory unstable --gpg user@domain.com --gpg_password myPa55word

mprm -t rpm -a x86_64 -r centos6 -p pool
```

## Thanks

95% of credit for mprm goes to Brett Gailey for his `prm` gem.  He has
gone dark on GitHub so this project was forked from his hard work.
