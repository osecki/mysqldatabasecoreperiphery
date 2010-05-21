package dsd.spring2010.analysis.ds;

public class Persons 
{
	// Private Attributes
	private int key;
	private String fName;
	private String lName;
	
	public Persons(int key, String fName, String lName) 
	{
		super();
		this.key = key;
		this.fName = fName;
		this.lName = lName;
	}

	public int getKey() {
		return key;
	}

	public void setKey(int key) {
		this.key = key;
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
		return "Persons [fName=" + fName + ", key=" + key + ", lName=" + lName
				+ "]";
	}
}
