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