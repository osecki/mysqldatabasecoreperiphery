package dsd.spring2010.analysis.ds;

public class Aliases 
{
	// Private Attributes
	private int key;
	private int person;
	private String name;
	
	public Aliases(int key, int person, String name) 
	{
		super();
		this.key = key;
		this.person = person;
		this.name = name;
	}

	public int getKey() {
		return key;
	}

	public void setKey(int key) {
		this.key = key;
	}

	public int getPerson() {
		return person;
	}

	public void setPerson(int person) {
		this.person = person;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	@Override
	public String toString() {
		return "Aliases [key=" + key + ", name=" + name + ", person=" + person
				+ "]";
	}
}
