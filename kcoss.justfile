download:
   git clone https://github.com/kcoss-2021/KCOSS.git

spack_init:
   spack_init
   spack load /37db

build_kcoss: spack_init
   cd KCOSS
   cd kmer_count
   mkd build
   vim ../CMakeLists.txt # add missing install target
   cmake ..
   make -j 8

build_kmer_dump: spack_init
   #spack location -i libcuckoo
   cd KCOSS/kmer_dump
   mkd build
   vim ../CMakeLists.txt
   cmake ..
   make -j 8

build_kmer_histo: spack_init
   cd KCOSS/kmer_histo
   mkd build
   vim ../CMakeLists.txt
   cmake ..
   make -j 8

test:
   ./kcoss -k 32 -i "../test_file/test_data.fa" -t 48 -m 360 -o out_file -n 3000000000 -d 268697600
