package dsd.spring2010.analysis.ds;

public class TicketMails 
{
	// Private Attributes
	private int id;
	private int thread;
	private int ticket;
	
	public TicketMails(int id, int thread, int ticket) {
		super();
		this.id = id;
		this.thread = thread;
		this.ticket = ticket;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getThread() {
		return thread;
	}

	public void setThread(int thread) {
		this.thread = thread;
	}

	public int getTicket() {
		return ticket;
	}

	public void setTicket(int ticket) {
		this.ticket = ticket;
	}

	@Override
	public String toString() {
		return "TicketMails [id=" + id + ", thread=" + thread + ", ticket="
				+ ticket + "]";
	}
}
