task TRUST4_TASK {

    File? gene_reference
    File? gene_annotation
    String sample_id
    File? input_bam
    File? fq_1
    File? fq_2
    String? barcode_10x
    String Docker
    Int preemptible
    Int maxRetries
    String memory
    String disks
    Int cpu
    
    String dollar = "$"
    
    command <<<

    set -e

    # define reference files

    if [[ -z "${gene_reference}" ]]; then
        gene_reference_run="/opt2/TRUST4/hg38_bcrtcr.fa"
    else
        gene_reference_run="${gene_reference}"
    fi

    if [[ -z "${gene_annotation}" ]]; then
        gene_annotation_run="/opt2/TRUST4/human_IMGT+C.fa"
    else
        gene_annotation_run="${gene_annotation}"
    fi

    # check 10x

    if [[ ! -z "${barcode_10x}" ]]; then
        support_barcode_10x="--barcode ${barcode_10x}"
    else   
        support_barcode_10x=""
    fi

    # trust4

    if [[ ! -z "${input_bam}" ]]; then
        run-trust4 \
            -b ${input_bam} \
            -t ${cpu} \
            ${dollar}{support_barcode_10x} \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_id}

    elif [[ -z "${fq_2}" ]]; then
        run-trust4 \
            -u ${fq_1} \
            -t ${cpu} \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_id}

    else
        run-trust4 \
            -1 ${fq_1} \
            -2 ${fq_2} \
            -t ${cpu} \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_id}

    fi

    gzip ${sample_id}_annot.fa
    gzip ${sample_id}_cdr3.out
    gzip ${sample_id}_report.tsv
    gzip ${sample_id}_airr.tsv

    if [[ ! -z "${barcode_10x}" ]]; then
        gzip ${sample_id}_barcode_report.tsv
    fi
      
   >>>
    
    output {
      File annot="${sample_id}_annot.fa.gz"
      File report="${sample_id}_cdr3.out.gz"
      File simpleReport="${sample_id}_report.tsv.gz"
      File airrReport="${sample_id}_airr.tsv.gz"
      File? barcodeReport="${sample_id}_barcode_report.tsv.gz"
   }
   
    runtime {
            docker: Docker
            disks: disks
            memory: memory
            cpu: cpu
            preemptible: preemptible
            maxRetries: maxRetries
    }

}


workflow trust4_wf {

    String sample_id
    File? gene_reference
    File? gene_annotation
    File? bam
    File? fq_1
    File? fq_2
    Array[File]? smart_1
    Array[File]? smart_2
    String? barcode_10x
    String? Docker = "lindax/trust4:v113"
    Int preemptible = 0
    Int maxRetries = 0
    String memory = "10GB"
    String disks = "local-disk 50 SSD"
    Int cpu = "8"

    if (defined(bam)||defined(fq_1)) {
        call TRUST4_TASK {
            input:
                input_bam=bam,
                fq_1=fq_1,
                fq_2=fq_2,
                sample_id=sample_id,
                barcode_10x=barcode_10x,
                gene_reference=gene_reference,
                gene_annotation=gene_annotation,
                Docker=Docker,
                preemptible=preemptible,
                maxRetries=maxRetries,
                disks=disks,
                memory=memory,
                cpu=cpu
        }
    }

}
