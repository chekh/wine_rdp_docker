//+------------------------------------------------------------------+
//|                                               OnTrade_Sample.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
 
input    int days=7;            // depth of trade history in days
//--- set the limits of the trade history on the global scope
datetime     start;             // start date for trade history in cache
datetime     end;               // end date for trade history in cache
//--- global counters
int          orders;            // number of active orders
int          positions;         // number of open positions
int          deals;             // number of deals in the trade history cache
int          history_orders;    // number of orders in the trade history cache
bool         started=false;     // flag of counter relevance
 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   end=TimeCurrent();
   start=end-days*PeriodSeconds(PERIOD_D1);
   PrintFormat("Limits of the history to be loaded: start - %s, end - %s",
               TimeToString(start),TimeToString(end));
   InitCounters();
//---
   return(0);
  }
//+------------------------------------------------------------------+
//|  initialization of position, order and trade counters            |
//+------------------------------------------------------------------+
void InitCounters()
  {
   ResetLastError();
//--- load history
   bool selected=HistorySelect(start,end);
   if(!selected)
     {
      PrintFormat("%s. Failed to load history from %s to %s to cache. Error code: %d",
                  __FUNCTION__,TimeToString(start),TimeToString(end),GetLastError());
      return;
     }
//--- get the current value
   orders=OrdersTotal();
   positions=PositionsTotal();
   deals=HistoryDealsTotal();
   history_orders=HistoryOrdersTotal();
   started=true;
   Print("Counters of orders, positions and deals successfully initialized");
  }  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(started) SimpleTradeProcessor();
   else InitCounters();
  }
//+------------------------------------------------------------------+
//| called when a Trade event arrives                                |
//+------------------------------------------------------------------+
void OnTrade()
  {
   if(started) SimpleTradeProcessor();
   else InitCounters();
  }
//+------------------------------------------------------------------+
//| example of processing changes in trade and history               |
//+------------------------------------------------------------------+
void SimpleTradeProcessor()
  {
   end=TimeCurrent();
   ResetLastError();
//--- download trading history from the specified interval to the program cache
   bool selected=HistorySelect(start,end);
   if(!selected)
     {
      PrintFormat("%s. Failed to load history from %s to %s to cache. Error code: %d",
                  __FUNCTION__,TimeToString(start),TimeToString(end),GetLastError());
      return;
     }
//--- get the current values
   int curr_orders=OrdersTotal();
   int curr_positions=PositionsTotal();
   int curr_deals=HistoryDealsTotal();
   int curr_history_orders=HistoryOrdersTotal();
//--- check if the number of active orders has been changed
   if(curr_orders!=orders)
     {
      //--- number of active orders has been changed
      PrintFormat("Number of orders has been changed. Previous value is %d, current value is %d",
                  orders,curr_orders);
      //--- update the value
      orders=curr_orders;
     }
//--- changes in the number of open positions
   if(curr_positions!=positions)
     {
      //--- number of open positions has been changed
      PrintFormat("Number of positions has been changed. Previous value is %d, current value is %d",
                  positions,curr_positions);
      //--- update the value
      positions=curr_positions;
     }
//--- changes in the number of deals in the trade history cache
   if(curr_deals!=deals)
     {
      //--- number of deals in the trade history cache has been changed
      PrintFormat("Number of deals has been changed. Previous value is %d, current value is %d",
                  deals,curr_deals);
      //--- update the value
      deals=curr_deals;
     }
//--- changes in the number of history orders in the trade history cache
   if(curr_history_orders!=history_orders)
     {
      //--- number of history orders in the trade history cache has been changed
      PrintFormat("Number of orders in history has been changed. Previous value is %d, current value is %d",
                  history_orders,curr_history_orders);
     //--- update the value
     history_orders=curr_history_orders;
     }
//--- checking if it is necessary to change the limits of the trade history to be requested in cache
   CheckStartDateInTradeHistory();
  }
//+------------------------------------------------------------------+
//|  changing the start date for requesting the trade history        |
//+------------------------------------------------------------------+
void CheckStartDateInTradeHistory()
  {
//--- initial interval, if we were to start working right now
   datetime curr_start=TimeCurrent()-days*PeriodSeconds(PERIOD_D1);
//--- make sure that the start limit of the trade history has not gone
//--- more than 1 day over the intended date
   if(curr_start-start>PeriodSeconds(PERIOD_D1))
     {
      //--- correct the start date of history to be loaded in the cache
      start=curr_start;
      PrintFormat("New start limit of the trade history to be loaded: start => %s",
                  TimeToString(start));
      //--- now reload the trade history for the updated interval
      HistorySelect(start,end);
      //--- correct the deal and order counters in history for further comparison
      history_orders=HistoryOrdersTotal();
      deals=HistoryDealsTotal();
     }
  }
//+------------------------------------------------------------------+