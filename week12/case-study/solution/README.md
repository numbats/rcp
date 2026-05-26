# Campus Cafe Analysis

This is the repaired version of the inherited project used in Week 12.

## Install packages

```r
install.packages(c("targets", "dplyr", "readr", "ggplot2", "scales", "knitr"))
```

## Rebuild the project

From this folder, run:

```r
targets::tar_make()
```

The pipeline reads `data/raw/cafe_sales.csv`, creates the files in `outputs/`, and renders `report.html`.

## Project structure

```text
.
|-- _targets.R
|-- R/
|   |-- data.R
|   |-- plots.R
|   |-- report.R
|   `-- summaries.R
|-- data/
|   `-- raw/
|       `-- cafe_sales.csv
|-- outputs/
`-- report.qmd
```
