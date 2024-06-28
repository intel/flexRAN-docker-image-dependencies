ifeq ($(with_libgfortran),yes)
  $(lib_binaries) += libgfortran
endif
ifeq ($(with_fdev),yes)
  $(lib_binaries) += libgfortran-dev
endif
ifeq ($(with_lib64gfortran),yes)
  $(lib_binaries) += lib64fortran
endif
ifeq ($(with_lib64gfortrandev),yes)
  $(lib_binaries) += lib64gfortran-dev
endif
ifeq ($(with_lib32gfortran),yes)
  $(lib_binaries) += lib32fortran
endif
ifeq ($(with_lib32gfortrandev),yes)
  $(lib_binaries) += lib32gfortran-dev
endif
ifeq ($(with_libn32gfortran),yes)
  $(lib_binaries) += libn32fortran
endif
ifeq ($(with_libn32gfortrandev),yes)
  $(lib_binaries) += libn32gfortran-dev
endif
ifeq ($(with_libx32gfortran),yes)
  $(lib_binaries) += libx32fortran
endif
ifeq ($(with_libx32gfortrandev),yes)
  $(lib_binaries) += libx32gfortran-dev
endif

ifeq ($(with_fdev),yes)
  ifneq (,$(filter yes, $(biarch64) $(biarch32) $(biarchn32) $(biarchx32)))
    arch_binaries  := $(arch_binaries) fdev-multi
  endif
  arch_binaries  := $(arch_binaries) fdev-nat fdev-host
  ifeq ($(unprefixed_names),yes)
    arch_binaries  := $(arch_binaries) fdev
    indep_binaries := $(indep_binaries) fdev-build
  endif
  ifneq ($(DEB_CROSS),yes)
    ifneq ($(GFDL_INVARIANT_FREE),yes)
      indep_binaries := $(indep_binaries) fortran-doc
    endif
  endif
endif

p_g95_n = gfortran$(pkg_ver)-$(subst _,-,$(TARGET_ALIAS))
p_g95_h = gfortran$(pkg_ver)-for-host
p_g95_b = gfortran$(pkg_ver)-for-build
p_g95	= gfortran$(pkg_ver)
p_g95_m	= gfortran$(pkg_ver)-multilib$(cross_bin_arch)
p_g95d	= gfortran$(pkg_ver)-doc
p_flib	= libgfortran$(FORTRAN_SONAME)$(cross_lib_arch)

d_g95_n = debian/$(p_g95_n)
d_g95_h = debian/$(p_g95_h)
d_g95_b = debian/$(p_g95_b)
d_g95	= debian/$(p_g95)
d_g95_m	= debian/$(p_g95_m)
d_g95d	= debian/$(p_g95d)

dirs_g95_n = \
	$(PF)/bin \
	$(gcc_lexec_dir) \
	$(gcc_lib_dir) \
	$(PF)/include \
	$(PF)/share/man/man1 \
	usr/share/lintian/overrides

dirs_g95 = \
	$(docdir)/$(p_xbase)/fortran \
	$(PF)/bin \
	$(PF)/share/man/man1

files_g95_n = \
	$(PF)/bin/$(cmd_prefix)gfortran$(pkg_ver) \
	$(gcc_lib_dir)/finclude \
	$(gcc_lexec_dir)/f951 

ifneq ($(GFDL_INVARIANT_FREE),yes)
  files_g95_n += \
	$(PF)/share/man/man1/$(cmd_prefix)gfortran$(pkg_ver).1
endif

# ----------------------------------------------------------------------
define __do_fortran
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l) $(d_d)
	dh_installdirs -p$(p_l) $(usr_lib$(2))
	$(dh_compat2) dh_movefiles -p$(p_l) $(usr_lib$(2))/libgfortran.so.*

	debian/dh_doclink -p$(p_l) $(p_lbase)
	$(if $(with_dbg),debian/dh_doclink -p$(p_d) $(p_lbase))

	if [ -f debian/$(p_l).overrides ]; then \
		mkdir -p debian/$(p_l)/usr/share/lintian/overrides; \
		cp debian/$(p_l).overrides debian/$(p_l)/usr/share/lintian/overrides/$(p_l); \
	fi

	$(call do_strip_lib_dbg, $(p_l), $(p_d), $(v_dbg),,)
	ln -sf libgfortran.symbols debian/$(p_l).symbols
	$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_l)
	$(call cross_mangle_shlibs,$(p_l))
	$(ignshld)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps) dh_shlibdeps -p$(p_l) \
		$(call shlibdirs_to_search, \
			$(subst gfortran$(FORTRAN_SONAME),gcc-s$(GCC_SONAME),$(p_l)) \
			$(subst gfortran$(FORTRAN_SONAME),gcc$(QUADMATH_SONAME),$(p_l)) \
		,$(2)) \
		$(if $(filter yes, $(with_common_libs)),,-- -Ldebian/shlibs.common$(2))
	$(call cross_mangle_substvars,$(p_l))
	echo $(p_l) $(if $(with_dbg), $(p_d)) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

do_fortran = $(call __do_fortran,lib$(1)gfortran$(FORTRAN_SONAME),$(1))


define __do_libgfortran_dev
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l)
	dh_installdirs -p$(p_l) $(gcc_lib_dir$(2))

	$(dh_compat2) dh_movefiles -p$(p_l) \
		$(gcc_lib_dir$(2))/libcaf_single.a
	$(call install_gcc_lib,libgfortran,$(FORTRAN_SONAME),$(2),$(p_l))

	$(if $(2),, \
	  $(dh_compat2) dh_movefiles -p$(p_l) \
		$(gcc_lib_dir$(2))/include/ISO_Fortran_binding.h)

	debian/dh_doclink -p$(p_l) $(p_lbase)
	debian/dh_rmemptydirs -p$(p_l)

	dh_strip -p$(p_l)
	$(cross_shlibdeps) dh_shlibdeps -p$(p_l)
	$(call cross_mangle_substvars,$(p_l))
	echo $(p_l) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef
# ----------------------------------------------------------------------

do_libgfortran_dev = $(call __do_libgfortran_dev,lib$(1)gfortran-$(BASE_VERSION)-dev,$(1))

$(binary_stamp)-libgfortran: $(install_stamp)
	$(call do_fortran,)

$(binary_stamp)-lib64fortran: $(install_stamp)
	$(call do_fortran,64)

$(binary_stamp)-lib32fortran: $(install_stamp)
	$(call do_fortran,32)

$(binary_stamp)-libn32fortran: $(install_stamp)
	$(call do_fortran,n32)

$(binary_stamp)-libx32fortran: $(install_stamp)
	$(call do_fortran,x32)

# ----------------------------------------------------------------------
$(binary_stamp)-fdev-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_g95_n)
	dh_installdirs -p$(p_g95_n) $(dirs_g95_n)

	$(dh_compat2) dh_movefiles -p$(p_g95_n) $(files_g95_n)

	mv $(d)/$(usr_lib)/libgfortran.spec $(d_g95_n)/$(gcc_lib_dir)/

	( \
	  echo '$(p_g95_n) binary: hardening-no-pie'; \
	  echo '$(p_g95_n) binary: missing-prerequisite-for-gfortran-module'; \
	) \
	  > $(d_g95_n)/usr/share/lintian/overrides/$(p_g95_n)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_g95_n) binary: binary-without-manpage' \
	  >> $(d_g95_n)/usr/share/lintian/overrides/$(p_g95_n)
endif

	debian/dh_doclink -p$(p_g95_n) $(p_xbase)

	debian/dh_rmemptydirs -p$(p_g95_n)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_g95_n)/$(gcc_lexec_dir)/f951
endif
	dh_strip -p$(p_g95_n) \
	  $(if $(unstripped_exe),-X/f951)
	dh_shlibdeps -p$(p_g95_n)

	echo $(p_g95_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-fdev-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_g95_h)
	debian/dh_doclink -p$(p_g95_h) $(p_xbase)
	echo $(p_g95_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-fdev-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_g95_b)
	debian/dh_doclink -p$(p_g95_b) $(p_cpp_b)
	echo $(p_g95_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-fdev: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_g95)
	dh_installdirs -p$(p_g95) $(dirs_g95)

	ln -sf $(cmd_prefix)gfortran$(pkg_ver) \
	    $(d_g95)/$(PF)/bin/gfortran$(pkg_ver)
ifneq ($(GFDL_INVARIANT_FREE),yes)
	ln -sf $(cmd_prefix)gfortran$(pkg_ver).1 \
	    $(d_g95)/$(PF)/share/man/man1/gfortran$(pkg_ver).1
endif

ifeq ($(GFDL_INVARIANT_FREE),yes)
	mkdir -p $(d_g95)/usr/share/lintian/overrides
	echo '$(p_g95) binary: binary-without-manpage' \
	  > $(d_g95)/usr/share/lintian/overrides/$(p_g95)
endif

	debian/dh_doclink -p$(p_g95) $(p_xbase)

	cp -p $(srcdir)/gcc/fortran/ChangeLog \
		$(d_g95)/$(docdir)/$(p_xbase)/fortran/changelog
	debian/dh_rmemptydirs -p$(p_g95)

	echo $(p_g95) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-fdev-multi: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_g95_m)
	dh_installdirs -p$(p_g95_m) $(docdir)

	debian/dh_doclink -p$(p_g95_m) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_g95_m)
	dh_strip -p$(p_g95_m)
	dh_shlibdeps -p$(p_g95_m)
	echo $(p_g95_m) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-fortran-doc: $(build_html_stamp) $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_g95d)
	dh_installdirs -p$(p_g95d) \
		$(docdir)/$(p_xbase)/fortran \
		$(PF)/share/info
	$(dh_compat2) dh_movefiles -p$(p_g95d) \
		$(PF)/share/info/gfortran*

	debian/dh_doclink -p$(p_g95d) $(p_xbase)
ifneq ($(GFDL_INVARIANT_FREE),yes)
	dh_installdocs -p$(p_g95d)
	rm -f $(d_g95d)/$(docdir)/$(p_xbase)/copyright
	cp -p html/gfortran.html $(d_g95d)/$(docdir)/$(p_xbase)/fortran/
endif
	echo $(p_g95d) >> debian/indep_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-libgfortran-dev: $(install_stamp)
	$(call do_libgfortran_dev,)

$(binary_stamp)-lib64gfortran-dev: $(install_stamp)
	$(call do_libgfortran_dev,64)

$(binary_stamp)-lib32gfortran-dev: $(install_stamp)
	$(call do_libgfortran_dev,32)

$(binary_stamp)-libn32gfortran-dev: $(install_stamp)
	$(call do_libgfortran_dev,n32)

$(binary_stamp)-libx32gfortran-dev: $(install_stamp)
	$(call do_libgfortran_dev,x32)
