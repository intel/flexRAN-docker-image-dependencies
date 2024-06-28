ifeq ($(with_libgnat),yes)
  # During native builds, gnat-BV Depends:
  # * libgnat             because of the development symlink.
  # During cross builds, gnat1 is linked statically. Only the latter remains.
  $(lib_binaries) += libgnat
endif

arch_binaries := $(arch_binaries) ada-nat ada-host
ifeq ($(unprefixed_names),yes)
  arch_binaries := $(arch_binaries) ada
  indep_binaries := $(indep_binaries) ada-build
endif
ifneq ($(DEB_CROSS),yes)
  ifneq ($(GFDL_INVARIANT_FREE),yes)
    indep_binaries := $(indep_binaries) ada-doc
  endif
endif

p_gbase		= $(p_xbase)
p_glbase	= $(p_lbase)

p_gnat_n = gnat-$(GNAT_VERSION)-$(subst _,-,$(TARGET_ALIAS))
p_gnat_h = gnat-$(GNAT_VERSION)-for-host
p_gnat_b = gnat-$(GNAT_VERSION)-for-build
p_gnat	= gnat-$(GNAT_VERSION)
p_gnatsjlj= gnat-$(GNAT_VERSION)-sjlj$(cross_bin_arch)
p_lgnat	= libgnat-$(GNAT_VERSION)$(cross_lib_arch)
p_lgnat_dbg = libgnat-$(GNAT_VERSION)-dbg$(cross_lib_arch)
p_gnatd	= $(p_gnat)-doc

d_gbase	= debian/$(p_gbase)
d_gnat_n = debian/$(p_gnat_n)
d_gnat_h = debian/$(p_gnat_h)
d_gnat_b = debian/$(p_gnat_b)
d_gnat	= debian/$(p_gnat)
d_gnatsjlj	= debian/$(p_gnatsjlj)
d_lgnat	= debian/$(p_lgnat)
d_gnatd	= debian/$(p_gnatd)

GNAT_TOOLS = gnat gnatbind gnatchop gnatclean gnatkr gnatlink \
	     gnatls gnatmake gnatname gnatprep gnathtml

dirs_gnat_n = \
	$(docdir)/$(p_gbase) \
	$(PF)/bin \
	$(PF)/share/man/man1 \
	$(gcc_lib_dir)/{adalib,adainclude} \
	$(gcc_lexec_dir) \
	usr/share/lintian/overrides

dirs_gnat = \
	$(docdir)/$(p_gbase)/ada \
	$(PF)/bin \
	$(PF)/share/man/man1 \
	usr/share/lintian/overrides

files_gnat_n = \
	$(gcc_lexec_dir)/gnat1 \
	$(gcc_lib_dir)/ada_target_properties \
	$(gcc_lib_dir)/adainclude/*.ad[bs] \
	$(gcc_lib_dir)/adainclude/*.h \
	$(gcc_lib_dir)/adalib/*.ali \
	$(gcc_lib_dir)/adalib/lib*.a \
	$(foreach i,$(GNAT_TOOLS),$(PF)/bin/$(cmd_prefix)$(i)$(pkg_ver))

# Strip unreproducible -f*-prefix-map= options from installed .ali
# files until the proper solution BUILD_PATH_PREFIX_MAP is accepted.
sed_ali_strip_prefix_map := sed -i '/^A -f[a-z]+-prefix-map=/d'

$(binary_stamp)-libgnat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	: # libgnat
	rm -rf $(d_lgnat)

	dh_install -p$(p_lgnat) $(gcc_lib_dir)/adalib/libgna{t,rl}-$(GNAT_SONAME).so $(usr_lib)

	debian/dh_doclink -p$(p_lgnat) $(p_glbase)

	debian/dh_rmemptydirs -p$(p_lgnat)

	b=libgnat; \
	v=$(GNAT_VERSION); \
	for ext in preinst postinst prerm postrm; do \
	  for t in '' -dev -dbg; do \
	    if [ -f debian/$$b$$t.$$ext ]; then \
	      cp -pf debian/$$b$$t.$$ext debian/$$b$$v$$t.$$ext; \
	    fi; \
	  done; \
	done
	$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_lgnat) \
		-V '$(p_lgnat) (>= $(shell echo $(DEB_VERSION) | sed 's/-.*//'))'
	$(call cross_mangle_shlibs,$(p_lgnat))

ifneq (,$(filter $(build_type), build-native cross-build-native))
	mkdir -p $(d_lgnat)/usr/share/lintian/overrides
	echo package-name-doesnt-match-sonames > \
		$(d_lgnat)/usr/share/lintian/overrides/$(p_lgnat)
endif

# The subst Make command below could be simplified, but ensures
# consistency with libraries building non-default multilib packages.
	$(call do_strip_lib_dbg, $(p_lgnat), $(p_lgnat_dbg), $(v_dbg),,)
	$(cross_shlibdeps) dh_shlibdeps -p$(p_lgnat) \
		$(call shlibdirs_to_search, \
			$(subst gnat-$(GNAT_SONAME),gcc-s$(GCC_SONAME),$(p_lgnat)) \
			$(subst gnat-$(GNAT_SONAME),atomic$(ATOMIC_SONAME),$(p_lgnat)) \
		,) \
		$(if $(filter yes, $(with_common_libs)),,-- -Ldebian/shlibs.common)
	$(call cross_mangle_substvars,$(p_lgnat))

ifeq ($(with_dbg),yes)
	: # $(p_lgnat_dbg)
	debian/dh_doclink -p$(p_lgnat_dbg) $(p_glbase)
endif
	echo $(p_lgnat) $(if $(with_dbg), $(p_lgnat_dbg)) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-ada-nat: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	: # $(p_gnat_n)
	rm -rf $(d_gnat_n)
	dh_installdirs -p$(p_gnat_n) $(dirs_gnat_n)
	: # Upstream does not install gnathtml.
	cp src/gcc/ada/gnathtml.pl debian/tmp/$(PF)/bin/$(cmd_prefix)gnathtml$(pkg_ver)
	chmod 755 debian/tmp/$(PF)/bin/$(cmd_prefix)gnathtml$(pkg_ver)
	$(dh_compat2) dh_movefiles -p$(p_gnat_n) $(files_gnat_n)

ifeq ($(with_libgnat),yes)
  # Similar links specific to Debian. FIXME: what is their purpose?
	dh_link -p$(p_gnat_n) $(foreach lib,libgnat libgnarl,\
	  $(usr_lib)/$(lib)-$(GNAT_SONAME).so $(gcc_lib_dir)/adalib/$(lib).so)
endif
	debian/dh_doclink -p$(p_gnat_n)      $(p_gbase)
	for i in $(GNAT_TOOLS); do \
	  case "$$i" in \
	    gnat) cp -p debian/gnat.1 $(d_gnat_n)/$(PF)/share/man/man1/$(cmd_prefix)gnat$(pkg_ver).1 ;; \
	    *) ln -sf $(cmd_prefix)gnat$(pkg_ver).1 $(d_gnat_n)/$(PF)/share/man/man1/$(cmd_prefix)$$i$(pkg_ver).1; \
	  esac; \
	done

ifeq (,$(findstring nostrip,$(DEB_BUILD_OPTONS)))
	$(DWZ) \
	  $(d_gnat_n)/$(gcc_lexec_dir)/gnat1
endif
	dh_strip -p$(p_gnat_n)
	find $(d_gnat_n) -name '*.ali' | xargs $(sed_ali_strip_prefix_map)
	find $(d_gnat_n) -name '*.ali' | xargs chmod 444
	dh_shlibdeps -p$(p_gnat_n)
	( \
	  echo '$(p_gnat_n) binary: hardening-no-pie'; \
	  echo '$(p_gnat_n) binary: non-standard-file-perm' \
	) > $(d_gnat_n)/usr/share/lintian/overrides/$(p_gnat_n)
ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_gnat_n) binary: binary-without-manpage' \
	  >> $(d_gnat_n)/usr/share/lintian/overrides/$(p_gnat_n)
endif

	debian/dh_rmemptydirs -p$(p_gnat_n)

	echo $(p_gnat_n) >> debian/arch_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-ada-host: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_gnat_h)
	debian/dh_doclink -p$(p_gnat_h) $(p_xbase)
	echo $(p_gnat_h) >> debian/arch_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-ada-build: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	rm -rf $(d_gnat_b)
	debian/dh_doclink -p$(p_gnat_b) $(p_cpp_b)
	echo $(p_gnat_b) >> debian/indep_binaries
	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)

$(binary_stamp)-ada: $(install_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp
	: # $(p_gnat)
	rm -rf $(d_gnat)
	dh_installdirs -p$(p_gnat) $(dirs_gnat)

ifeq ($(with_gnatsjlj),yes)
	dh_installdirs -p$(p_gnatsjlj) $(gcc_lib_dir)
	$(dh_compat2) dh_movefiles -p$(p_gnatsjlj) $(gcc_lib_dir)/rts-sjlj/adalib $(gcc_lib_dir)/rts-sjlj/adainclude
endif

	debian/dh_doclink -p$(p_gnat)      $(p_gbase)
ifeq ($(with_gnatsjlj),yes)
	debian/dh_doclink -p$(p_gnatsjlj) $(p_gbase)
endif
	cp -p src/gcc/ada/ChangeLog $(d_gnat)/$(docdir)/$(p_gbase)/ada/.
	cp -p debian/ada/README.gnat $(d_gnat)/$(docdir)/$(p_gbase)/ada/.

ifneq (,$(filter $(build_type), build-native cross-build-native))
	: # ship the versioned prefixed names in the gnat package.
	for i in $(GNAT_TOOLS); do \
	  ln -sf $(cmd_prefix)$$i$(pkg_ver) \
	    $(d_gnat)/$(PF)/bin/$$i$(pkg_ver); \
	  ln -sf $(cmd_prefix)gnat$(pkg_ver).1.gz \
	    $(d_gnat)/$(PF)/share/man/man1/$$i$(pkg_ver).1.gz; \
	done
endif

ifeq ($(GFDL_INVARIANT_FREE),yes)
	echo '$(p_gnat) binary: binary-without-manpage' \
	  >> $(d_gnat)/usr/share/lintian/overrides/$(p_gnat)
endif

	debian/dh_rmemptydirs -p$(p_gnat)

	echo $(p_gnat) >> debian/arch_binaries

ifeq ($(with_gnatsjlj),yes)
	dh_strip -p$(p_gnatsjlj)
	find $(d_gnatsjlj) -name '*.ali' | xargs $(sed_ali_strip_prefix_map)
	find $(d_gnatsjlj) -name '*.ali' | xargs chmod 444
	dh_shlibdeps -p$(p_gnatsjlj)
	echo $(p_gnatsjlj) >> debian/arch_binaries
endif

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)


$(build_gnatdoc_stamp): $(build_stamp)
	mkdir -p html
	rm -f html/*.info
	echo -n gnat_ugn gnat_rm gnat-style | xargs -d ' ' -L 1 -P $(USE_CPUS) -I{} \
	  sh -c 'cd html && \
	    echo "generating {}-$(GNAT_VERSION).info"; \
	    makeinfo -I $(srcdir)/gcc/doc/include -I $(srcdir)/gcc/ada \
		-I $(builddir)/gcc \
		-o {}-$(GNAT_VERSION).info \
		$(srcdir)/gcc/ada/{}.texi'
	touch $@

$(binary_stamp)-ada-doc: $(build_html_stamp) $(build_gnatdoc_stamp)
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_gnatd)
	dh_installdirs -p$(p_gnatd) \
		$(PF)/share/info
	cp -p html/gnat*info* $(d_gnatd)/$(PF)/share/info/.
	dh_installdocs -p$(p_gnatd) \
	    html/gnat_ugn.html html/gnat_rm.html html/gnat-style.html
	echo $(p_gnatd) >> debian/indep_binaries

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
