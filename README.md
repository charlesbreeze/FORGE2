## FORGE2


FORGE2 is also available as a web tool at 

https://forge2.altiusinstitute.org/

FORGE2 is based on eFORGE but applies analysis to GWAS SNP data

## Setup

1. The script itself is currently called eforge.pl written in Perl. It has
the following Perl dependencies.

use 5.012;

use warnings;

use DBI;

use Sort::Naturally;

use Cwd;

use Storable;

use Getopt::Long;

2. The sqlite3 db file that stores the bitstrings. This file is called forge2.db currently.

3. A stored hash containing the parameters for the background selection. Currently two files, snp_GWAS_bins and snp_GWAS_params.

The database and the hashes are downloadable from:
https://forge2.altiusinstitute.org/?download

4. An eforge.ini file in the same directory as the script. Edit this to provide the directory in which the database and hash are stored.

5. An R 3.0 installation with the "devtools" and "rCharts" packages installed. See

https://github.com/ramnathv/rCharts. You will need to install the latest version e.g.

require(devtools)
install_github('rCharts', 'ramnathv', ref = "dev")

## Input

The input data is currently a list of RSIDs (SNPs)

The web analysis requires a minimum of 5 SNPs (operationally the best option).

To work SNPs currently have to be on the FORGE2 database (covering 94.2% of the SNPs in the GWAS catalog as of 26-Jun-2019). The script gives warnings on SNPs not found.

It also warns for background sets that do not have the right number of probes chosen, but this is really for information only.

## Options

FORGE2 takes a series of command line options as follows

-f : the file to run on

-data : whether to analyse ENCODE ('encode'), unconsolidated Roadmap Epigenomics data ('erc'), consolidated Roadmap Epigenomics DNase-seq data ('erc2-DHS'), BLUEPRINT data ('blueprint'), Roadmap Epigenomics histone mark data for 'erc2-H3K4me1', 'erc2-H3K9me3', 'erc2-H3K4me3', 'erc2-H3K36me3', or 'erc2-H3K27me3'. FORGE2 also supports analysis across all histone marks ('erc2-H3-all'), and all chromatin states ('erc2-chromatin15state-all'). For more details see Analysis options at https://forge2.altiusinstitute.org/). FORGE2 will analyse erc by default.

-label : a name for the files that are generated and for the plot titles where there is a title.

-format : for the input data format. If this is location data e.g. bed format, the probeid is obtained from the sqlite3 database.
 
Some of these default as described in the perldoc. Minimally the command line is:

eforge.pl -f probeidfile -label Some_label

which will by default run on Epigenome Roadmap data

## Output

there are several outputs generated

1. A pdf static chart, for download.

2. A d3 interactive chart.

3. A Datatables table.

4. R code files for generating the charts and the table.

5. There is also a tsv file of the results.

## Multithreading

FORGE2 will automatically use multithreading if run with a Perl installation compiled with thread support. But those Perl installations that do not support multi-threading,  we also provide a single-threaded version at eforge.safe_copy_nonthreaded.pl.

## Webserver

To install the web interface, please refer to the INSTALL document in the webserver folder.
