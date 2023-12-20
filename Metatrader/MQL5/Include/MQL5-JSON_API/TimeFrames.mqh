//+------------------------------------------------------------------+
//|                                                   TimeFrames.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Convert chart timeframe from string to enum                      |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES GetTimeframe(string chartTF)
  {

   ENUM_TIMEFRAMES tf;
   tf=NULL;

   if(chartTF=="TICK")
      tf=PERIOD_CURRENT;

   if(chartTF=="M1" ||  chartTF=="1M")
      tf=PERIOD_M1;
   
   if(chartTF=="M2" ||  chartTF=="2M")
      tf=PERIOD_M2;
      
   if(chartTF=="M3" ||  chartTF=="3M")
      tf=PERIOD_M3;

   if(chartTF=="M4" ||  chartTF=="4M")
      tf=PERIOD_M4;
      
   if(chartTF=="M5" ||  chartTF=="5M")
      tf=PERIOD_M5;

   if(chartTF=="M10" ||  chartTF=="10M")
      tf=PERIOD_M10;
      
   if(chartTF=="M15" ||  chartTF=="15M")
      tf=PERIOD_M15;

   if(chartTF=="M20" ||  chartTF=="20M")
      tf=PERIOD_M20;
      
   if(chartTF=="M30" ||  chartTF=="30M")
      tf=PERIOD_M30;

   if(chartTF=="H1" ||  chartTF=="1H")
      tf=PERIOD_H1;

   if(chartTF=="H2" ||  chartTF=="2H")
      tf=PERIOD_H2;

   if(chartTF=="H3" ||  chartTF=="3H")
      tf=PERIOD_H3;

   if(chartTF=="H4" ||  chartTF=="4H")
      tf=PERIOD_H4;

   if(chartTF=="H6" ||  chartTF=="6H")
      tf=PERIOD_H6;

   if(chartTF=="H8" ||  chartTF=="8H")
      tf=PERIOD_H8;

   if(chartTF=="H12" ||  chartTF=="12H")
      tf=PERIOD_H12;

   if(chartTF=="D1" ||  chartTF=="1D")
      tf=PERIOD_D1;

   if(chartTF=="W1" ||  chartTF=="1W")
      tf=PERIOD_W1;

   if(chartTF=="MN1" ||  chartTF=="1MN")
      tf=PERIOD_MN1;

//if tf == NULL an error will be raised in config function
   return(tf);
  }
//+------------------------------------------------------------------+
