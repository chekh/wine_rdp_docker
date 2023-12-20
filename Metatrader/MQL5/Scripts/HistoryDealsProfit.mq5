//double Profit( void )
//{
// double Res = 0;
//
// if (HistorySelect(0, INT_MAX))
//   for (int i = HistoryDealsTotal() - 1; i >= 0; i--)
//   {
//     const ulong Ticket = HistoryDealGetTicket(i);
//
//     if((HistoryDealGetInteger(Ticket, DEAL_MAGIC) == MagicNumber) && (HistoryDealGetString(Ticket, DEAL_SYMBOL) == Symbol()))
//       Res += HistoryDealGetDouble(Ticket, DEAL_PROFIT);
//   }
//
//  return(Res);
//}

//+------------------------------------------------------------------+
//|                                                  export_V1.1.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "https://www.mql5.com/de/users/amando"
#property link      "https://www.mql5.com/de/users/amando"
#property version   "1.1"
#property script_show_inputs



input ulong id = 50655958633;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   color BuyColor =clrBlue;
   color SellColor=clrRed;


//--- request trade history
   if (HistorySelectByPosition(id)){
   //--- create objects
//   string   name;
   uint     total=HistoryDealsTotal();
   Print("Deals List of "+(string) total+" deals");
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime time;
   string   symbol;
   double   volume;
   ENUM_DEAL_TYPE      type;
   ENUM_DEAL_ENTRY     entry;
   double   total_pnl = 0;
//--- for all deals
   for(uint i=0; i<total; i++)
     {
      //--- try to get deals ticket
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         Print("Deal number: "+ (string) i);
         //--- get deals properties
         price  = HistoryDealGetDouble(ticket, DEAL_PRICE);
         time   = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         type   = HistoryDealGetInteger(ticket, DEAL_TYPE);
         entry  = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         total_pnl += profit;

         Print("Price:  " + (string) price);
         Print("Volume: " + (string) volume);
         Print("Time:   " + (string) time);
         Print("Symbol: " + (string) symbol);
         Print("Type:   " + (string) EnumToString(type));
         Print("Entry:  " + (string) EnumToString(entry));
         Print("Profit: " + (string) profit);

        }
     }
     Print("Total Profit: " + (string) total_pnl);
   }

  }

//+------------------------------------------------------------------+
