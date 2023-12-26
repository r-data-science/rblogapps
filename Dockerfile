FROM rocker/verse:4.3.2
RUN apt-get update && apt-get install -y  cmake git-core libcurl4-openssl-dev libicu-dev libpng-dev libssl-dev libxml2-dev make pandoc zlib1g-dev && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_version("withr",upgrade="never", version = "2.5.2")'
RUN Rscript -e 'remotes::install_version("fs",upgrade="never", version = "1.6.3")'
RUN Rscript -e 'remotes::install_version("stringr",upgrade="never", version = "1.5.1")'
RUN Rscript -e 'remotes::install_version("testthat",upgrade="never", version = "3.2.0")'
RUN Rscript -e 'remotes::install_version("scales",upgrade="never", version = "1.3.0")'
RUN Rscript -e 'remotes::install_version("ggplot2",upgrade="never", version = "3.4.4")'
RUN Rscript -e 'remotes::install_version("shiny",upgrade="never", version = "1.8.0")'
RUN Rscript -e 'remotes::install_version("shinydashboard",upgrade="never", version = "0.7.2")'
RUN Rscript -e 'remotes::install_version("vdiffr",upgrade="never", version = "1.0.7")'
RUN Rscript -e 'remotes::install_version("shinytest2",upgrade="never", version = "0.3.1")'
RUN Rscript -e 'remotes::install_version("lubridate",upgrade="never", version = "1.9.3")'
RUN Rscript -e 'remotes::install_version("ggpubr",upgrade="never", version = "0.6.0")'
RUN Rscript -e 'remotes::install_version("ggthemes",upgrade="never", version = "5.0.0")'
RUN Rscript -e 'remotes::install_version("shinycssloaders",upgrade="never", version = "1.0.0")'
RUN Rscript -e 'remotes::install_version("shinyWidgets",upgrade="never", version = "0.8.0")'
RUN Rscript -e 'remotes::install_version("shinydashboardPlus",upgrade="never", version = "2.0.3")'
RUN Rscript -e 'remotes::install_version("data.table",upgrade="never", version = "1.14.8")'
RUN Rscript -e 'remotes::install_version("remotes",upgrade="never", version = "2.4.2.1")'
RUN mkdir /build_zone
ADD . /build_zone
WORKDIR /build_zone
RUN R -e 'remotes::install_local(upgrade="never")'
RUN rm -rf /build_zone
EXPOSE 3838
CMD  ["R", "-e", "options('shiny.port'=3838,shiny.host='0.0.0.0');rblogapps::runBlogApp(" ")"]
