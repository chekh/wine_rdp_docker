//+------------------------------------------------------------------+
//|                                                   MarketData.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

int stateMessCounter = 0;

//+------------------------------------------------------------------+
//| State to subscribers                                             |
//+------------------------------------------------------------------+
void StateToSubscribers()
  {
// PUB/SUB to stream current state
   CJAVal data, header;
   header["topic"] = (string) "StateInfo";
   header["type"]  = (string) "stream";

   if(TerminalInfoInteger(TERMINAL_CONNECTED))
      header["state"] = (string) "CONNECTED";
   else
      header["state"] = (string) "DISCONNECTED";

   data["mess_id"] = (string) stateMessCounter;
   stateMessCounter += 1;

//   data["time"] = (string) time;
   data["uptime"] = (string) TimeFromStart();

//   Print(data.Serialize());
   PublishToSocket(streamSocket, header, data);
  }


//+------------------------------------------------------------------+
//| Stream live price data                                           |
//+------------------------------------------------------------------+
void StreamPriceData()
  {
// If liveStream == true, push last candle to liveSocket.
   if(liveStream)
     {
      CJAVal last, header;
      header["topic"] = (string) "MarketData";
      header["type"]  = (string) "stream";

      if(TerminalInfoInteger(TERMINAL_CONNECTED))
        {
         connectedFlag=true;
         header["state"] = (string) "CONNECTED";

         for(int i=0; i<symbolSubscriptionCount; i++)
           {
            string   symbol               = symbolSubscriptions[i].symbol;
            string   chartTF              = symbolSubscriptions[i].chartTf;
            datetime lastBar              = symbolSubscriptions[i].lastBar;
            bool     stream               = symbolSubscriptions[i].stream;
            bool     stream_acc_info      = symbolSubscriptions[i].stream_acc_info;

            CJAVal Data;
            ENUM_TIMEFRAMES period        = GetTimeframe(chartTF);

            datetime thisBar = 0;
            MqlTick  tick;
            MqlRates rates[1];
            int      spread[1];
            string   dataType;

            if(chartTF == "TICK")
              {
               if(SymbolInfoTick(symbol, tick) !=true) { /*mControl.Check();*/ }
               thisBar = (datetime) tick.time_msc;
              }
            else
              {
               if(CopyRates(symbol,period,1,1,rates)!=1) { /*mControl.Check();*/ }
               if(CopySpread(symbol,period,1,1,spread)!=1) { /*mControl.Check();*/; }
               thisBar = (datetime) rates[0].time;
              }

            if(lastBar!=thisBar)
              {
               if(lastBar!=0)  // skip first price data after startup/reset
                 {
                  if(chartTF == "TICK")
                    {
                     dataType = "Tick";
                     Data[0] = (long)    tick.time_msc;
                     Data[1] = (double)  tick.bid;
                     Data[2] = (double)  tick.ask;;
                    }
                  else
                    {
                     dataType = "Bar";
                     Data[0] = (long)   rates[0].time;
                     Data[1] = (double) rates[0].open;
                     Data[2] = (double) rates[0].high;
                     Data[3] = (double) rates[0].low;
                     Data[4] = (double) rates[0].close;
                     Data[5] = (double) rates[0].tick_volume;
                     Data[6] = (int)   spread[0];
                     Data[7] = (double) rates[0].real_volume;
                    }
                  last["data_type"] = (string) dataType;
                  last["symbol"]    = (string) symbol;
                  last["timeframe"] = (string) chartTF;
                  last["market_data"].Set(Data);

                  if(stream)
                     PublishToSocket(streamSocket, header, last);

                  if(stream_acc_info)
                     justUpdatedPrice = true;

                 }
               symbolSubscriptions[i].lastBar = thisBar;
              }
           }
        }
      else
        {
         // send disconnect message only once
         if(connectedFlag)
           {
            header["state"] = (string) "DISCONNECTED";
            PublishToSocket(streamSocket, header, last);
            connectedFlag=false;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Stream Account or Balance info                                   |
//+------------------------------------------------------------------+
void StreamAccountInfo()
  {
   string topic = "AccountInfo";
   CJAVal data, header;

   header["type"]   = (string) "stream";

   if(TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      connectedFlag=true;
      header["state"] = (string) "CONNECTED";
      header["topic"]  = streamBalanceInfoOnly ? "BalanceInfo": "AccountInfo";
      if(streamAccountInfo && justUpdatedPrice)
        {
         data = streamBalanceInfoOnly ? GetBalanceInfo(): GetAccountInfo();
         PublishToSocket(streamSocket, header, data);

         StreamPositionsOnTradeEvents();
         justUpdatedPrice = false;
        }
      else
         if(justUpdatedPrice)
           {
            PublishToSocket(streamSocket, header, data);
            StreamPositionsOnTradeEvents();
            justUpdatedPrice = false;
           }
     }
   else
     {
      // send disconnect message only once
      if(connectedFlag)
        {
         header["state"] = (string) "DISCONNECTED";
         header["topic"]  = streamBalanceInfoOnly ? "BalanceInfo": "AccountInfo";

         PublishToSocket(streamSocket, header, data);
         connectedFlag    = false;
        }
     }

  }


//+------------------------------------------------------------------+
//| Check Terminal State                                             |
//+------------------------------------------------------------------+
string IsTerminalConnected()
  {
   if(TerminalInfoInteger(TERMINAL_CONNECTED))
     {
      connectedFlag = true;
      return "CONNECTED";
     }
   else
     {
      connectedFlag = false;
      return "DISCONNECTED";
     }

  }

//+------------------------------------------------------------------+
//| Stream Postions on Trade Events                                  |
//+------------------------------------------------------------------+
void StreamPositionsOnTradeEvents()
  {

   CJAVal res, header;
   header["topic"]  = "Positions";
   header["type"]   = "stream";
   header["state"]  = (string) IsTerminalConnected();

   res = GetPositions();
   PublishToSocket(streamSocket, header, res);

  }


//+------------------------------------------------------------------+
//| Publish Postion update on Trade Events                           |
//+------------------------------------------------------------------+
void PublishNewPositionInfo(const MqlTradeTransaction &trans,
                            const MqlTradeRequest &request,
                            const MqlTradeResult &result)
  {

       CJAVal res, header;
       CPositionInfo myposition;
       CJAVal data, position, error;
       ENUM_DEAL_ENTRY deal = (ENUM_DEAL_ENTRY) HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

       if (deal == DEAL_ENTRY_IN)
        {
           header["topic"]  = "Positions";
           header["type"]   = "stream";
           header["state"]  = (string) IsTerminalConnected();

           res = GetPositionInfo(trans.position, position, error);
           PublishToSocket(streamSocket, header, res);
        }
  }

//+------------------------------------------------------------------+
//| Stream Trade Events                                              |
//+------------------------------------------------------------------+
void StreamTradeTransactionEvents(const MqlTradeTransaction &trans,
                                  const MqlTradeRequest &request,
                                  const MqlTradeResult &result)
  {

   CJAVal transactionResult, header;
   bool res;

   header["topic"]  = "TradeTransaction";
   header["type"]   = "stream";
   header["state"]  = (string) IsTerminalConnected();

   res = GetTradeTransaction(transactionResult, trans, request, result);
   if(res)
     {
      PublishToSocket(streamSocket, header, transactionResult);

      if (trans.type == TRADE_TRANSACTION_ORDER_ADD && result.retcode == TRADE_RETCODE_DONE)
        {
            PublishNewPositionInfo(trans, request, result);
        }
     }

  }
//+------------------------------------------------------------------+
