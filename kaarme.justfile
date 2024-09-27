build:
   module load cudatoolkit

download:
   git clone https://github.com/Denopia/kaarme.git
   cd kaarme/
   mkd build
   cmake -S .. -B .


spack_create:
   spack create -t cmake -n kaarme
   vim CMakeLists.txt  # add install target
   git diff > kaarme.cmakelists.patch
   cp kaarme.cmakelists.patch /global/cfs/cdirs/jgiqaqc/spack/var/spack/repos/builtin/packages/kaarme

test:
   kaarme example/ecoli1x.fasta 51 -s 8000000 -t 3 -o example/ecoli1x-51mers.txt
   time kaarme example/ecoli1x.fasta 111 -s 3200000 -t 12 -o example/ecoli1x-111mers.txt
   kaarme example/ecoli1x.fasta 51 -t 3 -u 4000000 --use-bfilter -o example/ecoli1x-51mers.txt # bloom filter
   kaarme example/ecoli1x.fasta 51 -t 3 -m 0 -u 4000000 --use-bfilter -o example/ecoli1x-51mers.txt # plain hash + BF

