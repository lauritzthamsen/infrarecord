# InfraRecord: Immediate Feedback on ORM Queries

An attempt to provide Rails developers continuously with feedback on their Active Record code, including the generated queries, cardinalities, and fetched result sets.
  
This project was started in the course [Enterprise Application Programming Model Research](http://epic.hpi.uni-potsdam.de/Home/ProgMod_W2012) at [HPI](hpi-web.de).

## Setup
* clone lauritzthamsen/infrarecord
* clone redcar/redcar
* put a link to infrarecord/redcar_plugin/infrarecord/ into redcar/plugins

## Usage
* include the infrarecord gem into the Gemfile of your Rails application
* start the rails server and redcar
* open a document and open *InfraRecord* from the *Debug* menu
