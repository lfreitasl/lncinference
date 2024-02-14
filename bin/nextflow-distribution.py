#!/usr/bin/env python
# coding: utf-8

# In[1]:


import gzip
import sys
import glob
import os
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import sys

# pasta onde você pode encontrar os arquivos
directory_paths = sys.argv[1:]

def read_multiple_fastq_files(directory_paths):
    all_results = {}
    var = len(directory_paths) #número de arquivos fasta - nrows
    
    fig, axes = plt.subplots(nrows= var, ncols=1, figsize=(6, 9)) #colocar a variável var em nrows(nf)
    
    # Ensure axes is always an array
    if var == 1:
        axes = [axes]
    else:
        axes = axes.flatten()

    #axes = axes.flatten()  # Flatten the 2D array of axes for easy iteration
    
    ax_index = 0 #track the subplot being drawn

    
    with open("read_len_sum.txt", 'w') as file: #tirar o caminho e deixar só o txt(nf)
    

        for directory_path in directory_paths:
            folder_name = os.path.basename(directory_path) #nextflow - caminhos para os arquivos (folder_name é na real file_name)
            fastq_files = glob.glob(directory_path) #+ '/*.fastq.gz') #retirar o que vem depois do + (nf)

            for fastq_file in fastq_files:
                with gzip.open(fastq_file, 'rt') as f:
                    reads = []
                    bases = []
                    line_counter = 0
                    for line in f:
                        line_counter += 1
                        if line_counter == 1: #Identifica as reads
                            reads.append(line)
                        elif line_counter == 2: #identifica as bases/sequências
                            bases.append(line.strip())
                        elif line_counter == 4: #desconsidera as linhas de qualidade e reseta a contagem
                            line_counter = 0

                    total_reads = len(reads)
                    total_bases = sum(len(base) for base in bases)
                    avg_read_length = total_bases / total_reads
                    max_read_length = max(len(base) for base in bases)
                    max_read_length_index = [len(base) for base in bases].index(max_read_length)
                    result = {
                        "file": os.path.basename(fastq_file),
                        "total_reads": total_reads,
                        "total_bases": total_bases,
                        "avg_read_length": avg_read_length,
                        "max_read_length": max_read_length,
                        "max_read_length_index": max_read_length_index,
                        "read_with_max_length": reads[max_read_length_index],
                        "read_lengths": [len(base) for base in bases],
                        "num_reads": total_reads
                    }
                    file_name = os.path.splitext(os.path.basename(fastq_file))[0]
                    all_results[file_name] = result

                    # Analysis preview
                    file.write(f'File: {file_name}\n')
                    file.write(f'Total Reads: {total_reads}\n')
                    file.write(f'Total Bases: {total_bases}\n')
                    file.write(f'Average Read Length: {avg_read_length}\n')
                    file.write(f'Max Read Length: {max_read_length}\n')
                    file.write(f'Read with Max Length: {reads[max_read_length_index]}\n')
                    file.write(f'\n\n\n')


                    # Generate boxplot using seaborn
                    sns.boxplot(x="read_lengths", data=pd.DataFrame(result), ax=axes[ax_index])
                    axes[ax_index].set_xlabel('Read Length')
                    axes[ax_index].set_title(f'Boxplot for {file_name}')

                    ax_index += 1
    
    plt.tight_layout()
    plt.savefig('boxplots.pdf') #deixar só o pdf, tirar o caminho (nf)

    return all_results

#directory_paths = ['D:'
#                  ] #lista de diretórios - trabalhar na entrada do nextflow

results = read_multiple_fastq_files(directory_paths)


# In[ ]:





# In[ ]:




