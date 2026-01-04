.PHONY: help build build-release clean release

help:
	@awk '/^[a-zA-Z_-]+:/ { \
		msg = match(lastLine, /^# (.*)/); \
		if (msg) { \
			cmd = substr($$1, 1, index($$1, ":") - 1); \
			printf "\033[36m%-15s\033[0m %s\n", cmd, substr(lastLine, 3); \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

GIT := git
LATEST_TAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "v2.0.0")
NEXT_VERSION := $(shell echo $(LATEST_TAG) | awk -F. -v OFS=. '{$$NF += 1;} 1')

# Build debug version
build:
	zig build

# Build release version
build-release:
	zig build -Doptimize=ReleaseSmall
	cd zig-out/bin && zip -q capslang-windows-x86_64.zip capslang.exe

# Clean build artifacts
clean:
	rm -rf .zig-cache zig-out

# Create and push a new release tag
release:
	@echo "Current version: $(LATEST_TAG)"
	@echo "Next version: $(NEXT_VERSION)"
	@read -p "Create release $(NEXT_VERSION)? [y/N] " answer; \
	if [ "$$answer" = "y" ]; then \
		$(GIT) tag -a $(NEXT_VERSION) -m "Release $(NEXT_VERSION)"; \
		$(GIT) push origin $(NEXT_VERSION); \
		echo "Release $(NEXT_VERSION) created and pushed."; \
	else \
		echo "Release cancelled."; \
	fi