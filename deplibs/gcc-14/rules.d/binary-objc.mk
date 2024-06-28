ifneq ($(DEB_STAGE),rtlibs)
  ifneq (,$(filter yes, $(biarch64) $(biarch32) $(biarchn32) $(biarchx32)))
    arch_binaries  := $(arch_binaries) objc-multi
  endif
  arch_binaries := $(arch_binaries) objc-nat objc-host
  ifeq ($(unprefixed_names),yes)
    arch_binaries := $(arch_binaries) objc
    indep_binaries := $(indep_binaries) objc-build
  endif
endif

p_objc_n = gobjc$(pkg_ver)-$(subst _,-,$(TARGET_ALIAS))
d_objc_n = debian/$(p_objc_n)

p_objc_h = gobjc$(pkg_ver)-for-host
d_objc_h = debian/$(p_objc_h)

p_objc_b = gobjc$(pkg_ver)-for-build
d_objc_b = debian/$(p_objc_b)

p_objc	= gobjc$(pkg_ver)
d_objc	= debian/$(p_objc)

p_objc_m= gobjc$(pkg_ver)-multilib$(cross_bin_arch)
d_objc_m= debian/$(p_objc_m)

dirs_objc_n = \
	$(gcc_lexec_dir) \
	usr/share/lintian/overrides

dirs_objc = \
	$(docdir)/$(p_xbase)/ObjC

files_objc_n = \
	$(gcc_lexec_dir)/cc1obj

$(binary_stamp)-objc-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_objc_n)
	dh_installdirs -p$(p_objc_n) $(dirs_objc_n)
	$(dh_compat2) dh_movefiles -p$(p_objc_n) $(files_objc_n)

	echo '$(p_objc_n) binary: hardening-no-pie' \
	  > $(d_objc_n)/usr/share/lintian/overrides/$(p_objc_n)

	debian/dh_doclink -p$(p_objc_n) $(p_xbase)

	debian/dh_rmemptydirs -p$(p_objc_n)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_objc_n)/$(gcc_lexec_dir)/cc1obj
endif
	dh_strip -p$(p_objc_n) \
	  $(if $(unstripped_exe),-X/cc1obj)
	dh_shlibdeps -p$(p_objc_n)
	echo $(p_objc_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objc-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_objc_h)
	debian/dh_doclink -p$(p_objc_h) $(p_xbase)
	echo $(p_objc_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objc-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_objc_b)
	debian/dh_doclink -p$(p_objc_b) $(p_cpp_b)
	echo $(p_objc_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objc: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_objc)
	dh_installdirs -p$(p_objc) $(dirs_objc)

	cp -p $(srcdir)/libobjc/{README*,THREADS*} \
		$(d_objc)/$(docdir)/$(p_xbase)/ObjC/.

	cp -p $(srcdir)/libobjc/ChangeLog \
		$(d_objc)/$(docdir)/$(p_xbase)/ObjC/changelog.libobjc

	debian/dh_doclink -p$(p_objc) $(p_xbase)

	debian/dh_rmemptydirs -p$(p_objc)

	echo $(p_objc) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-objc-multi: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_objc_m)
	dh_installdirs -p$(p_objc_m) $(docdir)

	debian/dh_doclink -p$(p_objc_m) $(p_xbase)

	dh_strip -p$(p_objc_m)
	dh_shlibdeps -p$(p_objc_m)
	echo $(p_objc_m) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
