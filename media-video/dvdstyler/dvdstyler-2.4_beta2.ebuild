# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/dvdstyler/dvdstyler-2.3.4.ebuild,v 1.2 2012/12/11 16:45:35 axs Exp $

EAPI=4

MY_P=${P/dvds/DVDS}
MY_P=${MY_P/_beta/b}
MY_PV=${PV/_beta/b}
WX_GTK_VER=2.8

inherit wxwidgets

DESCRIPTION="A cross-platform free DVD authoring application"
HOMEPAGE="http://www.dvdstyler.org/"
SRC_URI="mirror://sourceforge/project/${PN}/${PN}-devel/${MY_PV}/${MY_P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug gnome kernel_linux"

COMMON_DEPEND=">=app-cdr/dvd+rw-tools-7.1
	>=media-libs/libexif-0.6.16
	>=media-libs/wxsvg-1.1.9
	>=media-video/dvdauthor-0.7.0
	>=media-video/xine-ui-0.99.1
	virtual/cdrtools
	>=virtual/ffmpeg-0.10[encode]
	virtual/jpeg
	>=x11-libs/wxGTK-2.8.7:2.8[gstreamer,X]
	gnome? ( >=gnome-base/libgnomeui-2 )
	kernel_linux? ( virtual/udev )"
RDEPEND="${COMMON_DEPEND}
	>=app-cdr/dvdisaster-0.72.2"
DEPEND="${COMMON_DEPEND}
	virtual/yacc
	app-arch/zip
	app-text/xmlto
	virtual/pkgconfig
	>=sys-devel/gettext-0.17"

S=${WORKDIR}/${MY_P}

src_prepare() {
	use gnome || sed -i -e '/PKG_CONFIG/s:libgnomeui-2.0:dIsAbLeAuToMaGiC&:' configure

	# rmdir: failed to remove `tempfoobar': Directory not empty
	sed -i -e '/rmdir "$$t"/d' docs/Makefile.in || die

	sed -i -e 's:@LIBS@:& -ljpeg:' wxVillaLib/Makefile.in || die #367863
}

src_configure() {
	econf \
	 	--docdir=/usr/share/doc/${PF} \
		$(use_enable debug) \
		--with-wx-config=${WX_CONFIG}
}

src_install() {
	default
	rm -f "${ED}"usr/share/doc/${PF}/{COPYING*,INSTALL*}
}
