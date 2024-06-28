ifneq ($(DEB_STAGE),rtlibs)
  ifneq (,$(filter yes, $(biarch64) $(biarch32) $(biarchn32) $(biarchx32)))
    arch_binaries  := $(arch_binaries) cxx-multi
  endif
  arch_binaries  := $(arch_binaries) cxx-nat cxx-host
  ifeq ($(unprefixed_names),yes)
    arch_binaries  := $(arch_binaries) cxx
    indep_binaries := $(indep_binaries) cxx-build
  endif
endif

p_cxx = g++$(pkg_ver)
p_cxx_n = g++$(pkg_ver)-$(subst _,-,$(TARGET_ALIAS))
p_cxx_h = g++$(pkg_ver)-for-host
p_cxx_b = g++$(pkg_ver)-for-build

d_cxx = debian/$(p_cxx)
d_cxx_n = debian/$(p_cxx_n)
d_cxx_h = debian/$(p_cxx_h)
d_cxx_b = debian/$(p_cxx_b)

dirs_cxx_n = \
	$(PF)/bin \
	$(gcc_lexec_dir) \
	$(PF)/share/man/man1 \
	usr/share/lintian/overrides

dirs_cxx = \
	$(docdir)/$(p_xbase)/C++ \
	$(PF)/bin \
	$(PF)/share/info \
	$(PF)/share/man/man1 \
	usr/share/lintian/overrides

files_cxx_n = \
	$(PF)/bin/$(cmd_prefix)g++$(pkg_ver) \
	$(gcc_lexec_dir)/cc1plus \
	$(gcc_lexec_dir)/g++-mapper-server

ifneq ($(GFDL_INVARIANT_FREE),yes)
  files_cxx_n += \
	$(PF)/share/man/man1/$(cmd_prefix)g++$(pkg_ver).1
endif

p_cxx_m	= g++$(pkg_ver)-multilib$(cross_bin_arch)
d_cxx_m	= debian/$(p_cxx_m)

# ----------------------------------------------------------------------
$(binary_stamp)-cxx-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cxx_n)
	dh_installdirs -p$(p_cxx_n) $(dirs_cxx_n)
	$(dh_compat2) dh_movefiles -p$(p_cxx_n) $(files_cxx_n)

	echo '$(p_cxx_n) binary: hardening-no-pie' \
	  > $(d_cxx_n)/usr/share/lintian/overrides/$(p_cxx_n)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_cxx_n) binary: binary-without-manpage' \
	  >> $(d_cxx_n)/usr/share/lintian/overrides/$(p_cxx_n)
endif

	debian/dh_doclink -p$(p_cxx_n) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_cxx_n)

	dh_shlibdeps -p$(p_cxx_n)
ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_cxx_n)/$(gcc_lexec_dir)/cc1plus
endif
	dh_strip -p$(p_cxx_n) $(if $(unstripped_exe),-X/cc1plus)
	echo $(p_cxx_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cxx-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_cxx_h)
	debian/dh_doclink -p$(p_cxx_h) $(p_xbase)
	echo $(p_cxx_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cxx-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_cxx_b)
	debian/dh_doclink -p$(p_cxx_b) $(p_cpp_b)
	echo $(p_cxx_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cxx: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cxx)
	dh_installdirs -p$(p_cxx) $(dirs_cxx)

	ln -sf $(cmd_prefix)g++$(pkg_ver) \
	    $(d_cxx)/$(PF)/bin/g++$(pkg_ver)
ifneq ($(GFDL_INVARIANT_FREE),yes)
	ln -sf $(cmd_prefix)g++$(pkg_ver).1.gz \
	    $(d_cxx)/$(PF)/share/man/man1/g++$(pkg_ver).1.gz
endif

ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_cxx) binary: binary-without-manpage' \
	  >> $(d_cxx)/usr/share/lintian/overrides/$(p_cxx)
endif

	debian/dh_doclink -p$(p_cxx) $(p_xbase)
	cp -p debian/README.C++ $(d_cxx)/$(docdir)/$(p_xbase)/C++/
	cp -p $(srcdir)/gcc/cp/ChangeLog \
		$(d_cxx)/$(docdir)/$(p_xbase)/C++/changelog
	debian/dh_rmemptydirs -p$(p_cxx)

	echo $(p_cxx) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cxx-multi: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cxx_m)
	dh_installdirs -p$(p_cxx_m) \
		$(docdir)

	debian/dh_doclink -p$(p_cxx_m) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_cxx_m)

	dh_strip -p$(p_cxx_m)
	dh_shlibdeps -p$(p_cxx_m)
	echo $(p_cxx_m) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
