mg1655 := "Ecoli-MG1655.fasta.gz"
baa835 := "A.muciniphila-ATCC_BAA-835.fasta.gz"
iai39 := "Ecoli-IAI39.fasta.gz"

inter :="inter.k23.unik"
#memusg := "memusg -t"
memusg := '\time -f "IO: io=%I faults=%F\n MEM: max=%M kb Average=%K kb\n CPU: Percentage=%P real=%e sys=%S user=%U"'

default:
	@just --list

get_data:
	cp /Users/copeland/Projects/2024/20240429-_unikmer/unikmer/testdata/old/Ecoli-MG1655.fasta.gz {{mg1655}}
	cp /Users/copeland/Projects/2024/20240429-_unikmer/unikmer/testdata/old/A.muciniphila-ATCC_BAA-835.fasta.gz {{baa835}}
	cp /Users/copeland/Projects/2024/20240429-_unikmer/unikmer/testdata/old/Ecoli-IAI39.fasta.gz {{iai39}}

build:
	git clone https://github.com/shenwei356/unikmer.git
	cd unikmer/
	go build

install:
	lx unikmer

#install_memusg:
#	# memusg is for compute time and RAM usage: https://github.com/shenwei356/memusg
#	go install github.com/shenwei356/memusg@latest

count:
	# counting (only keep the canonical k-mers and compact output)
	# memusg -t unikmer count -k 23 {{iai39}} -o {{iai39}}.k23 --canonical --compact
	# elapsed time: 0.897s
	# peak rss: 192.41 MB
	{{memusg}} unikmer count -k 23 {{mg1655}} -o {{mg1655}}.k23 --canonical --compact

	# counting (only keep the canonical k-mers and sort k-mers)
	# {{memusg}} unikmer count -k 23 {iai39} -o {{iai39}}.k23.sorted --canonical --sort
	# elapsed time: 1.136s
	# peak rss: 227.28 MB
	{{memusg}} unikmer count -k 23 {{mg1655}} -o {{mg1655}}.k23.sorted --canonical --sort

	# counting and assigning global TaxIds
	unikmer count -k 23 -K -s {{iai39}} -o {{iai39}}.k23.sorted   -t 585057
	unikmer count -k 23 -K -s {{mg1655}} -o {{mg1655}}.k23.sorted -t 511145
	unikmer count -k 23 -K -s {{baa835}} -o {{baa835}}.sorted -t 349741

	# counting minimizer and ouputting in linear order
	unikmer count -k 23 -W 5 -H -K -l {{baa835}} -o {{baa835}}.m

view: count
	unikmer view {{mg1655}}.k23.sorted.unik --show-taxid | head -n 3
	# AAAAAAAAACCATCCAAATCTGG 511145
	# AAAAAAAAACCGCTAGTATATTC 511145
	# AAAAAAAAACCTGAAAAAAACGG 511145

	# view (hashed k-mers needs original FASTA/Q file)
	unikmer view --show-code --genome {{baa835}} {{baa835}}.m.unik | head -n 3
	# CATCCGCCATCTTTGGGGTGTCG 1210726578792
	# AGCGCAAAATCCCCAAACATGTA 2286899379883
	# AACTGATTTTTGATGATGACTCC 3542156397282

find:
	# find the positions of k-mers
	unikmer locate -g {{baa835}} {{baa835}}.m.unik | head -n 5
	# NC_010655.1     2       25      ATCTTATAAAATAACCACATAAC 0       .
	# NC_010655.1     5       28      TTATAAAATAACCACATAACTTA 0       .
	# NC_010655.1     6       29      TATAAAATAACCACATAACTTAA 0       .
	# NC_010655.1     9       32      AAAATAACCACATAACTTAAAAA 0       .
	# NC_010655.1     13      36      TAACCACATAACTTAAAAAGAAT 0       .

info:
	unikmer info *.unik -a -j 10
	# file                                              k  canonical  hashed  scaled  include-taxid  global-taxid  sorted  compact  gzipped  version     number  description
	# A.muciniphila-ATCC_BAA-835.fasta.gz.m.unik       23  ✓          ✓       ✕       ✕                            ✕       ✕        ✓        v5.0       860,900
	# A.muciniphila-ATCC_BAA-835.fasta.gz.sorted.unik  23  ✓          ✕       ✕       ✕                    349741  ✓       ✕        ✓        v5.0     2,630,905
	# Ecoli-IAI39.fasta.gz.k23.sorted.unik             23  ✓          ✕       ✕       ✕                    585057  ✓       ✕        ✓        v5.0     4,902,266
	# Ecoli-IAI39.fasta.gz.k23.unik                    23  ✓          ✕       ✕       ✕                            ✕       ✓        ✓        v5.0     4,902,266
	# Ecoli-MG1655.fasta.gz.k23.sorted.unik            23  ✓          ✕       ✕       ✕                    511145  ✓       ✕        ✓        v5.0     4,546,632
	# Ecoli-MG1655.fasta.gz.k23.unik                   23  ✓          ✕       ✕       ✕                            ✕       ✓        ✓        v5.0     4,546,632

concat:
	{{memusg}} unikmer concat *.k23.sorted.unik -o concat.k23 -c
# 	elapsed time: 1.020s
# 	peak rss: 25.86 MB

union:
	{{memusg}} unikmer union *.k23.sorted.unik -o union.k23 -s
	# elapsed time: 3.991s
	# peak rss: 590.92 MB

sort:
	# or sorting with limited memory.
	# note that taxonomy database need some memory.
	{{memusg}} unikmer sort *.k23.sorted.unik -o union2.k23 -u -m 1M
	# elapsed time: 3.538s
	# peak rss: 324.2 MB
	unikmer view -t union.k23.unik | md5sum
	# 4c038832209278840d4d75944b29219c  -
	unikmer view -t union2.k23.unik | md5sum
	# 4c038832209278840d4d75944b29219c  -

find_duplicates:
	# {{memusg}} unikmer sort *.k23.sorted.unik -o dup.k23 -d -m 1M # limit memory usage
	{{memusg}} unikmer sort *.k23.sorted.unik -o dup.k23 -d
	# elapsed time: 1.143s
	# peak rss: 240.18 MB

intersection:
	{{memusg}} unikmer inter *.k23.sorted.unik -o inter.k23
	# elapsed time: 1.481s
	# peak rss: 399.94 MB

difference:
	{{memusg}} unikmer diff -j 10 *.k23.sorted.unik -o diff.k23 -s
	# elapsed time: 0.793s
	# peak rss: 338.06 MB

ls_unik:
	ls -lh *.unik
	# -rw-r--r-- 1 shenwei shenwei 6.6M Sep  9 17:24 A.muciniphila-ATCC_BAA-835.fasta.gz.m.unik
	# -rw-r--r-- 1 shenwei shenwei 9.5M Sep  9 17:24 A.muciniphila-ATCC_BAA-835.fasta.gz.sorted.unik
	# -rw-r--r-- 1 shenwei shenwei  46M Sep  9 17:25 concat.k23.unik
	# -rw-r--r-- 1 shenwei shenwei 9.2M Sep  9 17:27 diff.k23.unik
	# -rw-r--r-- 1 shenwei shenwei  11M Sep  9 17:26 dup.k23.unik
	# -rw-r--r-- 1 shenwei shenwei  18M Sep  9 17:23 Ecoli-IAI39.fasta.gz.k23.sorted.unik
	# -rw-r--r-- 1 shenwei shenwei  29M Sep  9 17:24 Ecoli-IAI39.fasta.gz.k23.unik
	# -rw-r--r-- 1 shenwei shenwei  17M Sep  9 17:23 Ecoli-MG1655.fasta.gz.k23.sorted.unik
	# -rw-r--r-- 1 shenwei shenwei  27M Sep  9 17:25 Ecoli-MG1655.fasta.gz.k23.unik
	# -rw-r--r-- 1 shenwei shenwei  11M Sep  9 17:27 inter.k23.unik
	# -rw-r--r-- 1 shenwei shenwei  26M Sep  9 17:26 union2.k23.unik
	# -rw-r--r-- 1 shenwei shenwei  26M Sep  9 17:25 union.k23.unik

stats:
	unikmer stats *.unik -a -j 10
	# file                                              k  canonical  hashed  scaled  include-taxid  global-taxid  sorted  compact  gzipped  version     number  description
	# A.muciniphila-ATCC_BAA-835.fasta.gz.m.unik       23  ✓          ✓       ✕       ✕                            ✕       ✕        ✓        v5.0       860,900
	# A.muciniphila-ATCC_BAA-835.fasta.gz.sorted.unik  23  ✓          ✕       ✕       ✕                    349741  ✓       ✕        ✓        v5.0     2,630,905
	# concat.k23.unik                                  23  ✓          ✕       ✕       ✓                            ✕       ✓        ✓        v5.0            -1
	# diff.k23.unik                                    23  ✓          ✕       ✕       ✓                            ✓       ✕        ✓        v5.0     2,326,096
	# dup.k23.unik                                     23  ✓          ✕       ✕       ✓                            ✓       ✕        ✓        v5.0     2,576,170
	# Ecoli-IAI39.fasta.gz.k23.sorted.unik             23  ✓          ✕       ✕       ✕                    585057  ✓       ✕        ✓        v5.0     4,902,266
	# Ecoli-IAI39.fasta.gz.k23.unik                    23  ✓          ✕       ✕       ✕                            ✕       ✓        ✓        v5.0     4,902,266
	# Ecoli-MG1655.fasta.gz.k23.sorted.unik            23  ✓          ✕       ✕       ✕                    511145  ✓       ✕        ✓        v5.0     4,546,632
	# Ecoli-MG1655.fasta.gz.k23.unik                   23  ✓          ✕       ✕       ✕                            ✕       ✓        ✓        v5.0     4,546,632
	# inter.k23.unik                                   23  ✓          ✕       ✕       ✓                            ✓       ✕        ✓        v5.0     2,576,170
	# union2.k23.unik                                  23  ✓          ✕       ✕       ✓                            ✓       ✕        ✓        v5.0     6,872,728
	# union.k23.unik                                   23  ✓          ✕       ✕       ✓                            ✓       ✕        ✓        v5.0     6,872,728
	# -----------------------------------------------------------------------------------------

mapping:
	# mapping k-mers to genome
	seqkit seq {{iai39}} -o Ecoli-IAI39.fasta
	#g=Ecoli-IAI39.fasta
	# mapping k-mers back to the genome and extract successive regions/subsequences
	unikmer map -g {{iai39}} {{inter}} -a | more

to_fasta:
	# using bwa
	# to fasta
	unikmer view {{inter}}  -a -o {{inter}}.fa.gz
	# make index
	bwa index {{iai39}} ; samtools faidx {{iai39}}
	ncpu=12
	ls {{inter}}.fa.gz \
			| rush -j 1 -v ref=$g -v j=$ncpu \
					'bwa aln -o 0 -l 17 -k 0 -t {j} {ref} {} \
							| bwa samse {ref} - {} \
							| samtools view -bS > {}.bam; \
					 samtools sort -T {}.tmp -@ {j} {}.bam -o {}.sorted.bam; \
					 samtools index {}.sorted.bam; \
					 samtools flagstat {}.sorted.bam > {}.sorted.bam.flagstat; \
					 /bin/rm {}.bam '
