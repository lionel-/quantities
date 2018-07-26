#!/bin/bash

TMP=/tmp/.travis_fold_name

travis_fold_start() {
  echo "$1" > $TMP
  echo -en "travis_fold:start:$1\r"
  echo -e "\033[1;33m$2\033[0m"
}

travis_fold_end() {
  echo -en "travis_fold:end:$(cat ${TMP})\r"
}

pkg_tarball() {
  tarball_script='
    $version = $1 if (/^Version:\s(\S+)/);
    $package = $1 if (/^Package:\s*(\S+)/);
    END { print "${package}_$version.tar.gz" }'
  perl -ne "${tarball_script}" DESCRIPTION
}

travis_fold_start R-build 'Building package'
R CMD build .
R CMD INSTALL $(pkg_tarball)
travis_fold_end

travis_fold_start R-check 'Checking package'
R CMD check $(pkg_tarball) --as-cran --no-manual
travis_fold_end

[[ $TRAVIS_COMMIT_MESSAGE = *"no-quantities"* ]] && exit 0

travis_fold_start revdep-check 'Checking quantities'
Rscript -e 'devtools::install_deps(dependencies=TRUE)'
R CMD build quantities
R CMD check $(pkg_tarball) --as-cran --no-manual
travis_fold_end
