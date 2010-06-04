package dsd.spring2010.analysis.ds;

import java.util.Date;

public class Mails 
{
	// Private Attributes
	private int id;
	private int thread;
	private Date tStamp;
	private int sender;
	private int reply;
	private int key;
	private String message;
	
	public Mails(int key, int thread, java.sql.Date tStamp, int sender, int reply, int id, String message) 
	{
		super();
		this.key = key;
		this.thread = thread;
		this.tStamp = tStamp;
		this.sender = sender;
		this.reply = reply;
		this.id = id;
		this.message = message;
	}

	public int getKey() {
		return key;
	}

	public void setKey(int key) {
		this.key = key;
	}

	public int getThread() {
		return thread;
	}

	public void setThread(int thread) {
		this.thread = thread;
	}

	public Date gettStamp() {
		return tStamp;
	}

	public void settStamp(Date tStamp) {
		this.tStamp = tStamp;
	}

	public int getSender() {
		return sender;
	}

	public void setSender(int sender) {
		this.sender = sender;
	}

	public int getReply() {
		return reply;
	}

	public void setReply(int reply) {
		this.reply = reply;
	}
	
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	@Override
	public String toString() {
		return "Mails [key=" + key + ", message=" + message + ", reply=" + reply
				+ ", sender=" + sender + ", tStamp=" + tStamp + ", key=" + key + ", thread="
				+ thread + "]";
	}
}
