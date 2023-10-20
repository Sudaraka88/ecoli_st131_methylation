
<!-- EDIT THIS FILE, DO NOT EDIT .md -->

# Viewing genome-wide methylation in E. coli ST131

## Deploying the [shiny](https://www.rstudio.com/products/shiny/) app locally

### Option 1

Best (and easiest!) way is to copy+paste (or download) and run
[app.R](https://github.com/Sudaraka88/ecoli_st131_methylation/blob/main/app.R)
locally from RStudio. Simply click the `Run App` button at the top of
the script panel. You can also enter the command:

`shiny::runApp("<path_to_the_folder_containing_app.R>")`

### Option 2

Slower than Option 1: To run via github, open
[Rstudio](https://posit.co/products/open-source/rstudio/) and enter the
following command:

`shiny::runGitHub("ecoli_st131_methylation", "Sudaraka88")`

### Web version

A web version of the applet is also available in
[shinyapps.io](https://sudaraka88.shinyapps.io/ecoli_st131_methylation/)
and might be useful to get a taste. However, the web version is unstable
and using the local version is highly recommended.

## Walkthrough

If everything works as expected, the app should open in a new RStudio
(or Browser) window and should look like this:
![](screenshots/welcome.png)

Click on `Update Tracks` to load the genome, annotation and selected
methylation and barcode tracks. This will automatically switch the app
into the `Browser` (right) page. Please click on `Options` (left) page
to come back to this view. It is possible to modify methylation and
barcode selections using check boxes and the browser view can be updated
(again) by clicking `Update Tracks`.

> **Note** Adding a large number of methylation tracks might slow down
> the the browser!

The browser view is based on [jbrowse2](https://jbrowse.org/jb2/). There
are standard options to zoom in, out and scroll through regions. It is
also possible to jump to a region by entering the bp position in the
search window as: `(chr:from..to)`. Additionally, any entry in the
genome annotation can be searched using the same search box (E.g. DnaA).

In the browser view, click on any genomic annotation (gold horizontal
bars) to fetch information from the annotation (e.g., gene name,
nucleotide sequence) ![](screenshots/gffinfo.png)

Clicking these annotations will add them to the `bookmarks table` in the
`Options` (left) page. This table can also be used to quickly jump
between saved regions by clicking the `Navigate` button below. Entries
in the `bookmarks table` can be edited using controls below it.
![](screenshots/bookmarks.png)

Once an interesting region is identified, it is possible to zoom in to
view the nucleotide and AA sequences. The height of methylation bars
(blue vertical) show the ratio between methylated and total reads
covering the region. ![](screenshots/viewer.png)
