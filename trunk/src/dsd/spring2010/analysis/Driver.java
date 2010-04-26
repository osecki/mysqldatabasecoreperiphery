/**
 * Jordan Osecki
 */
package dsd.spring2010.analysis;
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
	// Attributes
	public static Vector <Aliases> aliasesVector = new Vector <Aliases> ();
	public static Vector <Mails> mailsVector = new Vector <Mails> ();
	public static Vector <Persons> personsVector = new Vector <Persons> ();
	public static Vector <Threads> threadsVector = new Vector <Threads> ();
	public static Vector <TicketMails> ticketMailsVector = new Vector <TicketMails> ();
	
	/**
	 * @param args
	 */
	public static void main(String[] args)
	{
		// Initiate connection with the database
		String url = "jdbc:postgresql://localhost";
		Properties props = new Properties();
		props.setProperty("user", "TODO");
		props.setProperty("password","TODO");
		props.setProperty("ssl","true");
		Connection conn;
		
		try 
		{
			conn = DriverManager.getConnection(url, props);
		
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
			    Mails m = new Mails (rs.getInt(1), rs.getInt(2), rs.getDate(3), rs.getInt(4), rs.getInt(5), rs.getString(6) );
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
			st = conn.createStatement();
			rs = st.executeQuery("SELECT * FROM ticketmails");
			while (rs.next()) 
			{
			    TicketMails tm = new TicketMails (rs.getInt(1), rs.getInt(2), rs.getInt(3) );
			    ticketMailsVector.add(tm);
			}
			rs.close();
			st.close();
		} 
		catch (SQLException e) 
		{
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		// Perform core-periphery analysis on the data structures
		
		// TODO!!!!!!!!!!!!
		
	}

}
