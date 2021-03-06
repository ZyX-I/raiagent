# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI=5

# Enforce Bash strictness.
set -e

# See "COMPILING.md" in the C:DDA repository for compilation instructions.
inherit games git-2

# C:DDA has yet to release source tarballs. GitHub suffices, instead.
DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="http://www.cataclysmdda.com"
EGIT_REPO_URI="git://github.com/CleverRaven/Cataclysm-DDA.git"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
KEYWORDS=""
IUSE="clang lua ncurses sdl"
REQUIRED_USE="
    lua? ( sdl )
    || ( ncurses sdl )
"

RDEPEND="
	sys-devel/gettext:0=[nls]
	sys-libs/glibc:2.2=
	lua? ( >=dev-lang/lua-5.1:0= )
	ncurses? ( sys-libs/ncurses:5= )
	sdl? (
		media-libs/libsdl2:0=
		media-libs/sdl2-ttf:0=
		media-libs/sdl2-image:0=[jpeg,png]
		media-libs/freetype:2=
	)
"
DEPEND="${RDEPEND}
	clang? ( sys-devel/clang )
	!clang? ( sys-devel/gcc[cxx] )
"

S="${WORKDIR}/Cataclysm-DDA-${PV}"

# Absolute path of the target directory to install Cataclysm to.
CATACLYSM_HOME="${GAMES_PREFIX}/${PN}"

# The Makefile is surprisingly Gentoo-friendly. (Thanks!)
src_prepare() {
	# Strip the following from the the Makefile:
	#
	# * Hardcoded optimizations (e.g., "-O3").
	# * g++ option "-Werror", converting compiler warnings to errors and hence
	#   failing on the first (inevitable) warning.
	sed -i\
		-e '/OTHERS += /s~ -O3~~'\
		-e '/RELEASE_FLAGS = /s~ -Werror~~'\
		'Makefile'

	# The Makefile assumes subdirectories "obj" and "obj/tiles" both exist,
	# which (of course) they do not. Create such subdirectories manually.
	mkdir -p obj/tiles
}

src_compile() {
	# Options to be passed to emake() below. Unconditionally enable "RELEASE=1" to
	# compile release rather than debug builds.
	local -a emake_options; emake_options=( RELEASE=1 )
	use clang && emake_options+=( CLANG=1 )
	use lua   && emake_options+=( LUA=1 )

	# If optional Gentoo-specific string global ${LINGUAS} is defined (e.g., in
	# "make.conf"), pass all such whitespace-delimited locales.
	[ -n "${LINGUAS+x}" ] && emake_options+=( LANGUAGES="${LINGUAS}" )

	# If enabling ncurses, compile the ncurses-based executable.
	if use ncurses; then
		einfo 'Compiling ncurses interface...'
		emake "${emake_options[@]}"
	fi

	# If enabling SDL, compile the SDL-based executable.
	if use sdl; then
		einfo 'Compiling SDL interface...'
		emake "${emake_options[@]}" TILES=1
	fi
}

# The Makefile defines no "install" target. ("A pox on yer scurvy grave!")
src_install() {
	# Install executable-agnostic data files.
	insinto "${CATACLYSM_HOME}"
	doins -r data

	# If enabling ncurses, install the ncurses-based executable.
	if use ncurses; then
		# The "cataclysm" binary expects to be executed from its home directory.
		# Install a shell script "cataclysm-dda-ncurses" ensuring this. While
		# the tarball prebundles a similar wrapper "cataclysm-launcher", such
		# script is both trivial and *NOT* terribly helpful.
		games_make_wrapper "${PN}-ncurses" ./cataclysm "${CATACLYSM_HOME}"

		# Install such executable.
		exeinto "${CATACLYSM_HOME}"
		doexe cataclysm
	fi

	# If enabling SDL, install the SDL-based executable and support files.
	if use sdl; then
		# Install such executable and wrapper, as above.
		games_make_wrapper "${PN}-sdl" ./cataclysm-tiles "${CATACLYSM_HOME}"
		exeinto "${CATACLYSM_HOME}"
		doexe cataclysm-tiles

		# Install SDL support files.
		insinto "${CATACLYSM_HOME}"
		doins -r gfx
	fi

	# Force game-specific user and group permissions.
	prepgamesdirs

	# Since playing Cataclysm requires write access to its home directory,
	# forcefully grant such access to users in group "games". This is (clearly)
	# non-ideal, but there's not much we can do about that... at the moment.
	fperms -R g+w "${CATACLYSM_HOME}"

	# Install documentation.
	dodoc CONTRIBUTING.md README.md
}
