## GNU makefile for this package.
##
## See Makefile.core for usage guidelines.
##

include Makefile.core

##

br2_external_tree_sample_dbn := $(strip \
	buildroot-ext-my-team \
)
br2_external_tree_sample_source_dir := $(strip \
	tests/trip-test/$(br2_external_tree_sample_dbn) \
)
br2_external_tree_sample_staging_dir := $(strip \
	$(distribution_staging_dir)/share/samples/$(br2_external_tree_sample_dbn) \
)
br2_external_tree_sample_source_candidate_file_finder := $(strip \
	git ls-files "$(br2_external_tree_sample_source_dir)" \
)
br2_external_tree_sample_source_candidates_computed_once := $(strip \
	$(shell $(br2_external_tree_sample_source_candidate_file_finder)) \
)

##

stage :: $(br2_external_tree_sample_staging_dir)/.ts.completed

$(br2_external_tree_sample_staging_dir)/.ts.completed : $(distribution_staging_dir)/.ts.completed
$(br2_external_tree_sample_staging_dir)/.ts.completed : $(br2_external_tree_sample_source_candidates_computed_once) $(force)
	@umask $(distribution_staging_dir_umask) && \
	mkdir -p "$(dir $@)"
	:
	rm -rf "$(dir $@)"
	:
	umask $(distribution_staging_dir_umask) && \
	(cd "$(br2_external_tree_sample_source_dir)" && git ls-files . | \
	 cpio -pdmuv "$(CURDIR)/$(patsubst %/,%,$(dir $@))")
	@touch "$@"

## EOF
