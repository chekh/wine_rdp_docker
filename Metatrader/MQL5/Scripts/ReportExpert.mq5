//+------------------------------------------------------------------+
//|                                                 DealsHistory.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviser Ltd."
#property link      "https://www.mql5.com"
#property version   "1.01"
#property script_show_inputs
//--- input parameters

//---


input datetime Start    = D'2023.08.14';

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--
   datetime End = TimeCurrent();
   HistorySelect(Start, End);
   int deals=HistoryDealsTotal();
   Print("HistoryDealsTotal: ", deals);
   
   long login=AccountInfoInteger(ACCOUNT_LOGIN);
   string fileName = StringFormat("%d_HistoryDeals.csv", login); 

   FileDelete(fileName);
   int h=FileOpen(fileName, FILE_READ|FILE_WRITE|FILE_ANSI|FILE_CSV);
   if(h!=INVALID_HANDLE)
     {
      FileWriteString(h, "Symbol;External ID;Comment;Magic;Entry;Order;Positions ID;Reason;Deal Ticket;Time;Time_msc;Type;Volume;Price;Commission;Profit;Swap\r\n");

      if(deals>0)
        {
         for(int i=deals-1; i>=0; i--)
           {

            ulong ticket=HistoryDealGetTicket(i);
            if(ticket>0)
              {
               string externalid             =HistoryDealGetString(ticket, DEAL_EXTERNAL_ID);
               string comment                =HistoryDealGetString(ticket, DEAL_COMMENT);
               string symbol                 =HistoryDealGetString(ticket, DEAL_SYMBOL);
               long  magic                   =HistoryDealGetInteger(ticket, DEAL_MAGIC);
               string entry                  =EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY));
               long order                    =HistoryDealGetInteger(ticket, DEAL_ORDER);
               long posid                    =HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
               string reason                 =EnumToString((ENUM_DEAL_REASON)HistoryDealGetInteger(ticket, DEAL_REASON));
               long dealticket               =HistoryDealGetInteger(ticket, DEAL_TICKET);
               datetime time                 =(datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
               long timemsc                  =HistoryDealGetInteger(ticket, DEAL_TIME_MSC);
               string type                   =EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE));
               string commission             =(string)HistoryDealGetDouble(ticket, DEAL_COMMISSION);
               string price                  =(string)HistoryDealGetDouble(ticket, DEAL_PRICE);
               string profit                 =(string)HistoryDealGetDouble(ticket, DEAL_PROFIT);
               string swap                   =(string)HistoryDealGetDouble(ticket, DEAL_SWAP);
               string volume                 =(string)HistoryDealGetDouble(ticket, DEAL_VOLUME);

               StringReplace(commission, ".", ",");
               StringReplace(price, ".", ",");
               StringReplace(profit, ".", ",");
               StringReplace(swap, ".", ",");
               StringReplace(volume, ".", ",");

               FileWriteString(h, symbol+";"+
                                 (string)externalid+";"+
                                 comment+";"+
                                 (string)magic+";"+
                                 entry+";"+
                                 (string)order+";"+
                                 (string)posid+";"+
                                 reason+";"+
                                 (string)dealticket+";"+
                                 (string)time+";"+
                                 (string)timemsc+";"+
                                 type+";"+
                                 (string)volume+";"+
                                 (string)price+";"+
                                 (string)commission+";"+
                                 (string)profit+";"+
                                 (string)swap+
                                 "\r\n"
                             );

              }

           }
        }

     }
   FileClose(h);

   
  }
//+------------------------------------------------------------------+
