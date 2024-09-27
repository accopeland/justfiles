
default:
	echo "see codon"

llvm12:
	# ouch - that's a really old llvm !
	git clone --depth 1 -b release/12.x https://github.com/llvm/llvm-project
	mkdir -p llvm-project/llvm/build
	cd llvm-project/llvm/build
	cmake .. -DCMAKE_BUILD_TYPE=Release -DLLVM_INCLUDE_TESTS=OFF -DLLVM_ENABLE_RTTI=ON -DLLVM_ENABLE_ZLIB=OFF -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_TARGETS_TO_BUILD=host
	make -j 4
	make install

build:
	# The following can generally be used to build Seq. The build process will automatically download and build several smaller dependencies.
	mkdir build
	cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release -DLLVM_DIR=$(llvm-config --cmakedir) -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
	cmake --build build --config Release

install_bin:
	/bin/bash -c "$(curl -fsSL https://seq-lang.org/install.sh)"

build_codon_plugin:
	# seq plugin for codon
	git clone https://github.com/exaloop/seq.git
	cmake -S . -B build -G Ninja -DLLVM_DIR=/Users/copeland/.codon/include/codon/cir/llvm/llvm.h -DCODON_PATH=/Users/copeland/.codon -DCMAKE_BUILD_TYPE=Release
	cmake --install build --prefix /Users/copeland/.codon/lib/codon/plugins/seq
