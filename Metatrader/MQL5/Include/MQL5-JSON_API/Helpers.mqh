//+------------------------------------------------------------------+
//|                                                      Helpers.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"


//+------------------------------------------------------------------+
//| Get current time                                                |
//+------------------------------------------------------------------+
CJAVal GetServerTimeInfo()
  {
   CJAVal data;

   datetime localTime   = TimeLocal();
   datetime serverTime  = TimeTradeServer();
   datetime gmtTime     = TimeGMT();

   data["local_time"]   = (string)localTime;
   data["server_time"]  = (string)serverTime;
   data["gmt_time"]     = (string)gmtTime;

   return data;
  }

//+------------------------------------------------------------------+
//| Get current time in millisonds                                               |
//+------------------------------------------------------------------+
CJAVal GetServerTimeInfoMsc()
  {
   CJAVal data;

   double localTime     = ((double)((ulong) TimeLocal()*1000 + (ulong) GetTickCount() % 1000) / 1000);
   double serverTime    = ((double)((ulong) TimeTradeServer()*1000 + (ulong) GetTickCount() % 1000) / 1000);
   double gmtTime       = ((double)((ulong) TimeGMT()*1000 + (ulong) GetTickCount() % 1000) / 1000);
   double currentTime   = ((double)((ulong) TimeCurrent()*1000 + (ulong) GetTickCount() % 1000) / 1000);

   data["local_time"]   = (string)localTime;
   data["server_time"]  = (string)serverTime;
   data["gmt_time"]     = (string)gmtTime;
   data["current_time"] = (string)currentTime;

   return data;
  }

//+------------------------------------------------------------------+
//| Return duration from start as string                               |
//+------------------------------------------------------------------+
string TimeFromStart()
{
    int durationInSeconds = TimeCurrent() - startTime;

    int days = durationInSeconds / 86400; // 86400 seconds in a day
    int hours = (durationInSeconds % 86400) / 3600;
    int minutes = (durationInSeconds % 3600) / 60;
    int seconds = durationInSeconds % 60;

    string durationString = StringFormat("%02d, %02d:%02d:%02d", days, hours, minutes, seconds);

    return durationString;

}


//+------------------------------------------------------------------+
//| Trade confirmation                                               |
//+------------------------------------------------------------------+
CJAVal OrderDoneOrError(bool error, string funcName, CTrade &trade)
  {

   if(error)
      ExplainError(trade);

   CJAVal data;

   data["error"]       = (bool)   error;
   data["retcode"]     = (long)   trade.ResultRetcode();
   data["description"] = (string) GetRetcodeID(trade.ResultRetcode());
   data["deal"]        = (long)   trade.ResultDeal();
   data["order_type"]  = (string) trade.RequestTypeDescription();
   data["order"]       = (long)   trade.ResultOrder();
   data["volume"]      = (double) trade.ResultVolume();
   data["price"]       = (double) trade.ResultPrice();
   data["bid"]         = (double) trade.ResultBid();
   data["ask"]         = (double) trade.ResultAsk();
   data["sl"]          = (double) trade.RequestSL();
   data["tp"]          = (double) trade.RequestTP();
   data["function"]    = (string) funcName;

   return data;
  }

//+------------------------------------------------------------------+
//| Error reporting                                                  |
//+------------------------------------------------------------------+
CJAVal CheckError(string funcName)
  {
   int lastError = mControl.mGetLastError();
   if(lastError)
     {
      string desc = mControl.mGetDesc();
      PrintDebug("Error handling source: " + funcName + " description: " + desc);
      mControl.Check();
      return ActionDoneOrError(lastError, funcName, desc);
     }
   else
      return ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, "NO_ERRORS");
  }

//+------------------------------------------------------------------+
//| Action confirmation                                              |
//+------------------------------------------------------------------+
CJAVal ActionDoneOrError(int lastError, string funcName, string desc)
  {

   CJAVal data, resp;

   resp["error"]       = lastError == 0 ? (bool) false: (bool) true;
   data["lastError"]   = (string) lastError;
   data["description"] = (string) desc;
   data["function"]    = (string) funcName;

   resp["execution_result"].Set(data);
   PrintDebug("ActionDoneOrError: " + resp.Serialize());

   return resp;
  }

//+------------------------------------------------------------------+
//| Print message if debug mode on                                   |
//+------------------------------------------------------------------+
void PrintDebug(string message)
  {
   if(debug)
      Print(message);
  }

//+------------------------------------------------------------------+
//| Check if subscribed to symbol and timeframe combination          |
//+------------------------------------------------------------------+
bool HasChartSymbol(string symbol, string chartTF)
  {
   for(int i=0; i<ArraySize(symbolSubscriptions); i++)
     {
      if(symbolSubscriptions[i].symbol == symbol && symbolSubscriptions[i].chartTf == chartTF)
        {
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Description for some error reasons                               |
//+------------------------------------------------------------------+
void ExplainError(CTrade &trade)
  {

   uint answer=trade.ResultRetcode();

   switch(answer)
     {
      case 10004:
        {
         Print("TRADE_RETCODE_REQUOTE");
         Print("request.price = ",trade.RequestPrice(),"   result.ask = ",
               trade.ResultAsk()," result.bid = ",trade.ResultBid());
         break;
        }
      case 10006:
        {
         Print("TRADE_RETCODE_REJECT");
         Print("request.price = ",trade.RequestPrice(),"   result.ask = ",
               trade.ResultAsk()," result.bid = ",trade.ResultBid());
         break;
        }
      case 10015:
        {
         Print("TRADE_RETCODE_INVALID_PRICE");
         Print("request.price = ",trade.RequestPrice(),"   result.ask = ",
               trade.ResultAsk()," result.bid = ",trade.ResultBid());
         break;
        }
      //--- ???????????? SL ?/??? TP
      case 10016:
        {
         Print("TRADE_RETCODE_INVALID_STOPS");
         Print("request.sl = ",trade.RequestSL()," request.tp = ",trade.RequestTP());
         Print("result.ask = ",trade.ResultAsk()," result.bid = ",trade.ResultBid());
         break;
        }
      case 10014:
        {
         Print("TRADE_RETCODE_INVALID_VOLUME");
         Print("request.volume = ",trade.RequestVolume(),"   result.volume = ",
               trade.ResultVolume());
         break;
        }
      case 10019:
        {
         Print("TRADE_RETCODE_NO_MONEY");
         Print("request.volume = ",trade.RequestVolume(),"   result.volume = ",
               trade.ResultVolume(),"   result.comment = ",trade.ResultComment());
         break;
        }
      default:
        {
         Print("Other answer = ", answer);
        }
     }

  }

//+------------------------------------------------------------------+
//| Get retcode message by retcode id                                |
//+------------------------------------------------------------------+
string GetRetcodeID(int retcode)
  {

   switch(retcode)
     {
      case 10004:
         return("TRADE_RETCODE_REQUOTE");
         break;
      case 10006:
         return("TRADE_RETCODE_REJECT");
         break;
      case 10007:
         return("TRADE_RETCODE_CANCEL");
         break;
      case 10008:
         return("TRADE_RETCODE_PLACED");
         break;
      case 10009:
         return("TRADE_RETCODE_DONE");
         break;
      case 10010:
         return("TRADE_RETCODE_DONE_PARTIAL");
         break;
      case 10011:
         return("TRADE_RETCODE_ERROR");
         break;
      case 10012:
         return("TRADE_RETCODE_TIMEOUT");
         break;
      case 10013:
         return("TRADE_RETCODE_INVALID");
         break;
      case 10014:
         return("TRADE_RETCODE_INVALID_VOLUME");
         break;
      case 10015:
         return("TRADE_RETCODE_INVALID_PRICE");
         break;
      case 10016:
         return("TRADE_RETCODE_INVALID_STOPS");
         break;
      case 10017:
         return("TRADE_RETCODE_TRADE_DISABLED");
         break;
      case 10018:
         return("TRADE_RETCODE_MARKET_CLOSED");
         break;
      case 10019:
         return("TRADE_RETCODE_NO_MONEY");
         break;
      case 10020:
         return("TRADE_RETCODE_PRICE_CHANGED");
         break;
      case 10021:
         return("TRADE_RETCODE_PRICE_OFF");
         break;
      case 10022:
         return("TRADE_RETCODE_INVALID_EXPIRATION");
         break;
      case 10023:
         return("TRADE_RETCODE_ORDER_CHANGED");
         break;
      case 10024:
         return("TRADE_RETCODE_TOO_MANY_REQUESTS");
         break;
      case 10025:
         return("TRADE_RETCODE_NO_CHANGES");
         break;
      case 10026:
         return("TRADE_RETCODE_SERVER_DISABLES_AT");
         break;
      case 10027:
         return("TRADE_RETCODE_CLIENT_DISABLES_AT");
         break;
      case 10028:
         return("TRADE_RETCODE_LOCKED");
         break;
      case 10029:
         return("TRADE_RETCODE_FROZEN");
         break;
      case 10030:
         return("TRADE_RETCODE_INVALID_FILL");
         break;
      case 10031:
         return("TRADE_RETCODE_CONNECTION");
         break;
      case 10032:
         return("TRADE_RETCODE_ONLY_REAL");
         break;
      case 10033:
         return("TRADE_RETCODE_LIMIT_ORDERS");
         break;
      case 10034:
         return("TRADE_RETCODE_LIMIT_VOLUME");
         break;
      case 10035:
         return("TRADE_RETCODE_INVALID_ORDER");
         break;
      case 10036:
         return("TRADE_RETCODE_POSITION_CLOSED");
         break;
      case 10038:
         return("TRADE_RETCODE_INVALID_CLOSE_VOLUME");
         break;
      case 10039:
         return("TRADE_RETCODE_CLOSE_ORDER_EXIST");
         break;
      case 10040:
         return("TRADE_RETCODE_LIMIT_POSITIONS");
         break;
      case 10041:
         return("TRADE_RETCODE_REJECT_CANCEL");
         break;
      case 10042:
         return("TRADE_RETCODE_LONG_ONLY");
         break;
      case 10043:
         return("TRADE_RETCODE_SHORT_ONLY");
         break;
      case 10044:
         return("TRADE_RETCODE_CLOSE_ONLY");
         break;

      default:
         return("TRADE_RETCODE_UNKNOWN="+IntegerToString(retcode));
         break;
     }
  }

//+------------------------------------------------------------------+
//| Get error message by error id                                    |
//+------------------------------------------------------------------+
string GetErrorID(int error)
  {

   switch(error)
     {
      // Custom errors
      case 65537:
         return("ERR_DESERIALIZATION");
         break;
      case 65538:
         return("ERR_WRONG_ACTION");
         break;
      case 65539:
         return("ERR_WRONG_ACTION_TYPE");
         break;
      case 65540:
         return("ERR_CLEAR_SUBSCRIPTIONS_FAILED");
         break;
      case 65541:
         return("ERR_RETRIEVE_DATA_FAILED");
         break;
      case 65542:
         return("ERR_CVS_FILE_CREATION_FAILED");
         break;
      case 65543:
         return("ERR_WRONG_ORDER_TYPE");
         break;
      case 65544:
         return("ERR_WRONG_ACCOUNT_CREDENTIALS");
         break;
      case 65545:
         return("ERR_WRONG_POSITION_TICKET_NUMBER");
         break;

      default:
         return("ERR_CODE_UNKNOWN="+IntegerToString(error));
         break;
     }
  }

//+------------------------------------------------------------------+
//| Return a textual description of the deinitialization reason code |
//+------------------------------------------------------------------+
string getUninitReasonText(int reasonCode)
  {
   string text="";
//---
   switch(reasonCode)
     {
      case REASON_ACCOUNT:
         text="Account was changed";
         break;
      case REASON_CHARTCHANGE:
         text="Symbol or timeframe was changed";
         break;
      case REASON_CHARTCLOSE:
         text="Chart was closed";
         break;
      case REASON_PARAMETERS:
         text="Input-parameter was changed";
         break;
      case REASON_RECOMPILE:
         text="Program "+__FILE__+" was recompiled";
         break;
      case REASON_REMOVE:
         text="Program "+__FILE__+" was removed from chart";
         break;
      case REASON_TEMPLATE:
         text="New template was applied to chart";
         break;
      default:
         text="Another reason";
     }
//---
   return text;
  }
//+------------------------------------------------------------------+
