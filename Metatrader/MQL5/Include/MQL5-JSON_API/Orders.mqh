//+------------------------------------------------------------------+
//|                                                       Orders.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Fetch orders information                                         |
//+------------------------------------------------------------------+
CJAVal GetOrders()
  {
   mControl.mResetLastError();

   COrderInfo myorder;
   CJAVal data, order;
  

// Get orders
   if(HistorySelect(0,TimeCurrent()))
     {
      int ordersTotal = OrdersTotal();
      // Create empty array if no orders
      if(!ordersTotal)
        {
         data["error"]=(bool) false;
         data["orders"].Add(order);
        }

      for(int i=0; i<ordersTotal; i++)
        {
         if(myorder.Select(OrderGetTicket(i)))
           {
            order["id"]=(string) myorder.Ticket();
            order["magic"]=OrderGetInteger(ORDER_MAGIC);
            order["symbol"]=OrderGetString(ORDER_SYMBOL);
            order["type"]=EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
            order["time_setup"]=OrderGetInteger(ORDER_TIME_SETUP);
            order["open"]=OrderGetDouble(ORDER_PRICE_OPEN);
            order["stoploss"]=OrderGetDouble(ORDER_SL);
            order["takeprofit"]=OrderGetDouble(ORDER_TP);
            order["volume"]=OrderGetDouble(ORDER_VOLUME_INITIAL);

            data["error"]=(bool) false;
            data["orders"].Add(order);
           }
         // Error handling
         CheckError(__FUNCTION__);
        }
     }

   return data;
  }
//+------------------------------------------------------------------+
