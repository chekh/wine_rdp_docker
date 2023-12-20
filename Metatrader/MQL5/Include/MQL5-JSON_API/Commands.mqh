//+------------------------------------------------------------------+
//|                                                     Commands.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

  
//+------------------------------------------------------------------+
//| Expansion of base enum of Trade Action Type                      |
//+------------------------------------------------------------------+
#define ENUM(x) case x: return #x

enum TRADE_ACTION
  {
   UNKNOWN                    =  0,        // Undefined trade action to return error
   DEAL                       =  1,        // Place a trade order for an immediate execution with the specified parameters (market order)
   PENDING                    =  2,        // Place pending order
   POSITION_CLOSE_BY_ID       =  3,        // Close position by position_id
   POSITION_CLOSE_BY_MAGIC    =  4,        // Close all positions with particular magic
   POSITION_CLOSE_BY_SYMBOL   =  5,        // Close position by symbol, all positions on symbol will be closed
   POSITION_MODIFY            =  6,        // Modify sl, tp of position with position_id
   POSITION_REVERSE           =  7,        // Close all opened positions with particular magic and open new position in opposite direction
   POSITION_CHECK             =  8,        // Return position details by position id
   ORDER_SEND                 =  9,        // Send any order
   ORDER_MODIFY               =  10,       // Modify pending order
   ORDER_CANCEL               =  11,       // Cancel pending order
   PENDING_POSITION_CLOSE     =  12,       // Close pending position by magic
   POSITION_MODIFY_BY_MAGIC   =  13,       // Modify sl, tp of position by magic
  };


enum COMMAND_ACTION
  {
   CONFIG    = 0,
   RESET     = 1,
   TIME      = 2,
   ACCOUNT   = 3,
   BALANCE   = 4,
   POSITIONS = 5,
   ORDERS    = 6,
   HISTORY   = 7,
   TRADE     = 8
  };
  
enum COMMAND_ACTION_TYPE
  {
   UNDEFINED            = 0,
   DATA                 = 1,
   TRADES               = 2,
   STREAM_ON            = 3,
   STREAM_OFF           = 4,
   STREAM_BALANCE_ONLY  = 5,
   STREAM_FULL_DATA     = 6
  };

struct CommandRequest
  {
   string                        uuid;             // Request id
   COMMAND_ACTION                action;           // Action type to be performed by Command Processor
   COMMAND_ACTION_TYPE           action_type;      // Subtype of Command action
   TRADE_ACTION                  trade_action;     // Trade Operation action
   long                          account;          // Account Login - AccountInfoString(ACCOUNT_NAME))
   string                        server;           // Server name - AccountInfoString(ACCOUNT_NAME))
   ulong                         magic;            // Expert Advisor Id
   ulong                         order_id;         // Order ticket
   ulong                         deal_id;          // Deal ticket
   string                        symbol;           // Trader Symbol
   double                        volume;           // Requested volume for a deal in lots
   double                        price_offset;     // Price offset for pending orders
   double                        price;            // Price
   double                        stoplimit;        // StopLimit level of the order
   double                        sl;               // Stop Loss level of the order
   double                        tp;               // Take Profit level of the order
   ulong                         deviation;        // Maximal possible deviation from the requested price
   ENUM_ORDER_TYPE               order_type;       // Order type
   ENUM_ORDER_TYPE_FILLING       type_filling;     // Order expiration type
   ENUM_ORDER_TYPE_TIME          type_time;        // Order expiration time
   datetime                      expiration;       // Order expiration time (for the orders of ORDER_TIME_SPECIFIED)
   string                        comment;          // Order comment
   ulong                         position;         // Position ticket
   ulong                         position_by;      // Position ticket of an opposite position
   string                        sltp_units;       // Stop limit units "%" or "points"
   string                        time_frame;       // Time frame for marked data
   datetime                      from_date;        // From date for history request
   datetime                      to_date;          // To date for history request
   bool                          close_all;        // Close all positions or shot/long sepparatelly
   bool                          stream;           // Should stream market data or not
   bool                          stream_acc_info;  // Should stream account info on every market_data update 
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool EvaluateCommand(ZmqMsg &request, CommandRequest &command, CJAVal &error)
  {
   CJAVal msg;
   string data = request.getData();

//   PrintDebug("Processing: " + data);

   if(!msg.Deserialize(data))
     {
      mControl.mSetUserError(65537, GetErrorID(65537));
      error = CheckError(__FUNCTION__);
     }
      
   command.uuid             = (string) msg["uuid"].ToStr();
   command.action           = (COMMAND_ACTION) msg["action"].ToInt();
   command.action_type      = (COMMAND_ACTION_TYPE) msg["action_type"].ToInt();
   command.trade_action     = (TRADE_ACTION) msg["trade_action"].ToInt();
   command.close_all        = msg["close_all"].ToBool();
   command.comment          = msg["comment"].ToStr();
   command.deal_id          = msg["deal_id"].ToInt();
   command.deviation        = msg["deviation"].ToInt();
   command.expiration       = (datetime) msg["expiration"].ToDbl();
   command.from_date        = (datetime) msg["from_date"].ToDbl();
   command.magic            = (ulong) msg["magic"].ToInt();
   command.order_id         = msg["order_id"].ToInt();
   command.position         = msg["position"].ToInt();
   command.position_by      = msg["position_by"].ToInt();
   command.price            = NormalizeDouble(msg["price"].ToDbl(),_Digits);
   command.sl               = msg["sl"].ToDbl();
   command.sltp_units       = msg["sltp_units"].ToStr();
   command.stoplimit        = msg["stoplimit"].ToDbl();
   command.symbol           = msg["symbol"].ToStr();
   command.time_frame       = msg["time_frame"].ToStr();
   command.to_date          = (datetime) msg["to_date"].ToDbl();
   command.tp               = msg["tp"].ToDbl();
   command.order_type       = (ENUM_ORDER_TYPE) msg["order_type"].ToInt();
   command.type_filling     = (ENUM_ORDER_TYPE_FILLING) msg["type_filling"].ToInt();
   command.type_time        = (ENUM_ORDER_TYPE_TIME) msg["type_time"].ToInt();    // GTC, DAY, SPECIFIED, SPECIFIED_DAY
   command.volume           = msg["volume"].ToDbl();
   command.stream           = msg["stream"].ToBool();
   command.stream_acc_info  = msg["stream_acc_info"].ToBool();
   command.server           = msg["server"].ToStr();
   command.account          = (long) msg["account"].ToInt();
   
   return true;

  }
//+------------------------------------------------------------------+
//| Command request handler                                          |
//+------------------------------------------------------------------+
void RequestHandler(ZmqMsg &request)
  {
   CJAVal result, incomingMessage, conf, error, header;
   CommandRequest command;
   string resultMessage;

   ResetLastError();
// Get data from reguest
// Send response to System socket that request was received
// Some historical data requests can take a lot of time

   if(EvaluateCommand(request, command, error))
     {
      header["state"]       = (string) "OK";
      header["description"] = (string) "Command Accepted";
     }
   else
     {
      header["state"]       = (string) "Error";
      header["description"] = error["description"];
     }
   header["type"]           = (string) "reply";
   header["uuid"]           = command.uuid;
//   PrintDebug("uuid: " + header["uuid"].Serialize());
   PublishToSocket(sysSocket, header, conf);

   header["state"]       = (string) "OK";
   header["description"] = (string) "Command Executed";

   PrintDebug("Command.Action: " + EnumToString(command.action) + " " + EnumToString(command.action_type) + " " + EnumToString(command.trade_action));
   switch(command.action)
     {
      case CONFIG:
         result = ScriptConfiguration(command);
         break;
         
      case RESET:
         result = ResetSubscriptions(command);
         break;

      case TIME:
         break;

      case ACCOUNT:
         result = AccountInfo(command);
         break;

      case BALANCE:
         result = GetBalanceInfo();
         break;

      case HISTORY:
         result = HistoryInfo(command);
         break;

      case TRADE:
         result = Trader(command);
         resultMessage = result["message"].ToStr();
         break;

      case POSITIONS:
         result = GetPositions();
         break;

      case ORDERS:
         result = GetOrders();
         break;   
             
      default:
         PrintDebug("ERR_COMMAND_UNKNOWN=");
         mControl.mSetUserError(65538, GetErrorID(65538));
         result = CheckError(__FUNCTION__);
         if (result["error"])
         {
             header["state"]       = (string) "Error";
             header["description"].Set(result["execution_result"]);
         }
         break;
     }  

   resultMessage = resultMessage != StringLen(resultMessage) == 0 ? resultMessage : "Command Execution Result: " + result.Serialize();
   PrintDebug(resultMessage);
   PublishToSocket(dataSocket, header, result);
  }
//+------------------------------------------------------------------+
