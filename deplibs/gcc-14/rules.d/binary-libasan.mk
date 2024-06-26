$(lib_binaries)  += libasan
ifeq ($(with_lib64asan),yes)
  $(lib_binaries)  += lib64asan
endif
ifeq ($(with_lib32asan),yes)
  $(lib_binaries)	+= lib32asan
endif
ifeq ($(with_libn32asan),yes)
  $(lib_binaries)	+= libn32asan
endif
ifeq ($(with_libx32asan),yes)
  $(lib_binaries)	+= libx32asan
endif

define __do_asan
	dh_testdir
	dh_testroot
	mv $(install_stamp) $(install_stamp)-tmp

	rm -rf $(d_l) $(d_d)
	dh_installdirs -p$(p_l) $(usr_lib$(2))
	$(dh_compat2) dh_movefiles -p$(p_l) $(usr_lib$(2))/libasan.so.*

	debian/dh_doclink -p$(p_l) $(p_lbase)
	$(if $(with_dbg),debian/dh_doclink -p$(p_d) $(p_lbase))

	if [ -f debian/$(p_l).overrides ]; then \
		mkdir -p debian/$(p_l)/usr/share/lintian/overrides; \
		cp debian/$(p_l).overrides debian/$(p_l)/usr/share/lintian/overrides/$(p_l); \
	fi
	mkdir -p debian/$(p_l)/usr/share/lintian/overrides
	echo "$(p_l): unstripped-binary-or-object" \
	    >> debian/$(p_l)/usr/share/lintian/overrides/$(p_l)

	$(if $(2), \
	  mkdir -p debian/$(p_l)/usr/share/lintian/overrides; \
	  echo "$(p_l): symbols-file-contains-current-version-with-debian-revision" \
	    >> debian/$(p_l)/usr/share/lintian/overrides/$(p_l))

	$(if $(strip_sanitizer), $(call do_strip_lib_dbg, $(p_l), $(p_d), $(v_dbg),,))
	$(cross_makeshlibs) dh_makeshlibs $(ldconfig_arg) -p$(p_l)
	$(call cross_mangle_shlibs,$(p_l))
	$(if $(ignshld),$(ignshld),-)DIRNAME=$(subst n,,$(2)) $(cross_shlibdeps) dh_shlibdeps -p$(p_l) \
		$(call shlibdirs_to_search, \
			$(subst asan$(ASAN_SONAME),gcc-s$(GCC_SONAME),$(p_l)) \
			$(subst asan$(ASAN_SONAME),stdc++$(CXX_SONAME),$(p_l)) \
		,$(2)) \
		$(if $(filter yes, $(with_common_libs)),,-- -Ldebian/shlibs.common$(2))
	$(call cross_mangle_substvars,$(p_l))
	echo $(p_l) $(if $(with_dbg), $(p_d)) >> debian/$(lib_binaries)

	trap '' 1 2 3 15; touch $@; mv $(install_stamp)-tmp $(install_stamp)
endef

# ----------------------------------------------------------------------

do_asan = $(call __do_asan,lib$(1)asan$(ASAN_SONAME),$(1))

$(binary_stamp)-libasan: $(install_stamp)
	$(call do_asan,)

$(binary_stamp)-lib64asan: $(install_stamp)
	$(call do_asan,64)

$(binary_stamp)-lib32asan: $(install_stamp)
	$(call do_asan,32)

$(binary_stamp)-libn32asan: $(install_stamp)
	$(call do_asan,n32)

$(binary_stamp)-libx32asan: $(install_stamp)
	$(call do_asan,x32)
