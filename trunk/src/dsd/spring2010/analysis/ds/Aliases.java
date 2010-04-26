package dsd.spring2010.analysis.ds;

public class Aliases 
{
	// Private Attributes
	private int id;
	private int person;
	private String name;
	
	public Aliases(int id, int person, String name) 
	{
		super();
		this.id = id;
		this.person = person;
		this.name = name;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
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
		return "Aliases [id=" + id + ", name=" + name + ", person=" + person
				+ "]";
	}
}
