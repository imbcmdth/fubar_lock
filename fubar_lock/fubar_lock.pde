#include <Ethernet.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 10, 0, 0, 177 };
byte server_ip[] = { 8, 12, 42, 228 }; // stackulator.com
char server_name[] = "stackulator.com";// 8.12.42.228

Client client(server_ip, 80);

void setup() {
  Serial.begin(9600);                                 // connect to the serial port

  // int initial_count =  fetchWithNothing();
  // TODO: Setup 7-segment LED display with initial_count
}

void loop () {
  byte val = 0;
  byte code[6];
  byte checksum = 0;
  byte bytesread = 0;
  byte tempbyte = 0;
  int code_count = 0;

  if(Serial.available() > 0) {
    if((val = Serial.read()) == 2) {                  // check for header 
      bytesread = 0; 
      while (bytesread < 12) {                        // read 10 digit code + 2 digit checksum
        if( Serial.available() > 0) { 
          val = Serial.read();
          if((val == 0x0D)||(val == 0x0A)||(val == 0x03)||(val == 0x02)) { // if header or stop bytes before the 10 digit reading 
            break;                                    // stop reading
          }

          // Do Ascii/Hex conversion:
          if ((val >= '0') && (val <= '9')) {
            val = val - '0';
          } else if ((val >= 'A') && (val <= 'F')) {
            val = 10 + val - 'A';
          }

          // Every two hex-digits, add byte to code:
          if (bytesread & 1 == 1) {
            // make some space for this hex-digit by
            // shifting the previous hex-digit with 4 bits to the left:
            code[bytesread >> 1] = (val | (tempbyte << 4));

            if (bytesread >> 1 != 5) {                // If we're at the checksum byte,
              checksum ^= code[bytesread >> 1];       // Calculate the checksum... (XOR)
            }
          } else {
            tempbyte = val;                           // Store the first hex digit first...
          }

          bytesread++;                                // ready to read next digit
        } 
      } 

      // Output to Serial:

      if (bytesread == 12) {                          // if 12 digit read is complete
        code_count = fetchWithRFID(code);
        Serial.print("Active RFID count: ");
        Serial.print(code_count);
        Serial.println();
      // TODO: Set 7-segment LED display to code_count
      }
    }
  }
}

int fetchWithRFID(byte *code){
  byte i = 0;
  Serial.println("connecting...");
  
  if (client.connect()) {
    Serial.println("connected");
    client.print("GET /fubar/fubar.php?rfid=");
    for (i=0; i<5; i++) {
      if (code[i] < 16) client.print("0");
      client.print(code[i], HEX);
    }
    client.println(" HTTP/1.1");
    client.print("Host: ");
    client.println(server_name);
    client.println();
  } else {
    Serial.println("connection failed");
  }
  Serial.println();

  return getCountFromResponse();  
}

int fetchWithNothing(){
  Serial.println("connecting...");
  
  if (client.connect()) {
    Serial.println("connected");
    client.println("GET /fubar/fubar.php HTTP/1.1");
    client.print("Host: ");
    client.println(server_name);
    client.println();
  } else {
    Serial.println("connection failed");
  }
  Serial.println();
  
  return getCountFromResponse();  
}

int getCountFromResponse(){
  int code_count = 0;
  while(true) {
    if (client.available()) {
      char c = client.read();
      if(c == ':') { // The last ':' should be part of 'Content:' and everything after that should be numbers or whitespace
        code_count = 0;
      }  else if ((c >= '0') && (c <= '9')) {
        code_count = (code_count * 10) + (c - '0');
      }
      continue;
    }
    
    if (!client.connected()) {
      Serial.println("disconnecting.");
      client.stop();
      return code_count;
    }
  }  
}
