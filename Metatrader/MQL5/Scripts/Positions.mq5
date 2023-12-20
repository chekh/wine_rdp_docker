//+------------------------------------------------------------------+
//|                                                    Positions.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   ShowPositionsByMagic();
   
  }
//+------------------------------------------------------------------+


void ShowPositionsByMagic() {
    CPositionInfo position;
    int positions = PositionsTotal();

     Print("Positions Total -------->: " + positions);
     for (int j = positions - 1; j >= 0; j--) {
         if(position.SelectByIndex(j)) {
             if (position.Magic()) {
                     Print("Position -------->: " + position.Magic());
             }
         }
     }

}
