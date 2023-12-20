//+------------------------------------------------------------------+
//|                                                Configuration.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"


//+------------------------------------------------------------------+
//| Reconfigure the script params                                    |
//+------------------------------------------------------------------+
CJAVal ScriptConfiguration(CommandRequest &command)
  {
      string symbol           = command.symbol;
      string chartTF          = command.time_frame;
      bool   stream           = command.stream;
      bool   stream_acc_info  = command.stream_acc_info;

      bool is_custom_symbol   = false;
   
      if(!SymbolExist(symbol, is_custom_symbol))
      {
         SymbolSelect(symbol, true);
      }
   
      if(!HasChartSymbol(symbol, chartTF))
      {
          ArrayResize(symbolSubscriptions, symbolSubscriptionCount+1);
          symbolSubscriptions[symbolSubscriptionCount].symbol           = symbol;
          symbolSubscriptions[symbolSubscriptionCount].chartTf          = chartTF;
          symbolSubscriptions[symbolSubscriptionCount].stream           = stream;
          symbolSubscriptions[symbolSubscriptionCount].stream_acc_info  = stream_acc_info;
       // to initialze with value 0 skips the first price
          symbolSubscriptions[symbolSubscriptionCount].lastBar          = 0;
          symbolSubscriptionCount++;
   
          mControl.mResetLastError();
          SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
   
          return CheckError(__FUNCTION__);
      }
      else
      {
          return ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, "Symbol and TF are already in config");
      }
   }
   
   
//+------------------------------------------------------------------+
//| Clear symbol subscriptions and indicators                        |
//+------------------------------------------------------------------+
CJAVal ResetSubscriptions(CommandRequest &command)
  {

   ArrayFree(symbolSubscriptions);
   symbolSubscriptionCount = 0;
   bool error = false;

   return ActionDoneOrError(ERR_SUCCESS, __FUNCTION__, "Successfully reset subscriptions");
  }

//+------------------------------------------------------------------+
