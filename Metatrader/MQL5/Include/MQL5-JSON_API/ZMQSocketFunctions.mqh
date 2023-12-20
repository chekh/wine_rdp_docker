//+------------------------------------------------------------------+
//|                                           ZMQSocketFunctions.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"


//+------------------------------------------------------------------+
//| Init ZMQ sockets to ports                                        |
//+------------------------------------------------------------------+
void InitSockets()
{

   sysSocket.setLinger(1000);
   dataSocket.setLinger(1000);
   streamSocket.setLinger(1000);

// Number of messages to buffer in RAM.
   sysSocket.setSendHighWaterMark(1000);
   dataSocket.setSendHighWaterMark(1000);
   streamSocket.setSendHighWaterMark(1000);
}


//+------------------------------------------------------------------+
//| Bind ZMQ sockets to ports                                        |
//+------------------------------------------------------------------+
bool BindSockets()
  {
  
   if(!sysSocket.bind(StringFormat("tcp://%s:%d", HOST, SYS_PORT)))
      return false;
   else
      Print("Bound `System` socket on port ", SYS_PORT);

   if(!dataSocket.bind(StringFormat("tcp://%s:%d", HOST, DATA_PORT)))
      return false;
   else
      Print("Bound `Data` socket on port ", DATA_PORT);

   if(!streamSocket.bind(StringFormat("tcp://%s:%d", HOST, STREAM_PORT)))
      return false;
   else
      Print("Bound `Stream` socket on port ", STREAM_PORT);

// All ports bound
   return true;
  }

//+------------------------------------------------------------------+
//| Close ZMQ sockets                                                |
//+------------------------------------------------------------------+
void CloseSockets()
  {
   Print("Closing `System` socket on port ", SYS_PORT, "...");
   sysSocket.close(StringFormat("tcp://%s:%d", HOST, SYS_PORT));
   Print("Closing `Data` socket on port ", DATA_PORT, "...");
   dataSocket.close(StringFormat("tcp://%s:%d", HOST, DATA_PORT));
   Print("Closing `Stream` socket on port ", STREAM_PORT, "...");
   streamSocket.close(StringFormat("tcp://%s:%d", HOST, STREAM_PORT));
  }

//+------------------------------------------------------------------+
//| Unbind ZMQ sockets from ports                                    |
//+------------------------------------------------------------------+
void UnBindSockets()
  {
   Print("Unbinding `System` socket on port ", SYS_PORT, "...");
   sysSocket.unbind(StringFormat("tcp://%s:%d", HOST, SYS_PORT));
   Print("Unbinding `Data` socket on port ", DATA_PORT, "...");
   dataSocket.unbind(StringFormat("tcp://%s:%d", HOST, DATA_PORT));
   Print("Unbinding `Stream` socket on port ", STREAM_PORT, "...");
   streamSocket.unbind(StringFormat("tcp://%s:%d", HOST, STREAM_PORT));
  }

//+------------------------------------------------------------------+
//| Generate standard header                                         |
//+------------------------------------------------------------------+
void UpdateHeader(CJAVal &header)
  {

    string header_uuid  = header["uuid"].ToStr();
    header["time"].Set(GetServerTimeInfoMsc());
    header["uuid"]      = StringLen(header_uuid) > 0 ? header_uuid : uuid4();
    header["server"]    = AccountInfoString(ACCOUNT_SERVER);
    header["account"]   = AccountInfoInteger(ACCOUNT_LOGIN);
  }

//+------------------------------------------------------------------+
//| Publish Message to Client via socket                             |
//+------------------------------------------------------------------+
void PublishToSocket(Socket &workingSocket, CJAVal &header, CJAVal &payload)
  {

   string replyMessage;
   string debugMessage;
   CJAVal data;

   UpdateHeader(header);
   data["header"].Set(header);
   data["payload"].Set(payload);
   string topic = data["header"]["topic"].ToStr();

   replyMessage = topic != "" ? topic + " " + data.Serialize(): data.Serialize();

   if (topic != "")
      PrintDebug(topic + ", " + data["header"]["state"].ToStr() + ", " + payload.Serialize());
//   PrintDebug("Published message: " + replyMessage);
   
// non-blocking
   workingSocket.send(replyMessage, true);
   mControl.mResetLastError();

  }

//+------------------------------------------------------------------+
