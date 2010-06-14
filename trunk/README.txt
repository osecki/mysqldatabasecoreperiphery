All code, documentation, and data used for our research project is stored on Google Code at the following location:
http://code.google.com/p/mysqldatabasecoreperiphery/

When you checkout the code, we have the following structure:

DSD-AnalysisProject
	-src (contains the Java code)
	-Documentation (contains the final report and presentation)
	-lib (contains the Perl script for pulling from the mailing list and populating the database)
	-postgresql-8.4-701.jdbc3.jar

The Java code contains object mappings to the database tables and the driver to pull data back from those
tables.  We have the following two packages:

dsd.spring2010.analysis
dsd.spring2010.analysis.ds

The first package contains the code to pull data back from the PostgreSQL database and create the input
that will be used in UCInet.

The second package contains the object mappings for the database.

If building in Eclipse, make sure to set your build path to include the postgresql-8.4-701.jdbc3.jar, 
which contains the drivers for connecting to a PostgreSQL database.  

Run Driver.java to connect to the PostgreSQL database and create the input files.  
Set the releaseDate and releaseDatePrevious variables for the release dates you wish to analyze.  

This will create a dl text file called: MYSQL-UCINET-[releaseDate].txt, that can be inputted into
UCInet.  The format of this file is a matrix of edgelists between aliases in the mailing list.

Download UCInet at: http://www.analytictech.com/ucinet/download.htm

Once installed, you can run analysis on the txt files generated from the Java program.

Select Data->Import text file->DL...
Select the created text file and click 'OK'
	-This will create two new files, a .##d and a .##h files.

To generate core/periphery numbers, select Network->Core/Periphery->Categorical
Select the .##h file, and this will generate the core/periphery metrics.

To create the network graph, select Visualize->NetDraw
This will open the NetDraw app.
Select File->Open->Ucinet dataset->Network and again select the .##h file.
This will generate the core/periphery network graph.



