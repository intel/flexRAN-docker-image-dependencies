ifneq ($(DEB_STAGE),rtlibs)
  arch_binaries  := $(arch_binaries) cpp-nat cpp-host
  ifeq ($(unprefixed_names),yes)
    arch_binaries  := $(arch_binaries) cpp
    indep_binaries := $(indep_binaries) cpp-build
  endif
  ifneq ($(DEB_CROSS),yes)
    ifneq ($(GFDL_INVARIANT_FREE),yes)
      indep_binaries := $(indep_binaries) cpp-doc
    endif
  endif
endif

p_cpp  = cpp$(pkg_ver)
p_cpp_n = cpp$(pkg_ver)-$(subst _,-,$(TARGET_ALIAS))
p_cpp_h = cpp$(pkg_ver)-for-host
p_cpp_d = cpp$(pkg_ver)-doc

d_cpp	= debian/$(p_cpp)
d_cpp_n = debian/$(p_cpp_n)
d_cpp_h = debian/$(p_cpp_h)
d_cpp_b = debian/$(p_cpp_b)
d_cpp_d	= debian/$(p_cpp_d)

dirs_cpp_n = \
	$(docdir) \
	$(PF)/share/man/man1 \
	$(PF)/bin \
	$(gcc_lexec_dir) \
	usr/share/lintian/overrides

dirs_cpp = \
	$(docdir) \
	$(PF)/bin \
	$(PF)/share/man/man1 \
	usr/share/lintian/overrides

files_cpp_n = \
	$(PF)/bin/$(cmd_prefix)cpp$(pkg_ver) \
	$(gcc_lexec_dir)/cc1

ifneq ($(GFDL_INVARIANT_FREE),yes)
  files_cpp_n += \
	$(PF)/share/man/man1/$(cmd_prefix)cpp$(pkg_ver).1
endif

# ----------------------------------------------------------------------
$(binary_stamp)-cpp-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cpp_n)
	dh_installdirs -p$(p_cpp_n) $(dirs_cpp_n)
	$(dh_compat2) dh_movefiles -p$(p_cpp_n) $(files_cpp_n)

	echo '$(p_cpp_n) binary: hardening-no-pie' \
	  > $(d_cpp_n)/usr/share/lintian/overrides/$(p_cpp_n)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_cpp_n) binary: binary-without-manpage' \
	  >> $(d_cpp_n)/usr/share/lintian/overrides/$(p_cpp_n)
endif

	debian/dh_doclink -p$(p_cpp_n) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_cpp_n)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) $(d_cpp_n)/$(gcc_lexec_dir)/cc1
endif
	dh_strip -p$(p_cpp_n) \
	  $(if $(unstripped_exe),-X/cc1)
	dh_shlibdeps -p$(p_cpp_n)

	echo $(p_cpp_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cpp-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_cpp_h)
	debian/dh_doclink -p$(p_cpp_h) $(p_xbase)
	echo $(p_cpp_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cpp-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_cpp_b)
	dh_installdocs -p$(p_cpp_b) debian/README.Debian
	dh_installchangelogs -p$(p_cpp_b)
	dh_compress -p$(p_cpp_b)
	dh_fixperms -p$(p_cpp_b)
	echo $(p_cpp_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-cpp: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cpp)
	dh_installdirs -p$(p_cpp) $(dirs_cpp)

	ln -sf $(cmd_prefix)cpp$(pkg_ver) \
	    $(d_cpp)/$(PF)/bin/cpp$(pkg_ver)
ifneq ($(GFDL_INVARIANT_FREE),yes)
	ln -sf $(cmd_prefix)cpp$(pkg_ver).1 \
	    $(d_cpp)/$(PF)/share/man/man1/cpp$(pkg_ver).1
else
	echo '$(p_cpp) binary: binary-without-manpage' \
	  >> $(d_cpp)/usr/share/lintian/overrides/$(p_cpp)
endif

	debian/dh_doclink -p$(p_cpp) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_cpp)

	echo $(p_cpp) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-cpp-doc: $(build_html_stamp) $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_cpp_d)
	dh_installdirs -p$(p_cpp_d) \
		$(docdir)/$(p_xbase) \
		$(PF)/share/info
	$(dh_compat2) dh_movefiles -p$(p_cpp_d) \
		$(PF)/share/info/cpp*

	debian/dh_doclink -p$(p_cpp_d) $(p_xbase)
	dh_installdocs -p$(p_cpp_d) html/cpp.html html/cppinternals.html
	rm -f $(d_cpp_d)/$(docdir)/$(p_xbase)/copyright
	debian/dh_rmemptydirs -p$(p_cpp_d)
	echo $(p_cpp_d) >> debian/indep_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
