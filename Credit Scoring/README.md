# Installation

## R/Shiny

### Via Docker
1. Download and extract the Teradata Linux ODBC driver (Ubuntu version). Copy the `.deb` file to the `linux_install` folder located on the project root. Rename the file to `tdodbc.deb`.
2. Run `docker-compose build` to build the image then run `docker-compose up -d` to run the application.
3. Go to `localhost:8090` to view the Shiny app.
