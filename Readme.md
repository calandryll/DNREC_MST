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