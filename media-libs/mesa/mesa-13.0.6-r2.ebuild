# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

PYTHON_COMPAT=( python2_7 )

inherit autotools multilib-minimal python-any-r1 pax-utils
OPENGL_DIR="${PN}"

MY_P="${P/_/-}"
FOLDER="${PV/_rc*/}"

DESCRIPTION="OpenGL-like graphic library for Linux"
HOMEPAGE="https://www.mesa3d.org/ https://mesa.freedesktop.org/
		https://mesa.freedesktop.org/"
if [[ "${PV}" == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://anongit.freedesktop.org/git/mesa/mesa.git"
	EGIT_CHECKOUT_DIR="${WORKDIR}/${MY_P}"
	SRC_URI=""
else
	SRC_URI="https://mesa.freedesktop.org/archive/${FOLDER}/${MY_P}.tar.xz"
	KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~sparc-solaris ~x64-solaris ~x86-solaris"
fi

LICENSE="MIT"
SLOT="0"
RESTRICT="!bindist? ( bindist )"

AMD_CARDS=( "r100" "r200" "r300" "r600" "radeon" "radeonsi" )
INTEL_CARDS=( "i915" "i965" "intel" )
VIDEO_CARDS=( "freedreno" "nouveau" "vc4" "vmware" )
VIDEO_CARDS+=( "${AMD_CARDS[@]}" )
VIDEO_CARDS+=( "${INTEL_CARDS[@]}" )
for card in "${VIDEO_CARDS[@]}"; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS}
	bindist +classic d3d9 debug +dri3 +egl +gallium +gbm gcrypt gles1 gles2
	libressl +llvm +nettle +nptl opencl osmesa pax_kernel openmax openssl pic
	selinux vaapi valgrind vdpau vulkan wayland xvmc xa"

REQUIRED_USE="
	|| ( gcrypt libressl nettle openssl )
	d3d9?   ( dri3 gallium )
	llvm?   ( gallium )
	opencl? ( gallium llvm )
	openmax? ( gallium )
	gles1?  ( egl )
	gles2?  ( egl )
	vaapi? ( gallium )
	vdpau? ( gallium )
	vulkan? ( || ( video_cards_i965 video_cards_radeonsi )
	          video_cards_radeonsi? ( llvm ) )
	wayland? ( egl gbm )
	xa?  ( gallium )
	video_cards_freedreno?  ( gallium )
	video_cards_intel?  ( classic )
	video_cards_i915?   ( || ( classic gallium ) )
	video_cards_i965?   ( classic )
	video_cards_nouveau? ( || ( classic gallium ) )
	video_cards_radeon? ( || ( classic gallium )
						  gallium? ( x86? ( llvm ) amd64? ( llvm ) ) )
	video_cards_r100?   ( classic )
	video_cards_r200?   ( classic )
	video_cards_r300?   ( gallium x86? ( llvm ) amd64? ( llvm ) )
	video_cards_r600?   ( gallium )
	video_cards_radeonsi?   ( gallium llvm )
	video_cards_vmware? ( gallium )
"

LIBDRM_DEPSTRING=">=x11-libs/libdrm-2.4.72"
# keep correct libdrm and dri2proto dep
# keep blocks in rdepend for binpkg
# shellcheck disable=SC2124
RDEPEND="
	!<x11-base/xorg-server-1.16.4-r6
	!<=x11-proto/xf86driproto-2.0.3
	abi_x86_32? ( !app-emulation/emul-linux-x86-opengl[-abi_x86_32(-)] )
	classic? ( app-eselect/eselect-mesa )
	gallium? ( app-eselect/eselect-mesa )
	=app-eselect/eselect-opengl-1.3.3-r1
	>=dev-libs/expat-2.1.0-r3:=[${MULTILIB_USEDEP}]
	>=x11-libs/libX11-1.6.2:=[${MULTILIB_USEDEP}]
	>=x11-libs/libxshmfence-1.1:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXdamage-1.1.4-r1:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXext-1.3.2:=[${MULTILIB_USEDEP}]
	>=x11-libs/libXxf86vm-1.1.3:=[${MULTILIB_USEDEP}]
	>=x11-libs/libxcb-1.9.3:=[${MULTILIB_USEDEP}]
	x11-libs/libXfixes:=[${MULTILIB_USEDEP}]
	llvm? (
		video_cards_radeonsi? (
			virtual/libelf:0=[${MULTILIB_USEDEP}]
			vulkan? ( >=sys-devel/llvm-3.9.0:=[${MULTILIB_USEDEP}] )
		)
		video_cards_r600? (
			virtual/libelf:0=[${MULTILIB_USEDEP}]
		)
		video_cards_radeon? (
			virtual/libelf:0=[${MULTILIB_USEDEP}]
		)
		>=sys-devel/llvm-3.6.0:0=[${MULTILIB_USEDEP}]
		<sys-devel/llvm-5:=[${MULTILIB_USEDEP}]
	)
	nettle? ( dev-libs/nettle:=[${MULTILIB_USEDEP}] )
	!nettle? (
		gcrypt? ( dev-libs/libgcrypt:=[${MULTILIB_USEDEP}] )
		!gcrypt? (
			libressl? ( dev-libs/libressl:=[${MULTILIB_USEDEP}] )
			!libressl? ( dev-libs/openssl:=[${MULTILIB_USEDEP}] )
		)
	)
	opencl? (
		app-eselect/eselect-opencl
		dev-libs/libclc
		virtual/libelf:0=[${MULTILIB_USEDEP}]
	)
	openmax? ( >=media-libs/libomxil-bellagio-0.9.3:=[${MULTILIB_USEDEP}] )
	vaapi? (
		>=x11-libs/libva-1.6.0:=[${MULTILIB_USEDEP}]
		video_cards_nouveau? ( !<=x11-libs/libva-vdpau-driver-0.7.4-r3 )
	)
	vdpau? ( >=x11-libs/libvdpau-1.1:=[${MULTILIB_USEDEP}] )
	wayland? ( >=dev-libs/wayland-1.2.0:=[${MULTILIB_USEDEP}] )
	xvmc? ( >=x11-libs/libXvMC-1.0.8:=[${MULTILIB_USEDEP}] )
	${LIBDRM_DEPSTRING}[video_cards_freedreno?,video_cards_nouveau?,video_cards_vc4?,video_cards_vmware?,${MULTILIB_USEDEP}]
"

# shellcheck disable=SC2068
for card in ${INTEL_CARDS[@]}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? ( ${LIBDRM_DEPSTRING}[video_cards_intel] )
	"
done
# shellcheck disable=SC2068
for card in ${AMD_CARDS[@]}; do
	RDEPEND="${RDEPEND}
		video_cards_${card}? ( ${LIBDRM_DEPSTRING}[video_cards_radeon] )
	"
done
RDEPEND="${RDEPEND}
	video_cards_radeonsi? ( ${LIBDRM_DEPSTRING}[video_cards_amdgpu] )
"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	llvm? (
		video_cards_radeonsi? (
			|| (
				sys-devel/llvm[llvm_targets_AMDGPU]
				sys-devel/llvm[video_cards_radeon]
			)
		)
	)
	opencl? (
		>=sys-devel/llvm-3.4.2:0=[${MULTILIB_USEDEP}]
		>=sys-devel/clang-3.4.2:0=[${MULTILIB_USEDEP}]
		>=sys-devel/gcc-4.6
	)
	sys-devel/gettext
	virtual/pkgconfig
	valgrind? ( dev-util/valgrind )
	>=x11-proto/dri2proto-2.8-r1:=[${MULTILIB_USEDEP}]
	dri3? (
		>=x11-proto/dri3proto-1.0:=[${MULTILIB_USEDEP}]
		>=x11-proto/presentproto-1.0:=[${MULTILIB_USEDEP}]
	)
	>=x11-proto/glproto-1.4.17-r1:=[${MULTILIB_USEDEP}]
	>=x11-proto/xextproto-7.2.1-r1:=[${MULTILIB_USEDEP}]
	>=x11-proto/xf86driproto-2.1.1-r1:=[${MULTILIB_USEDEP}]
	>=x11-proto/xf86vidmodeproto-2.3.1-r1:=[${MULTILIB_USEDEP}]
"

[[ "${PV}" == "9999" ]] && DEPEND+="
	sys-devel/bison
	sys-devel/flex
	$(python_gen_any_dep ">=dev-python/mako-0.7.3[\${PYTHON_USEDEP}]")
"

S="${WORKDIR}/${MY_P}"

QA_WX_LOAD="
x86? (
	!pic? (
		usr/lib*/libglapi.so.0.0.0
		usr/lib*/libGLESv1_CM.so.1.1.0
		usr/lib*/libGLESv2.so.2.0.0
		usr/lib*/libGL.so.1.2.0
		usr/lib*/libOSMesa.so.8.0.0
	)
"

# driver_enable DRI_DRIVERS()
#	1>	 driver array (reference)
#	2>	 driver USE flag (main category)
#	[3-N]> driver USE flags (subcategory)
driver_enable() {
	(($# < 2)) && die "Invalid parameter count: ${#} (2)"
	local __driver_array_reference="${1}" __driver_use_flag="${2}" driver
	declare -n driver_array=${__driver_array_reference}

	if (($# == 2)); then
		driver_array+=",${__driver_use_flag}"
	elif use "${__driver_use_flag}"; then
		# shellcheck disable=SC2068
		for driver in ${@:3}; do
			driver_array+=",${driver}"
		done
	fi
}

llvm_check_depends() {
	local flags="${MULTILIB_USEDEP}"
	if use video_cards_r600 || use video_cards_radeon || use video_cards_radeonsi; then
		flags+=",llvm_targets_AMDGPU(-)"
	fi
	if use opencl; then
		has_version "sys-devel/clang[${flags}]" || return 1
	fi
	has_version "sys-devel/llvm[${flags}]"
}

pkg_setup() {
	# warning message for bug 459306
	if use llvm && has_version sys-devel/llvm[!debug=]; then
		ewarn "Mismatch between debug USE flags in media-libs/mesa and sys-devel/llvm"
		ewarn "detected! This can cause problems. For details, see bug 459306."
	fi

	python-any-r1_pkg_setup
}

src_prepare() {
	[[ "${PV}" == "9999" ]] && eautoreconf
	default
}

multilib_src_configure() {
	local myeconfargs

	if use classic; then
		# Configurable DRI drivers
		driver_enable DRI_DRIVERS swrast

		# Intel code
		driver_enable DRI_DRIVERS video_cards_i915 i915
		driver_enable DRI_DRIVERS video_cards_i965 i965
		if ! use video_cards_i915 && ! use video_cards_i965; then
			driver_enable DRI_DRIVERS video_cards_intel i915 i965
		fi

		# Nouveau code
		driver_enable DRI_DRIVERS video_cards_nouveau nouveau

		# ATI code
		driver_enable DRI_DRIVERS video_cards_r100 radeon
		driver_enable DRI_DRIVERS video_cards_r200 r200
		if ! use video_cards_r100 && ! use video_cards_r200; then
			driver_enable DRI_DRIVERS video_cards_radeon radeon r200
		fi
	fi

	if use egl; then
		myeconfargs+=( "--with-egl-platforms=x11,surfaceless$(use wayland && echo ",wayland")$(use gbm && echo ",drm")" )
	fi

	if use gallium; then
		myeconfargs+=(
			"$(use_enable d3d9 nine)"
			"$(use_enable llvm)"
			"$(use_enable openmax omx)"
			"$(use_enable vaapi va)"
			"$(use_enable vdpau)"
			"$(use_enable xa)"
			"$(use_enable xvmc)"
		)
		use vaapi && myeconfargs+=( "--with-va-libdir=/usr/$(get_libdir)/va/drivers" )

		driver_enable GALLIUM_DRIVERS swrast
		driver_enable GALLIUM_DRIVERS video_cards_vc4 vc4
		driver_enable GALLIUM_DRIVERS video_cards_vivante etnaviv
		driver_enable GALLIUM_DRIVERS video_cards_vmware svga
		driver_enable GALLIUM_DRIVERS video_cards_nouveau nouveau
		driver_enable GALLIUM_DRIVERS video_cards_i915 i915
		driver_enable GALLIUM_DRIVERS video_cards_imx imx
		if ! use video_cards_i915 && ! use video_cards_i965; then
			driver_enable GALLIUM_DRIVERS video_cards_intel i915
		fi

		driver_enable GALLIUM_DRIVERS video_cards_r300 r300
		driver_enable GALLIUM_DRIVERS video_cards_r600 r600
		driver_enable GALLIUM_DRIVERS video_cards_radeonsi radeonsi
		if ! use video_cards_r300 && ! use video_cards_r600; then
			driver_enable GALLIUM_DRIVERS video_cards_radeon r300 r600
		fi

		driver_enable GALLIUM_DRIVERS video_cards_freedreno freedreno
		# opencl stuff
		if use opencl; then
			myeconfargs+=(
				"$(use_enable opencl)"
				"--with-clang-libdir=${EPREFIX}/usr/lib"
				)
		fi
	fi

	if use vulkan; then
		driver_enable VULKAN_DRIVERS video_cards_i965 intel
		if has_version '>=sys-devel-llvm-3.9.0'; then
			driver_enable VULKAN_DRIVERS video_cards_radeonsi radeon
		fi
	fi
	# x86 hardened pax_kernel needs glx-rts, bug 240956
	if [[ "${ABI}" == "x86" ]]; then
		myeconfargs+=( "$(use_enable pax_kernel glx-read-only-text)" )
	fi

	# on abi_x86_32 hardened we need to have asm disable
	if [[ ${ABI} == x86* ]] && use pic; then
		myeconfargs+=( "--disable-asm" )
	fi

	if use gallium; then
		myeconfargs+=( "$(use_enable osmesa gallium-osmesa)" )
	else
		myeconfargs+=( "$(use_enable osmesa)" )
	fi

	# build fails with BSD indent, bug #428112
	use userland_GNU || export INDENT=cat

	myeconfargs+=(
		"--enable-dri"
		"--enable-glx"
		"--enable-shared-glapi"
		"--disable-shader-cache"
		"$(use_enable !bindist texture-float)"
		"$(use_enable d3d9 nine)"
		"$(use_enable debug)"
		"$(use_enable dri3)"
		"$(use_enable egl)"
		"$(use_enable gbm)"
		"$(use_enable gles1)"
		"$(use_enable gles2)"
		"$(use_enable nptl glx-tls)"
		"--enable-valgrind=$(usex valgrind auto no)"
		"--enable-llvm-shared-libs"
		"--with-dri-drivers=${DRI_DRIVERS}"
		"--with-gallium-drivers=${GALLIUM_DRIVERS}"
		"--with-vulkan-drivers=${VULKAN_DRIVERS}"
		"--with-sha1=$(usex nettle libnettle "$(usex gcrypt libgcrypt libcrypto)")"
		"PYTHON2=${PYTHON}"
	)
	# shellcheck disable=SC2068,SC2128
	ECONF_SOURCE="${S}" econf ${myeconfargs[@]}
}

multilib_src_install() {
	emake install DESTDIR="${D}"

	# Move lib{EGL*,GL*,OpenVG,OpenGL}.{la,a,so*} files from /usr/lib to /usr/lib/opengl/mesa/lib
	ebegin "(subshell): moving lib{EGL*,GL*,OpenGL}.{la,a,so*} in order to implement dynamic GL switching support"
	(
		local gl_dir
		gl_dir="/usr/$(get_libdir)/opengl/${OPENGL_DIR}"
		dodir "${gl_dir}/lib"
		for library in "${ED%/}/usr/$(get_libdir)"/lib{EGL*,GL*,OpenGL}.{la,a,so*} ; do
			if [[ -f ${library} || -L ${library} ]]; then
				mv -f "${library}" "${ED%/}${gl_dir}"/lib \
					|| die "Failed to move ${library}"
			fi
		done
	)
	eend $? || die "(subshell): failed to move lib{EGL*,GL*,OpenGL}.{la,a,so*}"

	if use classic || use gallium; then
		ebegin "(subshell): moving DRI/Gallium drivers for dynamic switching"
		(
			local gallium_drivers=( i915_dri.so i965_dri.so r300_dri.so r600_dri.so swrast_dri.so )
			keepdir "/usr/$(get_libdir)/dri"
			dodir "/usr/$(get_libdir)/mesa"
			# shellcheck disable=SC2068
			for library in ${gallium_drivers[@]}; do
				if [ -f "$(get_libdir)/gallium/${library}" ]; then
					mv -f "${ED%/}/usr/$(get_libdir)/dri/${library}" \
							"${ED%/}/usr/$(get_libdir)/dri/${library/_dri.so/g_dri.so}" \
						|| die "Failed to move ${library}"
				fi
			done
			if use classic; then
				emake -C "${BUILD_DIR}/src/mesa/drivers/dri" DESTDIR="${D}" install
			fi
			for library in "${ED%/}/usr/$(get_libdir)/dri"/*.so; do
				if [[ -f "${library}" || -L "${library}" ]]; then
					mv -f "${library}" "${library/dri/mesa}" \
						|| die "Failed to move ${library}"
				fi
			done
			pushd "${ED%/}/usr/$(get_libdir)/dri" || die "pushd failed"
			ln -s ../mesa/*.so . || die "Creating symlink failed"
			# remove symlinks to drivers known to eselect
			# shellcheck disable=SC2068
			for library in ${gallium_drivers[@]}; do
				if [[ -f "${library}" || -L "${library}" ]]; then
					rm "${library}" || die "Failed to remove ${library}"
				fi
			done
			popd
		)
		eend $? || die "(subshell): moving DRI/Gallium drivers failed"
	fi
	if use opencl; then
		ebegin "(subshell): moving Gallium/Clover OpenCL implementation for dynamic switching"
		(
			local cl_dir
			cl_dir="/usr/$(get_libdir)/OpenCL/vendors/mesa"
			dodir "${cl_dir}"/{lib,include}
			if [ -f "${ED%/}/usr/$(get_libdir)/libOpenCL.so" ]; then
				mv -f "${ED%/}/usr/$(get_libdir)/libOpenCL.so"* \
					"${ED%/}${cl_dir}"
			fi
			if [ -f "${ED%/}/usr/include/CL/opencl.h" ]; then
				mv -f "${ED%/}/usr/include/CL" \
					"${ED%/}${cl_dir}/include"
			fi
		)
		eend $? || die "(subshell): moving Gallium/Clover OpenCL implementation failed"
	fi

	if use openmax; then
		echo "XDG_DATA_DIRS=\"${EPREFIX}/usr/share/mesa/xdg\"" > "${T}/99mesaxdgomx"
		doenvd "${T}"/99mesaxdgomx
		keepdir /usr/share/mesa/xdg
	fi
}

multilib_src_install_all() {
	find "${ED%/}" -name '*.la' -delete
	einstalldocs

	if use !bindist; then
		dodoc "docs/patents.txt"
	fi

	# Install config file for eselect mesa
	insinto /usr/share/mesa
	newins "${FILESDIR}/eselect-mesa.conf.9.2" "eselect-mesa.conf"
	if use vulkan; then
		rm "${ED%/}/usr/include/vulkan"/{vulkan.h,vk_platform.h} || die "rm failed"
	fi

}

multilib_src_test() {
	if use llvm; then
		local llvm_tests='lp_test_arit lp_test_arit lp_test_blend lp_test_blend lp_test_conv lp_test_conv lp_test_format lp_test_format lp_test_printf lp_test_printf'
		pushd "src/gallium/drivers/llvmpipe" >/dev/null || die "pushd failed"
		# shellcheck disable=SC2086
		emake ${llvm_tests}
		# shellcheck disable=SC2086
		pax-mark m ${llvm_tests}
		popd >/dev/null || die "popd failed"
	fi
	emake check
}

pkg_postinst() {
	# Switch to the xorg implementation.
	echo
	eselect opengl set --use-old "${OPENGL_DIR}"

	# Select classic/gallium drivers
	if use classic || use gallium; then
		eselect mesa set --auto
	fi

	# Switch to mesa opencl
	if use opencl; then
		eselect opencl set --use-old "${PN}"
	fi

	# run omxregister-bellagio to make the OpenMAX drivers known system-wide
	if use openmax; then
		ebegin "(subshell): registering OpenMAX drivers"
		BELLAGIO_SEARCH_PATH="${EPREFIX}/usr/$(get_libdir)/libomxil-bellagio0" \
			OMX_BELLAGIO_REGISTRY="${EPREFIX}/usr/share/mesa/xdg/.omxregister" \
			omxregister-bellagio
		eend $? || die "(subshell): registering OpenMAX drivers failed"
	fi

	# warn about patent encumbered texture-float
	if use !bindist; then
		elog "USE=\"bindist\" was not set. Potentially patent encumbered code was"
		elog "enabled. Please see patents.txt for an explanation."
	fi

	if ! has_version "media-libs/libtxc_dxtn"; then
		elog "Note that in order to have full S3TC support, it is necessary to install"
		elog "media-libs/libtxc_dxtn as well. This may be necessary to get nice"
		elog "textures in some apps, and some others even require this to run."
	fi

	ewarn "This is an experimental version of ${CATEGORY}/${PN} designed to fix various issues"
	ewarn "when switching GL providers."
	ewarn "This package can only be used in conjuction with patched versions of:"
	ewarn " * app-select/eselect-opengl"
	ewarn " * x11-base/xorg-server"
	ewarn " * x11-drivers/nvidia-drivers"
	ewarn "from the bobwya overlay."
}

pkg_prerm() {
	if use openmax; then
		rm "${EPREFIX}/usr/share/mesa/xdg/.omxregister"
	fi
}
