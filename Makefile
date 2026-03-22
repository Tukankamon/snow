FLAGS ?=
QUIET ?=
LANG ?=

snow: app/Main.hs app/Config.hs app/Utils.hs
	$(QUIET)mkdir -p build
	$(QUIET)ghc --make app/Main.hs -iapp -outputdir build -o build/snow $(FLAGS)

debug: FLAGS = -Wall -Wextra -fprint-explicit-kinds
debug: snow

# debug because this is only used when testing
run: QUIET = @
run: debug
	@./build/snow $(LANG)

clean:
	rm -rf build dist-newstyle
