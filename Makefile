.PHONY: default diff patch

default:
	@echo "usage:"
	@echo "  make diff  # make the patch files from upstream and edited"
	@echo "  make patch # apply the patch files to upstream"

diff: cbits/tinyfiledialogs.c.patch cbits/tinyfiledialogs.h.patch
patch: cbits/tinyfiledialogs.c cbits/tinyfiledialogs.h

cbits/tinyfiledialogs.c.patch:
	diff -u cbits/upstream.c cbits/tinyfiledialogs.c > cbits/tinyfiledialogs.c.patch; true

cbits/tinyfiledialogs.h.patch:
	diff -u cbits/upstream.h cbits/tinyfiledialogs.h > cbits/tinyfiledialogs.h.patch; true

cbits/tinyfiledialogs.c:
	patch -o cbits/tinyfiledialogs.c cbits/upstream.c cbits/tinyfiledialogs.c.patch

cbits/tinyfiledialogs.h:
	patch -o cbits/tinyfiledialogs.h cbits/upstream.h cbits/tinyfiledialogs.h.patch
