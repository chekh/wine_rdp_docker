//+------------------------------------------------------------------+
//|                                                    PointSize.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   string symbol = "EURUSD";
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   Print("Point size for symbol: ", symbol, ": ", point);
   
   double price_sell = SymbolInfoDouble(symbol, SYMBOL_BID);
   double price_buy = SymbolInfoDouble(symbol, SYMBOL_ASK);

   double sl = 0.007368975 / 2 / 0.00001;
   double sl_sell = price_sell + point * sl;
   double sl_buy  = price_buy  - point * sl;
   
   Print("symbol: ", _Symbol, " sl: ", sl, " point: ", point, " sl_sell: ", sl_sell);
   Print("symbol: ", _Symbol, " sl: ", sl, " point: ", point, " sl_buy: ", sl_buy);
  
  }
//+------------------------------------------------------------------+
