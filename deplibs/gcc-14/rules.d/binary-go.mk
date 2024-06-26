ifeq ($(with_libgo),yes)
  $(lib_binaries) += libgo
endif
ifeq ($(with_godev),yes)
  $(lib_binaries) += libgo-dev
endif
ifeq ($(with_lib64go),yes)
  $(lib_binaries) += lib64go
endif
ifeq ($(with_lib64godev),yes)
  $(lib_binaries)	+= lib64go-dev
endif
ifeq ($(with_lib32go),yes)
  $(lib_binaries) += lib32go
endif
ifeq ($(with_lib32godev),yes)
  $(lib_binaries)	+= lib32go-dev
endif
ifeq ($(with_libn32go),yes)
  $(lib_binaries) += libn32go
endif
ifeq ($(with_libn32godev),yes)
  $(lib_binaries)	+= libn32go-dev
endif
ifeq ($(with_libx32go),yes)
  $(lib_binaries) += libx32go
endif
ifeq ($(with_libx32godev),yes)
  $(lib_binaries)	+= libx32go-dev
endif

ifneq ($(DEB_STAGE),rtlibs)
  arch_binaries  := $(arch_binaries) gccgo-nat gccgo-host
  ifeq ($(unprefixed_names),yes)
    arch_binaries  := $(arch_binaries) gccgo
    indep_binaries := $(indep_binaries) gccgo-build
  endif
  ifneq (,$(filter yes, $(biarch64) $(biarch32) $(biarchn32) $(biarchx32)))
    arch_binaries  := $(arch_binaries) gccgo-multi
  endif
  ifneq ($(DEB_CROSS),yes)
    ifneq ($(GFDL_INVARIANT_FREE),yes)
      indep_binaries := $(indep_binaries) go-doc
    endif
  endif
endif

p_go_n  = gccgo$(pkg_ver)-$(subst _,-,$(TARGET_ALIAS))
p_go_h  = gccgo$(pkg_ver)-for-host
p_go_b  = gccgo$(pkg_ver)-for-build
p_go	= gccgo$(pkg_ver)
p_go_m	= gccgo$(pkg_ver)-multilib$(cross_bin_arch)
p_god	= gccgo$(pkg_ver)-doc
p_golib	= libgo$(GO_SONAME)$(cross_lib_arch)

d_go_n  = debian/$(p_go_n)
d_go_h  = debian/$(p_go_h)
d_go_b  = debian/$(p_go_b)
d_go	= debian/$(p_go)
d_go_m	= debian/$(p_go_m)
d_god	= debian/$(p_god)
d_golib	= debian/$(p_golib)

dirs_go_n = \
	$(PF)/bin \
	$(gcc_lexec_dir) \
	$(gcc_lib_dir) \
	$(PF)/include \
	$(PF)/share/man/man1 \
	usr/share/lintian/overrides

dirs_go = \
	$(docdir)/$(p_xbase)/go \
	$(PF)/bin \
	$(PF)/share/man/man1 \

files_go_n = \
	$(PF)/bin/$(cmd_prefix)gccgo$(pkg_ver) \
	$(gcc_lexec_dir)/go1

ifneq (,$(filter $(build_type), build-native cross-build-native))
  files_go_n += \
	$(PF)/bin/$(cmd_prefix){go,gofmt}$(pkg_ver) \
	$(gcc_lexec_dir)/cgo \
	$(gcc_lexec_dir)/{buildid,test2json,vet} \
	$(PF)/share/man/man1/$(cmd_prefix){go,gofmt}$(pkg_ver).1
endif

ifneq ($(GFDL_INVARIANT_FREE),yes)
  files_go_n += \
	$(PF)/share/man/man1/$(cmd_prefix)gccgo$(pkg_ver).1
endif

ifeq ($(with_standalone_go),yes)

  dirs_go_n += \
	$(gcc_lib_dir)/include \
	$(PF)/share/man/man1
  dirs_go += \
	$(PF)/share/man/man1

# XXX: what about triarch mapping?
  files_go_n += \
	$(PF)/bin/$(cmd_prefix){cpp,gcc,gcov,gcov-tool}$(pkg_ver) \
	$(PF)/bin/$(cmd_prefix)gcc-{ar,ranlib,nm}$(pkg_ver) \
	$(PF)/share/man/man1/$(cmd_prefix)gcc-{ar,nm,ranlib}$(pkg_ver).1 \
	$(gcc_lexec_dir)/{cc1,collect2,lto1,lto-wrapper} \
	$(gcc_lexec_dir)/liblto_plugin.so{,.0,.0.0.0} \
	$(gcc_lib_dir)/{libgcc*,libgcov.a,*.o} \
	$(header_files) \
	$(shell test -e $(d)/$(gcc_lib_dir)/SYSCALLS.c.X \
		&& echo $(gcc_lib_dir)/SYSCALLS.c.X)

  ifeq ($(with_cc1),yes)
    files_go_n += \
	$(gcc_lib_dir)/plugin/libcc1plugin.so{,.0,.0.0.0}
  endif

  ifneq ($(GFDL_INVARIANT_FREE),yes)
    files_go_n += \
	$(PF)/share/man/man1/$(cmd_prefix){cpp,gcc,gcov,gcov-tool}$(pkg_ver).1
  endif

  ifeq ($(biarch64),yes)
    files_go_n += $(gcc_lib_dir)/$(biarch64subdir)/{libgcc*,libgcov.a,*.o}
  endif
  ifeq ($(biarch32),yes)
    files_go_n += $(gcc_lib_dir)/$(biarch32subdir)/{libgcc*,*.o}
  endif
  ifeq ($(biarchn32),yes)
    files_go_n += $(gcc_lib_dir)/$(biarchn32subdir)/{libgcc*,libgcov.a,*.o}
  endif
  ifeq ($(biarchx32),yes)
    files_go_n += $(gcc_lib_dir)/$(biarchx32subdir)/{libgcc*,libgcov.a,*.o}
  endif
endif

# ----------------------------------------------------------------------
define __do_libgo
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l) $(d_d)
	dh_installdirs -p$(p_l) $(usr_lib$(2))
	$(dh_compat2) dh_movefiles -p$(p_l) \
		$(usr_lib$(2))/libgo.so.*

	debian/dh_doclink -p$(p_l) $(p_lbase)
	$(if $(with_dbg),debian/dh_doclink -p$(p_d) $(p_lbase))

	mkdir -p debian/$(p_l)/usr/share/lintian/overrides
	echo '$(p_l) binary: unstripped-binary-or-object' \
	  >> debian/$(p_l)/usr/share/lintian/overrides/$(p_l)

	: # don't strip: https://gcc.gnu.org/ml/gcc-patches/2015-02/msg01722.html
	: # dh_strip -p$(p_l) --dbg-package=$(p_d)
	: # $(call do_strip_lib_dbg, $(p_l), $(p_d), $(v_dbg),,)
	$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_l)
	$(call cross_mangle_shlibs,$(p_l))
	$(ignshld)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps) dh_shlibdeps -p$(p_l) \
		$(call shlibdirs_to_search, \
			$(subst go$(GO_SONAME),gcc-s$(GCC_SONAME),$(p_l)) \
			$(subst go$(GO_SONAME),atomic$(ATOMIC_SONAME),$(p_l)) \
		,$(2)) \
		$(if $(filter yes, $(with_common_libs)),,-- -Ldebian/shlibs.common$(2))
	$(call cross_mangle_substvars,$(p_l))
	echo $(p_l) $(if $(with_dbg), $(p_d)) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

define install_gccgo_lib
	mv $(d)/$(usr_lib$(3))/$(1).a debian/$(4)/$(gcc_lib_dir$(3))/
	if [ -f $(d)/$(usr_lib$(3))/$(1)libbegin.a ]; then \
	  mv $(d)/$(usr_lib$(3))/$(1)libbegin.a debian/$(4)/$(gcc_lib_dir$(3))/; \
	fi
	rm -f $(d)/$(usr_lib$(3))/$(1)*.{la,so}
	dh_link -p$(4) \
	  /$(usr_lib$(3))/$(1).so.$(2) /$(gcc_lib_dir$(3))/$(1).so
endef

# __do_gccgo_libgcc(flavour,package,todir,fromdir)
define __do_gccgo_libgcc
	$(if $(findstring gccgo,$(PKGSOURCE)),
		: # libgcc_s.so may be a linker script on some architectures
		set -e; \
		if [ -h $(4)/libgcc_s.so ]; then \
		  rm -f $(4)/libgcc_s.so; \
		  dh_link -p$(2) /$(libgcc_dir$(1))/libgcc_s.so.$(GCC_SONAME) \
		    $(3)/libgcc_s.so; \
		else \
		  mv $(4)/libgcc_s.so $(d)/$(3)/libgcc_s.so; \
		  dh_link -p$(2) /$(libgcc_dir$(1))/libgcc_s.so.$(GCC_SONAME) \
		    $(3)/libgcc_s.so.$(GCC_SONAME); \
		fi; \
		$(if $(1), dh_link -p$(2) /$(3)/libgcc_s.so \
		    $(gcc_lib_dir)/libgcc_s_$(1).so;)
	)
endef

define __do_libgo_dev
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l)
	dh_installdirs -p$(p_l) \
		$(gcc_lib_dir$(2)) \
		$(usr_lib$(2))
	mv $(d)/$(usr_lib$(2))/{libgobegin,libgolibbegin}.a \
		$(d)/$(gcc_lib_dir$(2))/
	$(dh_compat2) dh_movefiles -p$(p_l) \
		$(gcc_lib_dir$(2))/{libgobegin,libgolibbegin}.a \
		$(usr_lib$(2))/go
	$(call install_gccgo_lib,libgo,$(GO_SONAME),$(2),$(p_l))

	$(if $(filter yes, $(with_standalone_go)), \
	  $(call install_gccgo_lib,libgomp,$(GOMP_SONAME),$(2),$(p_l)))
	$(call __do_gccgo_libgcc,$(2),$(p_l),$(gcc_lib_dir$(2)),$(d)/$(usr_lib$(2)))

	debian/dh_doclink -p$(p_l) $(p_lbase)
	echo $(p_l) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

do_libgo = $(call __do_libgo,lib$(1)go$(GO_SONAME),$(1))
do_libgo_dev = $(call __do_libgo_dev,lib$(1)go-$(BASE_VERSION)-dev,$(1))

# ----------------------------------------------------------------------
$(binary_stamp)-libgo: $(install_stamp)
	$(call do_libgo,)

$(binary_stamp)-lib64go: $(install_stamp)
	$(call do_libgo,64)

$(binary_stamp)-lib32go: $(install_stamp)
	$(call do_libgo,32)

$(binary_stamp)-libn32go: $(install_stamp)
	$(call do_libgo,n32)

$(binary_stamp)-libx32go: $(install_stamp)
	$(call do_libgo,x32)

$(binary_stamp)-libgo-dev: $(install_stamp)
	$(call do_libgo_dev,)

$(binary_stamp)-lib64go-dev: $(install_stamp)
	$(call do_libgo_dev,64)

$(binary_stamp)-lib32go-dev: $(install_stamp)
	$(call do_libgo_dev,32)

$(binary_stamp)-libx32go-dev: $(install_stamp)
	$(call do_libgo_dev,x32)

$(binary_stamp)-libn32go-dev: $(install_stamp)
	$(call do_libgo_dev,n32)

# ----------------------------------------------------------------------
$(binary_stamp)-gccgo-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_go_n)
	dh_installdirs -p$(p_go_n) $(dirs_go_n)

	$(dh_compat2) dh_movefiles -p$(p_go_n) $(files_go_n)

ifneq (,$(findstring gccgo,$(PKGSOURCE)))
	rm -rf $(d_go_n)/$(gcc_lib_dir)/include/cilk
	rm -rf $(d_go_n)/$(gcc_lib_dir)/include/openacc.h
endif

ifeq ($(with_standalone_go),yes)
  ifeq ($(with_gomp),yes)
	mv $(d)/$(usr_lib)/libgomp*.spec $(d_go_n)/$(gcc_lib_dir)/
  endif
  ifeq ($(with_cc1),yes)
	rm -f $(d)/$(usr_lib)/libcc1.so
	dh_link -p$(p_go_n) \
		/$(usr_lib)/libcc1.so.$(CC1_SONAME) /$(gcc_lib_dir)/libcc1.so
  endif
endif

	echo '$(p_go_n) binary: unstripped-binary-or-object' \
	  > $(d_go_n)/usr/share/lintian/overrides/$(p_go_n)
	echo '$(p_go_n) binary: hardening-no-pie' \
	  >> $(d_go_n)/usr/share/lintian/overrides/$(p_go_n)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_go_n) binary: binary-without-manpage' \
	  >> $(d_go_n)/usr/share/lintian/overrides/$(p_go_n)
endif

	debian/dh_doclink -p$(p_go_n) $(p_xbase)

	debian/dh_rmemptydirs -p$(p_go_n)

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_go_n)/$(gcc_lexec_dir)/go1
endif
	dh_strip -v -p$(p_go_n) -X/cgo -X/go$(pkg_ver) -X/gofmt$(pkg_ver) \
	  -X/buildid -X/test2json -X/vet $(if $(unstripped_exe),-X/go1)
	dh_shlibdeps -p$(p_go_n)
	echo $(p_go_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-gccgo-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_go_h)
	debian/dh_doclink -p$(p_go_h) $(p_xbase)
	echo $(p_go_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-gccgo-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_go_b)
	debian/dh_doclink -p$(p_go_b) $(p_cpp_b)
	echo $(p_go_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-gccgo: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_go)
	dh_installdirs -p$(p_go) $(dirs_go)

	ln -sf $(cmd_prefix)gccgo$(pkg_ver) \
	    $(d_go)/$(PF)/bin/gccgo$(pkg_ver)
	ln -sf $(cmd_prefix)go$(pkg_ver) \
	    $(d_go)/$(PF)/bin/go$(pkg_ver)
	ln -sf $(cmd_prefix)gofmt$(pkg_ver) \
	    $(d_go)/$(PF)/bin/gofmt$(pkg_ver)
  ifneq ($(GFDL_INVARIANT_FREE),yes)
	ln -sf $(cmd_prefix)gccgo$(pkg_ver).1.gz \
	    $(d_go)/$(PF)/share/man/man1/gccgo$(pkg_ver).1.gz
  endif
	ln -sf $(cmd_prefix)go$(pkg_ver).1.gz \
	    $(d_go)/$(PF)/share/man/man1/go$(pkg_ver).1.gz
	ln -sf $(cmd_prefix)gofmt$(pkg_ver).1.gz \
	    $(d_go)/$(PF)/share/man/man1/gofmt$(pkg_ver).1.gz

ifeq ($(with_standalone_go),yes)
	for i in gcc gcov gcov-tool gcc-ar gcc-nm gcc-ranlib; do \
	  ln -sf $(cmd_prefix)$$i$(pkg_ver) \
	    $(d_go)/$(PF)/bin/$$i$(pkg_ver); \
	done
  ifneq ($(GFDL_INVARIANT_FREE),yes)
	for i in gcc gcov gcov-tool gcc-ar gcc-nm gcc-ranlib; do \
	  ln -sf $(cmd_prefix)gcc$(pkg_ver).1.gz \
	    $(d_go)/$(PF)/share/man/man1/$$i$(pkg_ver).1.gz; \
	done
  endif
endif

ifeq ($(GFDL_INVARIANT_FREE),yes)
	mkdir -p $(d_go)/usr/share/lintian/overrides
	echo '$(p_go) binary: binary-without-manpage' \
	  > $(d_go)/usr/share/lintian/overrides/$(p_go)
endif

	debian/dh_doclink -p$(p_go) $(p_xbase)

#	cp -p $(srcdir)/gcc/go/ChangeLog \
#		$(d_go)/$(docdir)/$(p_base)/go/changelog
	debian/dh_rmemptydirs -p$(p_go)

	echo $(p_go) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-gccgo-multi: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_go_m)
	dh_installdirs -p$(p_go_m) $(docdir)

	mkdir -p $(d_go_m)/usr/share/lintian/overrides
	echo '$(p_go_m) binary: non-multi-arch-lib-dir' \
	  > $(d_go_m)/usr/share/lintian/overrides/$(p_go_m)

	debian/dh_doclink -p$(p_go_m) $(p_xbase)
	debian/dh_rmemptydirs -p$(p_go_m)
	dh_strip -p$(p_go_m)
	dh_shlibdeps -p$(p_go_m)
	echo $(p_go_m) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

# ----------------------------------------------------------------------
$(binary_stamp)-go-doc: $(build_html_stamp) $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_god)
	dh_installdirs -p$(p_god) \
		$(docdir)/$(p_xbase)/go \
		$(PF)/share/info
	$(dh_compat2) dh_movefiles -p$(p_god) \
		$(PF)/share/info/gccgo*

	debian/dh_doclink -p$(p_god) $(p_xbase)
	dh_installdocs -p$(p_god)
	rm -f $(d_god)/$(docdir)/$(p_xbase)/copyright
	cp -p html/gccgo.html $(d_god)/$(docdir)/$(p_xbase)/go/
	echo $(p_god) >> debian/indep_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
