# README

This repository contains my semester project for CSCI 601, Data Modeling and Database Design. The project implements a web site that allows users to view a graphs of the current trends in COVID-19 case data.  It was built using Ruby on Rails using JetBrain's RubyMine IDE. The web server periodically pulls data from Microsoft's bing.com/covid site and stores it in a Postgres database.  Uses can connect to the webserver via a browswer to request various views of the COVID-19 case data - active, recovered, and fatal.  The webserver accesses the database to retrieve the required data necessary to build the requested views.  As the web server pulls new data, any connected clients views are automatically and asynchronously updated with the latest data.

![](browser.jpg)
