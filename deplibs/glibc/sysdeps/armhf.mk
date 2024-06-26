# configuration options for all flavours
extra_config_options = --enable-multi-arch

# multilib flavours
ifeq (,$(filter nobiarch, $(DEB_BUILD_PROFILES)))

# build soft-float (armel) alternative library
#GLIBC_PASSES += armel
#DEB_ARCH_MULTILIB_PACKAGES += libc6-armel libc6-dev-armel
#armel_configure_target = arm-linux-gnueabi
#armel_CC = $(CC) -mfloat-abi=soft
#armel_CXX = $(CXX) -mfloat-abi=soft
#armel_crypt = yes
#armel_slibdir = /lib/arm-linux-gnueabi
#armel_libdir = /usr/lib/arm-linux-gnueabi
#
#define libc6-dev-armel_extra_pkg_install
#
#$(call generic_multilib_extra_pkg_install,libc6-dev-armel)
#
#mkdir -p debian/libc6-dev-armel/usr/include/arm-linux-gnueabihf/gnu
#cp -a debian/tmp-armel/usr/include/gnu/lib-names-soft.h \
#	debian/tmp-armel/usr/include/gnu/stubs-soft.h \
#	debian/libc6-dev-armel/usr/include/arm-linux-gnueabihf/gnu
#
#endef

endif # multilib
