.PHONY: default diff patch

default:
	@echo "usage:"
	@echo "  make diff  # make the patch files from upstream and edited"
	@echo "  make patch # apply the patch files to upstream"

diff:
	diff -u cbits/tinyfiledialogs.c cbits/tinyfiledialogs-patched.c > cbits/tinyfiledialogs.c.patch; true
	diff -u cbits/tinyfiledialogs.h cbits/tinyfiledialogs-patched.h > cbits/tinyfiledialogs.h.patch; true

patch:
	patch -o cbits/tinyfiledialogs-patched.c cbits/tinyfiledialogs.c cbits/tinyfiledialogs.c.patch
	patch -o cbits/tinyfiledialogs-patched.h cbits/tinyfiledialogs.h cbits/tinyfiledialogs.h.patch
