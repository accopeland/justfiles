bigfq := "NovaSeqX-TSPF-NA24695-Rep3_S18_L001_R12_001.fastq.gz"
t1fqgz := "/Users/copeland/Repos/JGI/USA/reseq/reseq_wdl_test/507811_1327144.sub.001.fastq.gz"
t1outfq := "/Users/copeland/Repos/JGI/USA/reseq/reseq_wdl_test/507811_1327144.sub.001.fastq.gz.sfq"
in1fq := "in1.fastq"
in2fq := "in2.fastq"
infq := "in.fastq"
outfq := "out.fastq"

sam := "test.sam"
ref_fa := "ref.fa"
mgrec_al := "aligned.mgrec"

mgb_ua := "unaligned.mgb"
mgrec_ua := "unaligned.mgrec"
mgb_ga := "global_assembly.mgb"
mgrec_ga := "global_assembly.mgrec"
mgb_ll :=  "low_latency.mgb"
mgrec_ll :=  "low_latency.mgrec"
mgb_la :=  "local_assembly.mgb"
mgrec_la := "local_assembly.mgrec"
mgb_rb :=  "reference_based.mgb"
mgrec_rb := "reference_based.mgrec"


default:
	@just --list

# kmer counter
build_fastk:
  git clone https://github.com/thegenemyers/FASTK.git
	cd FASTK
	make

test_fastk:
  FastK -v -T4 -k33 {{infq}}
	Histex -v -A {{t}}

build dsrc:
	git clone ...
test dscrc:
	dsrc ...

# MPEG-G genie build https://raw.githubusercontent.com/MueFab/genie/main/util/get_genie.sh
build_genie:
	gcc_init
	#git clone https://github.com/MueFab/genie.git
	#cd genie
	#mkdir build
	#cd build
	#cmake ..
	#make
	# edit CMakeLists.txt to add -fopenmp support for Apple
	mkdir genie_buildspace
	cd genie_buildspace
	wget https://raw.githubusercontent.com/MueFab/genie/main/util/get_genie.sh
	bash ./get_genie.sh

# genie test
test_genie:
	# transcode unaligned
	genie transcode-fastq -i {{in1fq}} --input-suppl-file {{in2fq}} -o {{mgrec_ua}} -t 8
	# transcode aligned
	# genie transcode-sam -c -i {{sam}} -r {{ref_fa}} -o {{mgrec_al}}

	# compress: Unaligned data -> Global Assembly Encoding
	genie run -i {{mgrec_ua}} -o {{mgb_ga}} -t 8
	# compress: Unaligned data -> Low Latency Encoding
	genie run -i {{mgrec_ua}} -o {{mgb_ll}} --low-latency -t 8
	# compress: Aligned data w/out reference -> Local Assembly Encoding
	#genie run -i {{mgrec_la}} -o {{mgb_la}}
	# compress: Aligned data w reference -> Reference Based Encoding
	#genie run -i {{mgrec_rb}} -o {{mgb_rb}} -r {{ref_fa}}

	# decompress
	genie run -i {{mgb_ga}}  -o {{mgrec_ga}}  -t 8
	genie run -i {{mgb_ll}} -o {{mgrec_ll}} -t 8
	genie run -i {{mgb_la}} -o {{mgrec_la}} -t 8
	genie run -i {{mgb_rb}} -o {{mgrec_rb}} -r {{ref_fa}} -t 8

	# retranscoding
	genie transcode-fastq -i {{mgrec_ga}} -o {{in1fq}} --output-suppl-file {{in2fq}} -t 8
	genie transcode-fastq -i {{mgrec_ll}}  -o {{in1fq}} --output-suppl-file {{in2fq}} -t 8

# sprint build (version from 2019-Sep-12, https://github.com/shubhamchandak94/Spring):
build_spring:
	gcc_init
	git clone  https://github.com/shubhamchandak94/Spring
	cd Spring/
	mkd build
	cmake ..
	make

# spring test
test_spring:
	#SE, compression of DNA stream:
	spring -c --no-ids --no-quality -i {{infq}} -o comp.spring -t 12 -r
	#SE ORD, compression of DNA stream:
	spring -c --no-ids --no-quality -i {{infq}} -o comp.spring -t 12
	#PE, compression of DNA stream:
	spring -c --no-ids --no-quality -i {{in1fq}} {{in2fq}} -o comp.spring -t 12 -r
	#PE ORD, compression of DNA stream:
	spring -c --no-ids --no-quality -i {{in1fq}} {{in2fq}} -o comp.spring -t 12
	mytime spring -g -c -w /tmp -i {{bigfq}} -o {{outfq}}

# CURC build - need nvcc + GPU https://github.com/BioinfoSZU/CURC.git
build_curc:
	git clone https://github.com/BioinfoSZU/CURC.git
	cd CURC
	mkdir build
	cd build
	export CC=<gcc_path>  # eg export CC=/usr/bin/gcc-7
	export CXX=<g++_path> # eg export CXX=/usr/bin/g++-7
	# disable GPU check: -DCURC_DISABLE_ARCH_CHECK=ON
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_COMPILER=<nvcc_path> ..
	make

# CURC test ; need GPU
test_curc:
	# GPU initialization. To avoid the impact of slow GPU initialization
	# nvidia-smi -l 10 &
	# or enable persistence mode using
	# nvidia-smi -i <target gpu> -pm ENABLED.
	#If there are multiple GPUs and some devices are occupied, you can use CUDA_VISIBLE_DEVICES to make only those idle devices visible to CURC. For example:
	# CUDA_VISIBLE_DEVICES=2 ./curc <args>      # specify gpu device 2 that CURC uses
	#
	# To compress PE FASTQ in non-order preserving mode with two equal-size blocks.compressed output is paired_end_archive.curc
	curc -c -i in_1.fastq,in_2.fastq --block_ratio 0.5 -o paired_end_archive
	# To compress PE FASTQ in order     preserving mode with two equal-size blocks. compressed output is paired_end_archive.curc
	curc -c -i in_1.fastq,in_2.fastq --block_ratio 0.5 --preserve_order -o paired_end_archive
	# decompress PE
	curc -d -i paired_end_archive.curc -o out   # decompressed output is out_1.seq and out_2.seq

# build mstcom https://github.com/yuansliu/mstcom.git
build_mstcom:
	git clone https://github.com/yuansliu/mstcom.git
	cd mstcom
	make

test_mstcom:
	# To compress:
	mstcom e -i {{infq}} -o OUTPUT
	mstcom e -i {{infq}} -o OUTPUT -p                     #order-preserving mode
	mstcom e -i {{in1fq}} -f {{in2fq}} -o comp.mst
	mstcom e -i {{in1fq}} -f {{in2fq}} -o comp.mst -p     #order-preserving mode
	#To decompress:
	mstcom d -i comp.mst -o {{outfq}}

# build slimfastq https://github.com/Infinidat/slimfastq
build_slimfastq:
	gcc_init
	git clone https://github.com/Infinidat/slimfastq
	cd slimfastq/
	echo "fixup sprintf(buf,...) -> snprintf(buf,sizeof(buf),...)"
	make

# test slimfastq
test_slimfastq:
	mytime gzip -dc {{t1fqgz}} | slimfastq -f {{t1outfq}}
	mytime -f "IO: io=%I faults=%F\n MEM: max=%M kb Average=%K kb\n CPU: Percentage=%P real=%e sys=%S user=%U" slimfastq {{infq}} /tmp/a.tst -O

# test clumpify
test_clumpify:
	clumpify.sh ow in={{infq}} out={{outfq}}

# build repaq https://github.com/OpenGene/repaq.git
build_repaq:
	git clone clone https://github.com/OpenGene/repaq.git
	cd repaq
	make

# test repaq
test_repaq:
	# repaq -c -i in.R1.fq -I in.R2.fq -o out.rfq
	time repaq -c -i {{infq}} -o {{outfq}}

# build Minicom (version from 2019-Sep-9, https://github.com/yuansliu/minicom):  for sequence only ?
build_minicom:
	git clone https://github.com/yuansliu/minicom

# test minicom
test_minicom:
	#SE, compression of DNA stream:
	minicom -r {{infq}} -t 12
	#SE ORD, compression of DNA stream:
	minicom -r {{infq}} -t 12 -p
	#PE, compression of DNA stream:
	minicom -1 {{in1fq}} -2 {{in2fq}} -t 12

#build FQSqueezer v0.1 (version from 2019-May-17, https://github.com/refresh-bio/fqsqueezer) v slow ?
build_fqsqueezer:
	git clone https://github.com/refresh-bio/fqsqueezer

# test fqsqueezer
test_fqsqueezer:
	#SE, compression of DNA stream:
	fqs-0.1 e -im n -qm n -om s -s -t 12 -out comp.fqs {{infq}}
	#SE ORD, compression of DNA stream:
	fqs-0.1 e -im n -qm n -om o -s -t 12 -out comp.fqs {{infq}}
	#PE, compression of DNA stream:
	fqs-0.1 e -im n -qm n -om s -p -t 12 -out comp.fqs {{in1fq}} {{in2fq}}
	#PE ORD, compression of DNA stream:
	fqs-0.1 e -im n -qm n -om o -p -t 12 -out comp.fqs {{in1fq}} {{in2fq}}

#PgRC v1.1 https://github.com/kowallus/PgRC
build_pgrc:
	gcc_init
	git clone https://github.com/kowallus/PgRC
	cd PgRC
	mkdir build
	cd build
	cmake ..
	# fix: cannot bind non-const lvalue reference of type 'long long unsigned int' to a value of type 'size_t' {aka 'long unsigned int'}
	make PgRC

test_pgrc:
	#SE, compression of DNA stream:
	PgRC -i {{infq}} -o comp.pgrc
	#SE ORD, compression of DNA stream:
	PgRC -o -i {{infq}} -o comp.pgrc
	#PE, compression of DNA stream:
	PgRC -i {{in1fq}} {{in2fq}} -o comp.pgrc
	#PE ORD, compression of DNA stream:
	PgRC -o -i {{infq}} -o comp.pgrc
