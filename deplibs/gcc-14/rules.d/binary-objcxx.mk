ifneq ($(DEB_STAGE),rtlibs)
  ifneq (,$(filter yes, $(biarch64) $(biarch32) $(biarchn32) $(biarchx32)))
    arch_binaries  := $(arch_binaries) objcxx-multi
  endif
  arch_binaries := $(arch_binaries) objcxx-nat objcxx-host
  ifeq ($(unprefixed_names),yes)
    arch_binaries := $(arch_binaries) objcxx
    indep_binaries := $(indep_binaries) objcxx-build
  endif
endif

p_objcx_n	= gobjc++$(pkg_ver)-$(subst _,-,$(TARGET_ALIAS))
d_objcx_n	= debian/$(p_objcx_n)

p_objcx_h	= gobjc++$(pkg_ver)-for-host
d_objcx_h	= debian/$(p_objcx_h)

p_objcx_b	= gobjc++$(pkg_ver)-for-build
d_objcx_b	= debian/$(p_objcx_b)

p_objcx		= gobjc++$(pkg_ver)
d_objcx		= debian/$(p_objcx)

p_objcx_m	= gobjc++$(pkg_ver)-multilib$(cross_bin_arch)
d_objcx_m	= debian/$(p_objcx_m)

dirs_objcx_n = \
	$(gcc_lexec_dir) \
	usr/share/lintian/overrides

dirs_objcx = \
	$(docdir)/$(p_xbase)/Obj-C++ \

files_objcx_n = \
	$(gcc_lexec_dir)/cc1objplus

$(binary_stamp)-objcxx-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_objcx_n)
	dh_installdirs -p$(p_objcx_n) $(dirs_objcx_n)
	$(dh_compat2) dh_movefiles -p$(p_objcx_n) $(files_objcx_n)

	debian/dh_doclink -p$(p_objcx_n) $(p_xbase)

	echo '$(p_objcx_n) binary: hardening-no-pie' \
	  > $(d_objcx_n)/usr/share/lintian/overrides/$(p_objcx_n)

	debian/dh_rmemptydirs -p$(p_objcx_n)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_objcx_n)/$(gcc_lexec_dir)/cc1objplus
endif
	dh_strip -p$(p_objcx_n) \
	  $(if $(unstripped_exe),-X/cc1objplus)
	dh_shlibdeps -p$(p_objcx_n)
	echo $(p_objcx_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objcxx-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_objcx_h)
	debian/dh_doclink -p$(p_objcx_h) $(p_xbase)
	echo $(p_objcx_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objcxx-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_objcx_b)
	debian/dh_doclink -p$(p_objcx_b) $(p_cpp_b)
	echo $(p_objcx_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objcxx: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_objcx)
	dh_installdirs -p$(p_objcx) $(dirs_objcx)

	debian/dh_doclink -p$(p_objcx) $(p_xbase)
	cp -p $(srcdir)/gcc/objcp/ChangeLog \
		$(d_objcx)/$(docdir)/$(p_xbase)/Obj-C++/changelog

	debian/dh_rmemptydirs -p$(p_objcx)

	echo $(p_objcx) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objcxx-multi: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_objcx_m)
	debian/dh_doclink -p$(p_objcx_m) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_objcx_m)
	dh_strip -p$(p_objcx_m)
	dh_shlibdeps -p$(p_objcx_m)
	echo $(p_objcx_m) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
