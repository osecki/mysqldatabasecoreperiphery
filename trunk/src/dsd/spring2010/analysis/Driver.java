/**
 * Jordan Osecki
 */
package dsd.spring2010.analysis;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.sql.*;
import java.util.Properties;
import java.util.Vector;
import dsd.spring2010.analysis.ds.*;

/**
 * @author Jordan Osecki
 *
 */
public class Driver
{
	// Table Attributes
	public static Vector <Aliases> aliasesVector = new Vector <Aliases> ();
	public static Vector <Mails> mailsVector = new Vector <Mails> ();
	public static Vector <Persons> personsVector = new Vector <Persons> ();
	public static Vector <Threads> threadsVector = new Vector <Threads> ();
	//public static Vector <TicketMails> ticketMailsVector = new Vector <TicketMails> ();
	
	/**
	 * @param args
	 */
	public static void main(String[] args)
	{
		// Initiate connection with the database
		String url = "jdbc:postgresql://wander.cs.drexel.edu:5432/CS680ateam";
		String username = "jmo34";
		String password = "pVfNP8e8KqjY";
		Connection conn;
		
		try 
		{
			conn = DriverManager.getConnection(url, username, password);
		
			// Iterate through each of the tables and pull the information from it
			
			// Get Aliases
			Statement st = conn.createStatement();
			ResultSet rs = st.executeQuery("SELECT * FROM aliases");
			while (rs.next()) 
			{
			    Aliases a = new Aliases (rs.getInt(1), rs.getInt(2), rs.getString(3) );
			    aliasesVector.add(a);
			}
			rs.close();
			st.close();
			
			// Get Mails
			st = conn.createStatement();
			rs = st.executeQuery("SELECT * FROM mails");
			while (rs.next()) 
			{
			    Mails m = new Mails (rs.getInt(1), rs.getInt(2), rs.getDate(3), rs.getInt(4), rs.getInt(5), rs.getInt(6), rs.getString(7) );
			    mailsVector.add(m);
			}
			rs.close();
			st.close();

			// Get Persons
			st = conn.createStatement();
			rs = st.executeQuery("SELECT * FROM persons");
			while (rs.next()) 
			{
			    Persons p = new Persons (rs.getInt(1), rs.getString(2), rs.getString(3) );
			    personsVector.add(p);
			}
			rs.close();
			st.close();
			
			// Get Threads
			st = conn.createStatement();
			rs = st.executeQuery("SELECT * FROM threads");
			while (rs.next()) 
			{
			    Threads t = new Threads (rs.getInt(1), rs.getString(2) );
			    threadsVector.add(t);
			}
			rs.close();
			st.close();
			
			// Get TicketMails
			/*st = conn.createStatement();
			rs = st.executeQuery("SELECT * FROM ticketmails");
			while (rs.next()) 
			{
			    TicketMails tm = new TicketMails (rs.getInt(1), rs.getInt(2), rs.getInt(3) );
			    ticketMailsVector.add(tm);
			}
			rs.close();
			st.close();*/
		} 
		catch (SQLException e) 
		{
			System.out.println("Error. Problem connecting to the database. Try again with correct parameters.");
			e.printStackTrace();
		}
		
		// Perform core-periphery analysis on the data structures
		
		// Begin to write CSV file
		try
		{
		    // Create file 
		    FileWriter fstream = new FileWriter("MYSQL-MAILINGLIST-CSV.csv");
		    BufferedWriter out = new BufferedWriter(fstream);
		    
		    // Write out to the CSV in the format that NodeXL expects
		    // TODO Figure out NodeXL format
		    out.write("Hello World");
		   
		    // Close the output stream
		    out.close();
		}
		catch (Exception e)
		{
			// Catch exception if any
		    System.err.println("Error: " + e.getMessage());
		}	
	}

}
