package dsd.spring2010.analysis.ds;

public class Persons 
{
	// Private Attributes
	private int id;
	private String fName;
	private String lName;
	
	public Persons(int id, String fName, String lName) 
	{
		super();
		this.id = id;
		this.fName = fName;
		this.lName = lName;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getfName() {
		return fName;
	}

	public void setfName(String fName) {
		this.fName = fName;
	}

	public String getlName() {
		return lName;
	}

	public void setlName(String lName) {
		this.lName = lName;
	}

	@Override
	public String toString() {
		return "Persons [fName=" + fName + ", id=" + id + ", lName=" + lName
				+ "]";
	}
}
