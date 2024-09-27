pb :=  "pacbio.fastq"
hifi := "ecoli.fastq"
lc := "yeast.20x.fastq.gz"
pbc := "ecoli.correctedReads.fasta.gz"
canu := "canu/build/bin/canu"

build:
  gcc_init
  git clone https://github.com/marbl/canu.git
  cd canu/src
  LDFLAGS=-L/usr/local/opt/openssl@3.3/lib make  -j 4

test:
  echo "test"
  curl -L -o {{pb}} http://gembox.cbcb.umd.edu/mhap/raw/ecoli_p6_25x.filtered.fastq
  {{canu}} -p ecoli -d ecoli-pacbio genomeSize=4.8m -pacbio {{pb}}

hifi:
  curl -L -o {{hifi}} https://sra-pub-src-1.s3.amazonaws.com/SRR10971019/m54316_180808_005743.fastq.1
  {{canu}} -p asm -d ecoli_hifi genomeSize=4.8m -pacbio-hifi {{hifi}}

correct_trim_assemble:
  #We’ll use the PacBio reads from above. First, correct the raw reads:
  {{canu}} -correct  -p ecoli -d ecoli  genomeSize=4.8m -pacbio  {{pb}}
  # Then, trim the output of the correction:
  {{canu}} -trim -p ecoli -d ecoli genomeSize=4.8m -corrected -pacbio ecoli/{{pbc}}
  #And finally, assemble the output of trimming, twice, with different stringency on which overlaps to use (see correctedErrorRate):
  {{canu}} -p ecoli -d ecoli-erate-0.039 genomeSize=4.8m correctedErrorRate=0.039 -trimmed -corrected -pacbio ecoli/ecoli.trimmedReads.fasta.gz
  {{canu}} -p ecoli -d ecoli-erate-0.075 genomeSize=4.8m correctedErrorRate=0.075 -trimmed -corrected -pacbio ecoli/ecoli.trimmedReads.fasta.gz

low_coverage:
  curl -L -o {{lc}} http://gembox.cbcb.umd.edu/mhap/raw/yeast_filtered.20x.fastq.gz
  canu -p asm -d yeast genomeSize=12.1m correctedErrorRate=0.105 -pacbio {{lc}}

list:
	ls /Users/copeland/Projects/2024/20240426-_canu/canu/build/bin
