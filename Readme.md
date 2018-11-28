## Sample Analysis

### Convert November 2018 files to FASTQ

```bash
convert_fastaqual_fastq.py -f 102418CMillcus515F-full.fasta \
    -q 102418CMillcus515F-full.qual \
    -o fastq

mv 102418CMillcus515F-full.fastq November.fastq
```

### Convert July 2017 files to FASTQ

```bash
convert_fastaqual_fastq.py -f 062917CM515F-full.fasta \
    -q 062917CM515F-full.qual \
    -o fastq

mv 062917CM515F-full.fastq July.fastq
```

### Extracting Barcodes

```bash
extract_barcodes.py -f fastq/July.fastq \
    -m mapping.txt \
    -o fastq/July_barcode_1 \
    -a -l 8
```

```bash
extract_barcodes.py -f fastq/July_barcode_1/reads.fastq \
    -o fastq/July_barcode_2 -l 20
```

```bash
extract_barcodes.py -f fastq/November.fastq \
    -m mapping.txt \
    -o fastq/November_barcode_1 \
    -a -l 8
```

```bash
extract_barcodes.py -f fastq/November_barcode_1/reads.fastq \
    -o fastq/November_barcode_2 -l 20
```

#### Combine Files
Combine separate sequencing files into a combined file for further downstream analysis.

```bash
cat July_barcode_2/reads.fastq November_barcode_2/reads.fastq > love_creek_reads.fastq
```

```bash
cat July_barcode_1/barcodes.fastq November_barcode_1/barcodes.fastq > love_creek_barcodes.fastq
```

### Split the files

```bash
split_libraries_fastq.py -i fastq/love_creek_reads.fastq \
    -b fastq/love_creek_barcodes.fastq \
    -m mapping.txt \
    --barcode_type 8 \
    -o split_library \
    --phred_offset 33
```
> 9149088  : split_library/seqs.fna (Sequence lengths (mean +/- std): 270.5207 +/- 10.4980)

### Identify Chimeras

```bash
identify_chimeric_seqs.py -i split_library/seqs.fna \
    -m usearch61 \
    -o chimeras \
    -r /home/chris/miniconda3/envs/qiime1/lib/python2.7/site-packages/qiime_default_reference/gg_13_8_otus/rep_set/97_otus.fasta
```

### Open Reference picking of OTUs

```bash
pick_open_reference_otus.py -i split_library/seqs.fna \
    -o otus \
    -a -O 24
```

### Core Diversity Analysis

```bash
core_diversity_analyses.py -i otus/otu_table_mc2_w_tax_no_pynast_failures.biom \
    -o diversity \
    -m mapping.txt \
    -e 31511 \
    -a -O 24 \
    -t otus/rep_set.tre \
    -c Site \
    --recover_from_failure
```

The -e was determined via
```bash
biom summarize-table -i otus/otu_table_mc2_w_tax_no_pynast_failures.biom > otu_summary.txt
```
and choosing the minimum number.

### Filter unwanted OTUs

#### Filter low abundance

See [Bix et al. 2016](https://msphere.asm.org/content/1/6/e00226-16)
```bash
filter_otus_from_otu_table.py -i otus/otu_table_mc2_w_tax_no_pynast_failures.biom \
    -o otus/filtered_abundance_table.biom \
    --min_count_fraction 0.000005
```

#### Filter Mitochondria and Chloroplasts

```bash
filter_taxa_from_otu_table.py -i otus/filtered_abundance_table.biom \
    -o otus/filtered_abund_chloro_mito.biom \
    -n f__Mitochondria,o__Chlorophyta,c__Chloroplast
```

### [Sourcetracker](https://github.com/danknights/sourcetracker)

#### Convert to format for Sourcetracker

```bash
biom convert -i otus/otu_table_mc2_w_tax_no_pynast_failures.biom \
    -o nonfiltered.txt \
    --to-tsv
```

```bash
biom convert -i otus/filtered_abund_chloro_mito.biom \
    -o filtered.txt \
    --to-tsv
```

#### Run Sourcetracker

```bash
R --slave --vanilla --args -i nonfiltered.txt -m mapping.txt -o sourcetracker_1 -r 30000 --train_rarefaction 30000 < $SOURCETRACKER_PATH/sourcetracker_for_qiime.r
```