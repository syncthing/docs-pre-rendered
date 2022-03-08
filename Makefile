# Hey Emacs, this is a -*- GNUmakefile -*-

# This helper is meant to be run from a developer's machine where all
# necessary tools are installed.  The most important ones are:
#   * Git
#   * Sphinx (for example via pip)
#   * latexmk
#
# The main target is rebuilding all historic versions that currently
# exist in the current directory, checking the new build into the git
# index.  Specific (existing) version directories can be specified as
# targets to limit the rebuild to only those.


SOURCE_REPO = https://github.com/syncthing/docs
SOURCE_DIR = $(TEMP_DIR)/syncthing-docs
PATCH_BRANCH = patches-for-version-picker
VERSIONS = $(wildcard v*.*.*)
TARGET_DIR := $(CURDIR)
JS_FILES = $(patsubst %,%/_static/version_redirect.js,$(VERSIONS))


TEMP_DIR := $(shell mktemp -d --tmpdir st-pre-rendered.XXXXXX)
$(warning Keeping temporary source checkout in $(SOURCE_DIR))


all: $(VERSIONS)

copy-js: $(JS_FILES)
	git add --no-all .

.PHONY: all copy-js


$(SOURCE_DIR):
	git clone -b $(PATCH_BRANCH) $(SOURCE_REPO) $@

$(VERSIONS): %: $(SOURCE_DIR) FORCE
	cd $(SOURCE_DIR) && \
		git checkout -f $@ && \
		git merge --no-commit -X theirs $(PATCH_BRANCH)
	make -C $(SOURCE_DIR) clean html man latexpdf
	rm -rf $(TARGET_DIR)/$@
	@mv -v $(SOURCE_DIR)/_build/html/ $(TARGET_DIR)/$@/
	@mv -v $(SOURCE_DIR)/_build/man/ $(TARGET_DIR)/$@/
	mkdir $(TARGET_DIR)/$@/pdf
	@mv -v $(SOURCE_DIR)/_build/latex/*.pdf $(TARGET_DIR)/$@/pdf/
	cd $(TARGET_DIR) && \
		git add --no-all $@

$(JS_FILES): %/_static/version_redirect.js: $(SOURCE_DIR) FORCE
	@cp -vf $(SOURCE_DIR)/_static/version_redirect.js $(TARGET_DIR)/$@/

FORCE:
