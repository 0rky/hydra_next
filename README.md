# Implementing quality control (QC) with nextflow leveraging Hydra - an NDN based data storage

## Installation of Nextflow:

#### Install SDKMAN and Java:
```
sudo apt install zip
sudo apt install unzip
curl -s "https://get.sdkman.io" | bash
sdk install java 17.0.6-amzn
java --version # To check java installation
```

#### Installing nextflow:
```
wget -O nextflow https://github.com/nextflow-io/nextflow/releases/download/v23.10.0/nextflow-23.10.0-all
chmod +x nextflow
#And move it to somewhere in $PATH:
mv nextflow /bin
```

## Running nextflow

Install miniconda before proceeding. Nextflow will automatically install required QC packages with the help of miniconda.  

Since nextflow only supports POSIX standard filesystems, we have to stage the file first and then send it to the computation pipeline.


### ASSUMING THE DATA IS ALREADY IN THE CLUSTER

Change directory to the cloned repo and run the following commands.  

To download the paired end reads from the cluster to perform QC
```
nextflow run main.nf --input=<path_to_data_in_hydra_cluster> \
--outDir=<path_to_local_storage> \
--result=<path_to_output_result> \
-profile conda \
-entry fetch_hydra
```
example:
```
nextflow run main.nf --input=/data --outDir=/home/ubuntu/data --result=/home/ubuntu/data/results -profile conda -entry fetch_hydra
```

To start the computation of QC and publish the result back to the hydra cluster run the following command. The data will be published in the same namespace as the input data. 

```
 nextflow run main.nf --input=<path_to_data_in_hydra_cluster> \
 --outDir=<path_to_local_storage> \
 --result=<path_to_output_result> \
 -profile conda \
 -entry compute_data
```

 Example:
```
nextflow run main.nf --input=/data --outDir=/home/ubuntu/data --result=/home/ubuntu/data/results -profile conda -entry compute_data
```