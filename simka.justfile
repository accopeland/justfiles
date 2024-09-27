build:
	#The installation creates 4 executables (./build/bin directory):
	gcc_init
	rm -rf simka/
	git clone https://github.com/GATB/simka.git
	cd simka/
	# Prepare GATB sub-module
	git submodule init
	git submodule update
	rm -rf build
	mkdir build
	cd build
	cmake ..
	make -j4

install:
	#See the INSTALL file for more information.
	#simka: main software to be used for your analysis
	#simkaCount, simkaMerge and simkaCountProcess: not to be used directly, called by 'simka'
	#All softwares must stay in the same folder; so, if you want to move them elsewhere on your system, consider to let them altogether.
	cd simka/build/bin
	lnx

test:
	#Then, you can try the software on your computer, as follows:
	cd simka/example
	./simple_test.sh
