//+------------------------------------------------------------------+
//|                                                  AccountInfo.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

#include <MQL5-JSON_API/Commands.mqh>
//+------------------------------------------------------------------+
//| Account information                                              |
//+------------------------------------------------------------------+
CJAVal AccountInfo(CommandRequest &command)
  {

    string message;

    switch(command.action_type)
     {
      case UNDEFINED:
         return GetAccountInfo();

      case STREAM_ON:
         streamAccountInfo = true;
         message = "Streaming Account Info On.";
         break;
      case STREAM_OFF:
         streamAccountInfo = false;
         message = "Streaming Account Info Off.";
         break;
      case STREAM_BALANCE_ONLY:
         streamBalanceInfoOnly = true;
         message = "Streaming Balance Only as Account Info.";
         break;
      case STREAM_FULL_DATA:
         streamBalanceInfoOnly = false;
         message = "Streaming Full Data of Account Info.";
         break;
      default:
         break;
     }

    return ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, message);
  }

//+------------------------------------------------------------------+
//| Account information                                              |
//+------------------------------------------------------------------+
CJAVal GetAccountInfo()
  {
    CJAVal data;

    data["broker"]          = AccountInfoString(ACCOUNT_COMPANY);
    data["currency"]        = AccountInfoString(ACCOUNT_CURRENCY);
    data["server"]          = AccountInfoString(ACCOUNT_SERVER);
    data["account"]         = AccountInfoInteger(ACCOUNT_LOGIN);
    data["trading_allowed"] = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
    data["bot_trading"]     = AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
    data["balance"]         = AccountInfoDouble(ACCOUNT_BALANCE);
    data["equity"]          = AccountInfoDouble(ACCOUNT_EQUITY);
    data["profit"]          = AccountInfoDouble(ACCOUNT_PROFIT);
    data["margin"]          = AccountInfoDouble(ACCOUNT_MARGIN);
    data["margin_free"]     = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    data["margin_level"]    = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

    return data;
  }

//+------------------------------------------------------------------+
//| Balance information                                              |
//+------------------------------------------------------------------+
CJAVal GetBalanceInfo()
  {

   CJAVal data;

   data["balance"]      = AccountInfoDouble(ACCOUNT_BALANCE);
   data["equity"]       = AccountInfoDouble(ACCOUNT_EQUITY);
   data["profit"]       = AccountInfoDouble(ACCOUNT_PROFIT);
   data["margin"]       = AccountInfoDouble(ACCOUNT_MARGIN);
   data["margin_free"]  = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   return data;
  }

//+------------------------------------------------------------------+
