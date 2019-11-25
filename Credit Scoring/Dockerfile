FROM r-base:3.5.1

# Install needed system libraries
RUN apt-get update -y
RUN apt-get install -y ksh \
    build-essential lib32stdc++6 \
    libxt-dev \
    unixodbc unixodbc-dev \
    libc6 \
    psmisc \
    rrdtool \
    libssl-dev=1.1.1-1 openssl \
    libcurl4-openssl-dev curl

# Add folders
RUN mkdir -p /www/rshiny/app
WORKDIR /www/rshiny/app

# Install teradata driver
ADD ./linux_install ./linux_install
WORKDIR /www/rshiny/app/linux_install
RUN dpkg -i tdodbc.deb

# Install R dependencies
RUN R -e 'install.packages(c("shiny", "plotly", "dplyr", "ggplot2", "viridisLite", "shinydashboard", "reshape2", "e1071", "rhandsontable", "pROC", "ROCR", "caret", "DBI", "odbc", "plotly", "splitstackshape", "data.table", "DT"), repos = "https://cran.ism.ac.jp/")'

# Add source code
WORKDIR /www/rshiny/app

ADD ./r/*.R ./
ADD ./r/*.html ./
ADD ./r/*.Rmd ./

ADD ./r/www ./www
ADD ./r/data ./data
ADD ./r/newtabs ./newtabs
ADD ./r/output_charts ./output_charts

ENV TD_DRIVER /opt/teradata/client/16.20/lib64/tdataodbc_sb64.so

CMD ["R", "-e", "shiny::runApp('./', port=8090, host='0.0.0.0', launch.browser = FALSE)"]
