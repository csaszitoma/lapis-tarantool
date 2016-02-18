test:
	busted

lint: build
	moonc -l lapis

local: build
	luarocks make --local lapis-tarantool-dev-1.rockspec

build:
	moonc lapis
