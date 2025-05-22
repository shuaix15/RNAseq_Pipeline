#ml FastQC/0.11.9
echo "${SAMPLEID} FastQC Begin"
fastqc -o /nobackup/sbcs/xus13/LungtissueTWAS/cell_line/ ${SAMPLEID}_R1_001.fastq.gz ${SAMPLEID}_R2_001.fastq.gz
echo "${SAMPLEID} FastQC End"

#ml GCC/6.4.0-2.28  OpenMPI/2.1.1 Intel/2017.4.196  IntelMPI/2017.3.196 MultiQC/1.6-Python-3.6.3
echo " MultiQC Begin"
multiqc *_001.fastq.gz
echo " MultiQC End"

## Adopt from GTEx (OH75) using oh100
#ml GCC/6.4.0-2.28 Intel/2017.4.196 STAR/2.5.4b
STAR \
     --runMode genomeGenerate \
     --genomeDir STARv254b_genome_GRCh38_v26_oh100 \
     --genomeFastaFiles GRCh38.primary_assembly.genome.fa \
     --sjdbGTFfile gencode.v26.annotation.gtf \
     --sjdbOverhang 100 \
     --runThreadN 10 \

threadNo=32
SAMPLEID="11619-LX-05"
rgline="ID:${SAMPLEID} SM:${SAMPLEID} LB:${SAMPLEID} PL:ILLUMINA PU:ILLUMINA"
dbDir="./STARv254b_genome_GRCh38_v26_oh100"
output="./BAM"
echo " STAR Begin"

STAR --twopassMode Basic \
     --outSAMprimaryFlag AllBestScore \
     --outSAMattrRGline $rgline \
     --runThreadN $threadNo \
     --genomeDir $dbDir \
     --readFilesIn ${SAMPLEID}_R1_001.fastq.gz ${SAMPLEID}_R2_001.fastq.gz \
     --readFilesCommand zcat \
     --outFileNamePrefix ${output}/${SAMPLEID}_ \
     --outSAMtype BAM SortedByCoordinate \
     --outSAMstrandField intronMotif \
     --outSAMattributes NH HI NM MD AS XS \
     --outSAMunmapped Within \
     --outSAMheaderHD @HD VN:1.4 \
     --outFilterMultimapScoreRange 1 \
     --outFilterMultimapNmax 20 \
     --outFilterMismatchNmax 10 \
     --alignIntronMax 500000 \
     --alignMatesGapMax 1000000 \
     --sjdbScore 2 \
     --alignSJDBoverhangMin 1 \
     --genomeLoad NoSharedMemory \
     --limitBAMsortRAM 0 \
     --outFilterMatchNminOverLread 0.33 \
     --outFilterScoreMinOverLread 0.33 \
     --sjdbOverhang 100
echo " STAR End"

#ml GCC/11.3.0 SAMtools/1.18
samtools index -@ $threadNo ${output}/${SAMPLEID}_Aligned.sortedByCoord.out.bam

#ml picard/2.18.27
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    I=${output}/${SAMPLEID}_Aligned.sortedByCoord.out.bam \
    O=${output}/${SAMPLEID}_Aligned.sortedByCoord.out.md.bam \
    M=${output}/${SAMPLEID}_Aligned.sortedByCoord.marked_dup_metrics.txt \
    PROGRAM_RECORD_ID=null \
    MAX_RECORDS_IN_RAM=500000 \
    SORTING_COLLECTION_SIZE_RATIO=0.25 \
    TMP_DIR=${output}/tmp \
    ASSUME_SORT_ORDER=coordinate \
    TAGGING_POLICY=DontTag \
    OPTICAL_DUPLICATE_PIXEL_DISTANCE=100

samtools index -@ $threadNo ${output}/${SAMPLEID}_Aligned.sortedByCoord.out.md.bam

while read line
 do
   echo $line
   SAMPLEID=$line
   /nobackup/sbcs/xus13/software/rnaseqc/rnaseqc.v2.4.2.linux ./genexp/gencode.v26.gene.gtf ./BAM/${SAMPLEID}_Aligned.sortedByCoord.out.md.bam ./genexp/${SAMPLEID}/
done < sample
