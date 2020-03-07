#!/bin/bash

platform=x86_64
pkg=pkg/packages/$platform
pkgaur=pkg/aur/$platform
temp=tmp

# Сборка пакета из AUR
 aur() {
	echo '> aur '$1
	echo '> aur '$1 >> $temp/build.log
	cd $temp
	if [ -d $1 ]; then
		cd $1
		git pull
	else
		git clone https://aur.archlinux.org/$1.git
		cd $1
	fi
	makepkg -s
	cd ../..
}

# Обновить репозиторий
rupdate() {
	echo '>> update '$1
	echo '>> update '$1 >> $temp/build.log
	pkgdir="pkg/$1/$platform"
	if [ -d $pkgdir ]; then
		cd $pkgdir
		repo-add -n -R $1.db.tar.gz *.pkg.tar.xz
		repo-add -n -R $1.db.tar.gz *.pkg.tar.zst
		cd ../../..
	else
		mkdir -p "$pkgdir/"
	fi
}

rtest() {
	echo '>> test '$1
	echo '>> test '$1 >> $temp/build.log
	pkgdir="pkg/$1/$platform"
	if [ ! -d $pkgdir ]; then
		mkdir -p "$pkgdir/"
	fi
}

ttest() {
	echo '>> test temp' >> $temp/build.log
	if [ ! -d "$temp/" ]; then
		mkdir -p $temp/
	fi
}

rpkg() {
	echo '>> package'
	echo '>> package' >> $temp/build.log
	rm -rf $temp/pkg.lst
	for package in $(cat packages.x86_64); do
		echo '> pac '$package
		echo '> pac '$package >> $temp/build.log
		pactree -sl $package >> $temp/pkg.lst
	done
	cat $temp/pkg.lst | sort -d -u -o $temp/pkg.lst
	sudo pacman -Sw $(cat $temp/pkg.lst) --noconfirm
	cp -v /var/cache/pacman/pkg/* $pkg/
}

raur() {
	echo '>> aur'
	echo '>> aur' >> $temp/build.log
	for packageaur in $(cat aur.x86_64); do
		aur ${packageaur}
		for pckg in $(ls "${temp}/${packageaur}/"*.pkg.tar.xz); do
			echo '>copy '$pckg
			echo '>copy '$pckg >> $temp/build.log
			cp -v $pckg "${pkgaur}/"
			cp -v $pckg "${pkg}/"
		done
	done
}
_help ()
{
	echo "usage ${0} [options]"
	echo
	echo " General options:"
	echo " -n new repo"
	echo " -h This help message"
	exit ${1}
}

while getopts 'n:u:h:v' arg; do
case "${arg}" in
	n) 
		rm -rf $temp/*
		rm -rf pkg/*
		(echo 'y' ; echo 'y') | sudo pacman -Scc
		;;
	h) _help 0 ;;
	*)
		echo "Invalid argument '${arg}'"
		_help 1
		;;
esac
done

ttest

rtest "packages"   2>  $temp/err.log
rtest "aur"        2>> $temp/err.log

rpkg               2>> $temp/err.log
raur               2>> $temp/err.log

rupdate "packages" 2>> $temp/err.log
rupdate "aur"      2>> $temp/err.log
