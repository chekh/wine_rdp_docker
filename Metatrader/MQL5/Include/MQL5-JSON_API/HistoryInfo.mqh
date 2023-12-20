//+------------------------------------------------------------------+
//|                                                  HistoryInfo.mqh |
//|                                                   Gunther Schulz |
//|                        https://github.com/khramkov/MQL5-JSON-API |
//+------------------------------------------------------------------+
#property copyright "Gunther Schulz"
#property link      "https://github.com/khramkov/MQL5-JSON-API"



//+------------------------------------------------------------------+
//| Get historical data                                              |
//+------------------------------------------------------------------+
CJAVal HistoryInfo(CommandRequest &command)
  {

   switch(command.action_type)
     {
      case DATA:
         return (command.time_frame=="TICK") ? GetTicksHistory(command) : GetBarsHistory(command);
      case TRADES:
         return GetTradesHistory();
      default:
        {
         mControl.mSetUserError(65538, GetErrorID(65538));
         return CheckError(__FUNCTION__);
        }
     }
  }

//+------------------------------------------------------------------+
//| Get historical data                                              |
//+------------------------------------------------------------------+
CJAVal GetTicksHistory(CommandRequest &command)
  {
   CJAVal data, result;
   MqlTick tickArray[];

   PrintDebug("Fetching Market-data HISTORY");
   PrintDebug("1) Symbol:    " + command.symbol);
   PrintDebug("2) Timeframe: Ticks");
   PrintDebug("3) Date from: " + TimeToString(command.from_date));
   PrintDebug("4) Date to:   " + TimeToString((command.to_date == NULL) ? TimeCurrent() : command.to_date));

   result["data_type"] = "Tick";
   result["symbol"]    = command.symbol;
   result["timeframe"] = command.time_frame;

   int   tickCount = 0;
   ulong fromDateM = 1000 * (ulong) command.from_date;
   ulong toDateM   = (command.to_date == NULL) ? 1000 * TimeCurrent() : 1000 * (ulong) command.to_date;

   tickCount = CopyTicksRange(command.symbol, tickArray, COPY_TICKS_ALL, fromDateM, toDateM);
   PrintDebug("Preparing tick data of " + (string) tickCount + " ticks for " + command.symbol);

   if(tickCount)
     {
      for(int i=0; i<tickCount; i++)
        {
         data[i][0] = (long)   tickArray[i].time_msc;
         data[i][1] = (double) tickArray[i].bid;
         data[i][2] = (double) tickArray[i].ask;;
        }
      result["market_data"].Set(data);
     }
   else
     {
      result["market_data"].Add(data);
     }
   PrintDebug("Finished preparing tick data");

   return result;
  }

//+------------------------------------------------------------------+
//| Get historical data                                              |
//+------------------------------------------------------------------+
CJAVal GetBarsHistory(CommandRequest &command)
  {
   CJAVal result, data;
   MqlRates bars[];
   int spreads[];
   int barsCount    = 0;
   int spreadsCount = 0;

   ENUM_TIMEFRAMES period = GetTimeframe(command.time_frame);
   datetime fromDate      = command.from_date;
   datetime toDate        = (command.to_date == NULL) ? TimeCurrent() : command.to_date;

   result["data_type"]    = "Bar";
   result["symbol"]       = command.symbol;
   result["timeframe"]    = command.time_frame;

   barsCount = CopyRates(command.symbol, period, fromDate, toDate, bars);
   spreadsCount = CopySpread(command.symbol, period, fromDate, toDate, spreads);

   if(barsCount > 0) {
      // Need to get time of the last bar
      datetime lastBarTime = bars[barsCount - 1].time;

      // Get current time
      datetime currentTime  = TimeCurrent();

      // Check if last bar is closed if not - sequest
      if(lastBarTime == currentTime) barsCount--;

      for(int i=0; i<barsCount; i++)
        {
         data[i][0] = (long)     bars[i].time;
         data[i][1] = (double)   bars[i].open;
         data[i][2] = (double)   bars[i].high;
         data[i][3] = (double)   bars[i].low;
         data[i][4] = (double)   bars[i].close;
         data[i][5] = (double)   bars[i].tick_volume;
         data[i][6] = (int)      spreads[i];
         data[i][7] = (double)   bars[i].real_volume;
        }
      result["market_data"].Set(data);

      PrintDebug("Fetching Market-data HISTORY: " + (string)barsCount + " bars");
      PrintDebug("1) Symbol:     " + command.symbol);
      PrintDebug("2) Timeframe : " + EnumToString(period));
      PrintDebug("3) Date from : " + TimeToString(fromDate));
      PrintDebug("4) Date to:    " + TimeToString((command.to_date == NULL) ? TimeCurrent() : command.to_date));

   }
   else
     {
      result["market_data"].Add(data);
     }

   return result;
  }

//+------------------------------------------------------------------+
//| Get historical data                                              |
//+------------------------------------------------------------------+
CJAVal GetTradesHistory(void)
  {
   CDealInfo tradeInfo;
   CJAVal trades, data;

   if(HistorySelect(0,TimeCurrent()))
     {
      // Get total deals in history
      int total = HistoryDealsTotal();
      ulong ticket; // deal ticket

      for(int i=0; i<total; i++)
        {
         if((ticket=HistoryDealGetTicket(i))>0)
           {
            tradeInfo.Ticket(ticket);
            data["ticket"] = (long)   tradeInfo.Ticket();
            data["time"]   = (long)   tradeInfo.Time();
            data["price"]  = (double) tradeInfo.Price();
            data["volume"] = (double) tradeInfo.Volume();
            data["symbol"] = (string) tradeInfo.Symbol();
            data["type"]   = (string) tradeInfo.TypeDescription();
            data["entry"]  = (long)   tradeInfo.Entry();
            data["profit"] = (double) tradeInfo.Profit();

            trades["trades"].Add(data);
           }
        }
     }
   else
      trades["trades"].Add(data);

   return trades;
  }
//+------------------------------------------------------------------+
