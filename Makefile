.PHONY: build build-release clean

# Build debug version
build:
	zig build

# Build release version
build-release:
	zig build -Doptimize=ReleaseSmall

# Clean build artifacts
clean:
	rm -rf zig-cache zig-out
