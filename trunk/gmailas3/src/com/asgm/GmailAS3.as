package com.walta.asgm
{	
	import com.hurlant.crypto.hash.MD5;
	import com.hurlant.crypto.tls.TLSSocket;
	import com.hurlant.util.Base64;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	public class GmailAS3 extends TLSSocket
	{
		public static const EMAIL_SEND_SUCCESS:String			= "email-send-success";
		
		public static const SERVER:String						= "smtp.gmail.com";
		public static const PORT:int							= 465;
		
		private static const ENDLINE:String			= "\r\n";
	
		private var stanzas:Array					= new Array;						
		private var stanzaNumber:int				= 0;
		
		private var username:String;
		private var password:String;
		private var rcptEmailAddress:String;
		private var subject:String;
		private var message:String;
		private var displayName:String;
		
		private var md5:MD5 						= new MD5;
		
		public function GmailAS3()
		{
			this.addEventListener(ProgressEvent.SOCKET_DATA, handleSocketData);
		}
		
		public function sendEmail(username:String, password:String, displayName:String, rcptEmailAddress:String, subject:String, message:String):void{
			this.connect(SERVER, PORT);
			
			this.username = username;
			this.password = password;
			this.rcptEmailAddress = rcptEmailAddress;
			this.subject = subject;
			this.message = message;
			this.displayName = displayName;
			
			stanzaNumber = 0;
			buildStanzas();
			
			writeUTFBytes("EHLO " + SERVER + ENDLINE);
			writeUTFBytes("AUTH LOGIN" + ENDLINE);
		}

		private function handleSocketData(evt:ProgressEvent):void{
			var data:String = readUTFBytes(bytesAvailable);
			
			trace(data);
			
			if(data.indexOf(Base64.encode("Username:")) != -1){
   				writeUTFBytes (Base64.encode(username)+ENDLINE);
   			}
   				
   			if(data.indexOf(Base64.encode("Password:")) != -1){
   				writeUTFBytes (Base64.encode(password)+ENDLINE);
   			}
   				
   			if(data.indexOf("235") != -1){
   				trace("Logged in");
   				writeUTFBytes (stanzas[stanzaNumber]);
   			}
   				
   			if(data.indexOf("OK") != -1){
   				stanzaNumber++;
   				if(stanzas[stanzaNumber] != null){
   					writeUTFBytes (stanzas[stanzaNumber]);
   				}else{
   					dispatchEvent(new Event(EMAIL_SEND_SUCCESS));
   				}
   			}
   				
   			if(data.indexOf("354") != -1){
   				trace("Begin writing in the data part");
   				writeUTFBytes (getEmailData());
   				writeUTFBytes ("." + ENDLINE);
   			}
		}
		
		private function getEmailData():String{
			//var boundry:String = md5.hash(ByteArray(getTimer()));
			
			var emailMessage:String 			= "From: " + this.displayName + " <" + this.username + "> " + ENDLINE;
							emailMessage 		+= "To: " + this.rcptEmailAddress + ENDLINE;
							emailMessage		+= "Date: " + new Date().toString() + ENDLINE;
							emailMessage		+= "Subject: " + this.subject + ENDLINE;
							emailMessage		+= "Mime-Version: 1.0" + ENDLINE;
							
							emailMessage		+= message + ENDLINE;
							
							
			return emailMessage;
		}
		
		private function buildStanzas():void{
			stanzas.splice(0, stanzas.length);
			
			stanzas.push("MAIL FROM: <" + username + ">" + ENDLINE);
			stanzas.push("RCPT TO: <" + rcptEmailAddress + ">" + ENDLINE);
			stanzas.push("DATA" + ENDLINE);
		}
	}
}