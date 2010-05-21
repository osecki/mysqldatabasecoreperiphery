package dsd.spring2010.analysis.ds;

public class Threads
{
	// Private Attributes
	private int key;
	private String subject;
	
	public Threads(int key, String subject) 
	{
		super();
		this.key = key;
		this.subject = subject;
	}

	public int getKey() {
		return key;
	}

	public void setKey(int key) {
		this.key = key;
	}

	public String getSubject() {
		return subject;
	}

	public void setSubject(String subject) {
		this.subject = subject;
	}

	@Override
	public String toString() {
		return "Threads [key=" + key + ", subject=" + subject + "]";
	}
}
