/**
 * Jordan Osecki
 */
package dsd.spring2010.analysis;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.sql.*;
import java.util.Collections;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.Set;
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
	
	public static Hashtable<String, Integer> edges = new Hashtable<String, Integer>();
	
	/**
	 * @param args
	 */
	public static void main(String[] args)
	{
		System.out.println("Test");
		
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
		
		// Build Data Structure Needed to print
		int n = 0;
		String releaseDate = "2008-03-01";
		String releaseDatePrevious = "2008-01-01";
		Vector<Integer> nSeen = new Vector<Integer>();
		for (int i = 0; i < mailsVector.size(); i++)
		{
			if ( mailsVector.elementAt(i).getReply() != -1 
					&& mailsVector.elementAt(i).gettStamp().before(java.sql.Date.valueOf( releaseDate )) 
					&& mailsVector.elementAt(i).gettStamp().after(java.sql.Date.valueOf( releaseDatePrevious )) )
			{
				// Make New Edge
				addToHashEdgeTable(mailsVector.elementAt(i).getSender(), mailsVector.elementAt(i).getReply());
				
				// Update N
				if ( ! nSeen.contains(mailsVector.elementAt(i).getSender()) )
				{
					n++;
					nSeen.add(mailsVector.elementAt(i).getSender());
				}
				if ( ! nSeen.contains(mailsVector.elementAt(i).getReply()) )
				{
					n++;
					nSeen.add(mailsVector.elementAt(i).getReply());
				}
			}
		}
		
		// Begin to write file for UCINET
		try
		{
		    // Create file 
		    FileWriter fstream = new FileWriter("MYSQL-UCINET-" + releaseDate + ".txt");
		    BufferedWriter out = new BufferedWriter(fstream);
		    
		    // Write out to the file in the format that UCINET expects
		    
		    // Header Info
		    out.write("dl n = " + n + " format = edgelist1\n");
		    out.write("labels embedded\n");
		    out.write("data:\n");
		    
		    // Actual Edges
		    //Set<String> set = edges.keySet();
		    //Iterator<String> itr = set.iterator();
		    
		    // Iterate through all of the edges printing them
		    Vector<String> tempToSort = new Vector<String>(edges.keySet());
		    Collections.sort(tempToSort);
		    for (int j = 0; j < tempToSort.size(); j++)
		    {
		    	out.write(tempToSort.elementAt(j).substring(0, tempToSort.elementAt(j).indexOf("->")) + " " + tempToSort.elementAt(j).substring(tempToSort.elementAt(j).indexOf("->") + 2) + " ");
		    	out.write(edges.get(tempToSort.elementAt(j)) + "\n");
		    }
		   
		    // Close the output stream
		    out.close();
		}
		catch (Exception e)
		{
			// Catch exception if any
		    System.err.println("Error: " + e.getMessage());
		}	
	}

	private static void addToHashEdgeTable(int p1, int p2)
	{
		String testKey = p1 + "->" + p2;
		
		// Check if the entry exists or not
		if ( edges.containsKey(testKey) )
		{
			int temp = edges.get(testKey);
			temp += 1;
			edges.put(p1 + "->" + p2, temp);
		}
		else
		{
			edges.put(p1 + "->" + p2, 1);
		}		
	}
}
