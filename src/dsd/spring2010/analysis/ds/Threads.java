package dsd.spring2010.analysis.ds;

public class Threads
{
	// Private Attributes
	private int id;
	private String subject;
	
	public Threads(int id, String subject) 
	{
		super();
		this.id = id;
		this.subject = subject;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getSubject() {
		return subject;
	}

	public void setSubject(String subject) {
		this.subject = subject;
	}

	@Override
	public String toString() {
		return "Threads [id=" + id + ", subject=" + subject + "]";
	}
}
