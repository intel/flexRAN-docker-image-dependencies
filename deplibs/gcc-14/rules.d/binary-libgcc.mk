ifeq ($(with_libgcc),yes)
  $(lib_binaries)	+= libgcc
endif
ifeq ($(with_lib64gcc),yes)
  $(lib_binaries)	+= lib64gcc
endif
ifeq ($(with_lib32gcc),yes)
  $(lib_binaries)	+= lib32gcc
endif
ifeq ($(with_libn32gcc),yes)
  $(lib_binaries)	+= libn32gcc
endif
ifeq ($(with_libx32gcc),yes)
  $(lib_binaries)	+= libx32gcc
endif

ifneq ($(DEB_STAGE),rtlibs)
  ifeq ($(with_cdev),yes)
    $(lib_binaries)  += libgcc-dev
  endif
  ifeq ($(with_lib64gccdev),yes)
    $(lib_binaries)  += lib64gcc-dev
  endif
  ifeq ($(with_lib32gccdev),yes)
    $(lib_binaries)  += lib32gcc-dev
  endif
  ifeq ($(with_libn32gccdev),yes)
    $(lib_binaries)  += libn32gcc-dev
  endif
  ifeq ($(with_libx32gccdev),yes)
    $(lib_binaries)  += libx32gcc-dev
  endif
endif

p_lgcc		= libgcc-s$(GCC_SONAME)$(cross_lib_arch)
p_lgccdbg	= libgcc-s$(GCC_SONAME)-dbg$(cross_lib_arch)
p_lgccdev	= libgcc-$(BASE_VERSION)-dev$(cross_lib_arch)
d_lgcc		= debian/$(p_lgcc)
d_lgccdbg	= debian/$(p_lgccdbg)
d_lgccdev	= debian/$(p_lgccdev)

p_l32gcc	= lib32gcc-s$(GCC_SONAME)$(cross_lib_arch)
p_l32gccdbg	= lib32gcc-s$(GCC_SONAME)-dbg$(cross_lib_arch)
p_l32gccdev	= lib32gcc-$(BASE_VERSION)-dev$(cross_lib_arch)
d_l32gcc	= debian/$(p_l32gcc)
d_l32gccdbg	= debian/$(p_l32gccdbg)
d_l32gccdev	= debian/$(p_l32gccdev)

p_l64gcc	= lib64gcc-s$(GCC_SONAME)$(cross_lib_arch)
p_l64gccdbg	= lib64gcc-s$(GCC_SONAME)-dbg$(cross_lib_arch)
p_l64gccdev	= lib64gcc-$(BASE_VERSION)-dev$(cross_lib_arch)
d_l64gcc	= debian/$(p_l64gcc)
d_l64gccdbg	= debian/$(p_l64gccdbg)
d_l64gccdev	= debian/$(p_l64gccdev)

p_ln32gcc	= libn32gcc-s$(GCC_SONAME)$(cross_lib_arch)
p_ln32gccdbg	= libn32gcc-s$(GCC_SONAME)-dbg$(cross_lib_arch)
p_ln32gccdev	= libn32gcc-$(BASE_VERSION)-dev$(cross_lib_arch)
d_ln32gcc	= debian/$(p_ln32gcc)
d_ln32gccdbg	= debian/$(p_ln32gccdbg)
d_ln32gccdev	= debian/$(p_ln32gccdev)

p_lx32gcc	= libx32gcc-s$(GCC_SONAME)$(cross_lib_arch)
p_lx32gccdbg	= libx32gcc-s$(GCC_SONAME)-dbg$(cross_lib_arch)
p_lx32gccdev	= libx32gcc-$(BASE_VERSION)-dev$(cross_lib_arch)
d_lx32gcc	= debian/$(p_lx32gcc)
d_lx32gccdbg	= debian/$(p_lx32gccdbg)
d_lx32gccdev	= debian/$(p_lx32gccdev)

# __do_gcc_devels(flavour,package,todir,fromdir)
define __do_gcc_devels
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	test -n "$(2)"
	rm -rf debian/$(2)
	dh_installdirs -p$(2) $(docdir) #TODO
	dh_installdirs -p$(2) $(3)

	$(call __do_gcc_devels2,$(1),$(2),$(3),$(4))

	debian/dh_doclink -p$(2) $(p_lbase)
	debian/dh_rmemptydirs -p$(2)

	dh_strip -p$(2)
	$(cross_shlibdeps) dh_shlibdeps -p$(2)
	$(call cross_mangle_substvars,$(2))
	echo $(2) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

# __do_gcc_devels2(flavour,package,todir,fromdir)
define __do_gcc_devels2
# stage1 builds static libgcc only
	$(if $(filter $(DEB_STAGE),stage1),,
		: # libgcc_s.so may be a linker script on some architectures
		set -e; \
		if [ -h $(4)/libgcc_s.so ]; then \
		  rm -f $(4)/libgcc_s.so; \
		  rm -f $(d)/$(3)/libgcc_s.so; \
		  ( \
		    echo '/* GNU ld script'; \
		    echo '   Use a trivial linker script instead of a symlink.  */'; \
		    echo 'GROUP ( libgcc_s.so.$(GCC_SONAME) )'; \
		  ) > $(d)/$(3)/libgcc_s.so; \
		else \
		  mv $(4)/libgcc_s.so $(d)/$(3)/libgcc_s.so; \
		fi; \
	)
	$(dh_compat2) dh_movefiles -p$(2) \
		$(3)/{libgcc*,libgcov.a,*.o} \
		$(if $(1),,$(gcc_lib_dir)/include/*.h $(gcc_lib_dir)/include/sanitizer/*.h) # Only move headers for the "main" package
	$(if $(1),, for h in ISO_Fortran_binding.h libgccjit.h libgccjit++.h; do \
	  if [ -f debian/$(2)/$(gcc_lib_dir)/include/$$h ]; then \
	    mv debian/$(2)/$(gcc_lib_dir)/include/$$h $(d)/$(gcc_lib_dir)/include/.; \
	  fi; done)

	: # libbacktrace not installed by default
	$(if $(filter yes, $(with_backtrace)),
	if [ -f $(buildlibdir)/$(1)/libbacktrace/.libs/libbacktrace.a ]; then \
	  install -m644 $(buildlibdir)/$(1)/libbacktrace/.libs/libbacktrace.a \
	      debian/$(2)/$(gcc_lib_dir)/$(1); \
	fi; \
	$(if $(1),,
	if [ -f $(buildlibdir)/libbacktrace/backtrace-supported.h ]; then \
	  install -m644 $(buildlibdir)/libbacktrace/backtrace-supported.h \
	    debian/$(2)/$(gcc_lib_dir)/include/; \
	  install -m644 $(srcdir)/libbacktrace/backtrace.h \
	    debian/$(2)/$(gcc_lib_dir)/include/; \
	fi
	))

	: # If building a flavour, add a lintian override
	$(if $(1),
		#TODO: use a file instead of a hacky echo
		# but do we want to use one override file (in the source package) per
		# flavour or not since they are essentially the same?
		mkdir -p debian/$(2)/usr/share/lintian/overrides
		echo "$(2) binary: binary-from-other-architecture" \
			>> debian/$(2)/usr/share/lintian/overrides/$(2)
	)
	$(if $(filter yes, $(with_lib$(1)gmath)),
		$(call install_gcc_lib,libgcc-math,$(GCC_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_libssp)),
		$(call install_gcc_lib,libssp,$(SSP_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_ssp)),
		mv $(4)/libssp_nonshared.a debian/$(2)/$(3)/;
	)
	$(if $(filter yes, $(with_gomp)),
		$(call install_gcc_lib,libgomp,$(GOMP_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_itm)),
		$(call install_gcc_lib,libitm,$(ITM_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_atomic)),
		$(call install_gcc_lib,libatomic,$(ATOMIC_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_asan)),
		$(call install_gcc_lib,libasan,$(ASAN_SONAME),$(1),$(2))
		mv $(4)/libasan_preinit.o debian/$(2)/$(3)/;
	)
	$(if $(1),,$(if $(filter yes, $(with_lsan)),
		$(call install_gcc_lib,liblsan,$(LSAN_SONAME),$(1),$(2))
		mv $(4)/liblsan_preinit.o debian/$(2)/$(3)/;
	))
	$(if $(1),,$(if $(filter yes, $(with_tsan)),
		$(call install_gcc_lib,libtsan,$(TSAN_SONAME),$(1),$(2))
		mv $(4)/libtsan_preinit.o debian/$(2)/$(3)/;
	))
	$(if $(filter yes, $(with_ubsan)),
		$(call install_gcc_lib,libubsan,$(UBSAN_SONAME),$(1),$(2))
	)
	$(if $(1),,$(if $(filter yes, $(with_hwasan)),
		$(call install_gcc_lib,libhwasan,$(HWASAN_SONAME),$(1),$(2))
	))
	$(if $(filter yes, $(with_vtv)),
		$(call install_gcc_lib,libvtv,$(VTV_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_cilkrts)),
		$(call install_gcc_lib,libcilkrts,$(CILKRTS_SONAME),$(1),$(2))
	)
	$(if $(filter yes, $(with_qmath)),
		$(call install_gcc_lib,libquadmath,$(QUADMATH_SONAME),$(1),$(2))
	)
endef

# do_gcc_devels(flavour)
define do_gcc_devels
	$(call __do_gcc_devels,$(1),$(p_l$(1)gccdev),$(gcc_lib_dir$(1)),$(d)/$(usr_lib$(1)))
endef


define __do_libgcc
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l) $(d_d)

	dh_installdirs -p$(p_l) \
		$(docdir)/$(p_l) \
		$(libgcc_dir$(2))

	$(if $(filter yes,$(with_shared_libgcc)),
		mv $(d)/$(usr_lib$(2))/libgcc_s.so.$(GCC_SONAME) \
			$(d_l)/$(libgcc_dir$(2))/.
	)

	$(if $(filter yes, $(with_internal_libunwind)),
		mv $(d)/$(usr_lib$(2))/libunwind.* \
			$(d_l)/$(libgcc_dir$(2))/.
	)

	debian/dh_doclink -p$(p_l) $(if $(3),$(3),$(p_lbase))
	debian/dh_rmemptydirs -p$(p_l)
	$(if $(with_dbg),
	  debian/dh_doclink -p$(p_d) $(if $(3),$(3),$(p_lbase))
	  debian/dh_rmemptydirs -p$(p_d)
	)
	$(call do_strip_lib_dbg, $(p_l), $(p_d), $(v_dbg),,)

	# see Debian #533843 for the __aeabi symbol handling; this construct is
	# just to include the symbols for dpkg versions older than 1.15.3 which
	# didn't allow bypassing the symbol blacklist
	$(if $(filter yes,$(with_shared_libgcc)),
		$(if $(findstring gcc-s1,$(p_l)), \
		ln -sf libgcc-s.symbols debian/$(p_l).symbols \
		)
		$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_l) \
			-- -v$(DEB_LIBGCC_VERSION) -a$(call mlib_to_arch,$(2)) || echo XXXXXXXXXXXXXX ERROR $(p_l)
		$(call cross_mangle_shlibs,$(p_l))
		$(if $(filter arm-linux-gnueabi%,$(DEB_TARGET_GNU_TYPE)),
			if head -1 $(d_l)/DEBIAN/symbols 2>/dev/null | grep -q '^lib'; then \
			  grep -q '^ __aeabi' $(d_l)/DEBIAN/symbols \
			    || cat debian/libgcc.symbols.aeabi \
				>> $(d_l)/DEBIAN/symbols; \
			fi
		)
	)

	$(if $(DEB_STAGE),,
	    $(ignshld)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps) dh_shlibdeps -p$(p_l) \
		$(call shlibdirs_to_search,,$(2))
	)
	$(call cross_mangle_substvars,$(p_l))

	$(if $(2),,	# only for native
		mkdir -p $(d_l)/usr/share/lintian/overrides
		echo '$(p_l): package-name-doesnt-match-sonames' \
			> $(d_l)/usr/share/lintian/overrides/$(p_l)
	)

	echo $(p_l) $(if $(with_dbg), $(p_d)) >> debian/$(lib_binaries)

	$(if $(filter yes,$(with_libcompatgcc)),
	  debian/dh_doclink -p$(subst gcc-s,gcc,$(p_l)) $(if $(3),$(3),$(p_lbase))
	  $(if $(with_dbg),
	    debian/dh_doclink -p$(subst gcc-s,gcc,$(p_d)) $(if $(3),$(3),$(p_lbase))
	  )

	  $(if $(2),,
	    mkdir -p $(subst gcc-s,gcc,$(d_l))/$(libgcc_dir$(2))
	    cp -p $(d_l)/$(libgcc_dir$(2))/libgcc_s.so.$(GCC_SONAME) \
		$(subst gcc-s,gcc,$(d_l))/lib/.
	    mkdir -p $(subst gcc-s,gcc,$(d_l))/DEBIAN
	    cp -p $(d_l)/DEBIAN/{symbols,shlibs} \
		$(subst gcc-s,gcc,$(d_l))/DEBIAN/.
	    cp -p $(d_l).substvars $(subst gcc-s,gcc,$(d_l)).substvars
	    mkdir -p $(subst gcc-s,gcc,$(d_l))/usr/share/lintian/overrides
	    ( \
	      echo '$(subst gcc-s,gcc,$(p_l)): package-name-doesnt-match-sonames'; \
	      echo '$(subst gcc-s,gcc,$(p_l)): shlibs-declares-dependency-on-other-package'; \
	      echo '$(subst gcc-s,gcc,$(p_l)): symbols-declares-dependency-on-other-package'; \
	    ) > $(subst gcc-s,gcc,$(d_l))/usr/share/lintian/overrides/$(subst gcc-s,gcc,$(p_l))
	  )

	  echo $(subst gcc-s,gcc,$(p_l) $(if $(with_dbg), $(p_d))) >> debian/$(lib_binaries).epoch
	)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

do_libgcc = $(call __do_libgcc,lib$(1)gcc-s$(GCC_SONAME),$(1),$(2))
# ----------------------------------------------------------------------

$(binary_stamp)-libgcc: $(install_dependencies)
	$(call do_libgcc,,)

$(binary_stamp)-lib64gcc: $(install_dependencies)
	$(call do_libgcc,64,)

$(binary_stamp)-lib32gcc: $(install_dependencies)
	$(call do_libgcc,32,)

$(binary_stamp)-libn32gcc: $(install_dependencies)
	$(call do_libgcc,n32,)

$(binary_stamp)-libx32gcc: $(install_dependencies)
	$(call do_libgcc,x32,)

$(binary_stamp)-libgcc-dev: $(install_dependencies)
	$(call do_gcc_devels,)

$(binary_stamp)-lib64gcc-dev: $(install_dependencies)
	$(call do_gcc_devels,64)

$(binary_stamp)-lib32gcc-dev: $(install_dependencies)
	$(call do_gcc_devels,32)

$(binary_stamp)-libn32gcc-dev: $(install_dependencies)
	$(call do_gcc_devels,n32)

$(binary_stamp)-libx32gcc-dev: $(install_dependencies)
	$(call do_gcc_devels,x32)
