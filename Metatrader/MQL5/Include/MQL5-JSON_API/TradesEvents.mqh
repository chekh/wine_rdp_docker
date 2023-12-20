//+------------------------------------------------------------------+
//|                                                 TradesEvents.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Describe Trade Transaction information                           |
//+------------------------------------------------------------------+
bool GetTradeTransaction(CJAVal &data, 
                         const MqlTradeTransaction &trans,
                         const MqlTradeRequest     &request,
                         const MqlTradeResult      &result)
  {
    CJAVal req, res, tr;

    switch (trans.type)
    {
        case TRADE_TRANSACTION_DEAL_ADD:
        {
            if (HistoryDealSelect(trans.deal))
            {
                double volume = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
                int direction = HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_BUY ? 1 : -1;
                ENUM_DEAL_ENTRY deal = (ENUM_DEAL_ENTRY) HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

                tr = ComposeTransaction(trans, request, result);
                req = ComposeRequest(trans, request, result);
                res = ComposeResult(trans, request, result);

                data["transaction_type"] = (int) trans.type;
                data["request"].Set(req);
                data["result"].Set(res);
                data["transaction"].Set(tr);

                return true;
            }
        }
    }
    return false;
  }


//+------------------------------------------------------------------+
//| Calc Profit For Closed Position                                  |
//+------------------------------------------------------------------+
 double CalcProfit(const long position_id)
   {
       double   total_pnl   = 0;
       ulong    ticket      = 0;

       if (HistorySelectByPosition(position_id))
       {
           //--- for all deals
           for(uint i=0; i<HistoryDealsTotal(); i++)
             {
              //--- try to get deals ticket
              if((ticket=HistoryDealGetTicket(i)) > 0)
                {
                 total_pnl += HistoryDealGetDouble(ticket, DEAL_PROFIT);
                }
             }
       }
       return total_pnl;
   }

//+------------------------------------------------------------------+
//| Compose Request                                                  |
//+------------------------------------------------------------------+
 CJAVal ComposeTransaction(const MqlTradeTransaction &trans,
                           const MqlTradeRequest     &request,
                           const MqlTradeResult      &result)
   {
        CJAVal res;

//        res["transaction_type"]  =(long)   trans.type;
        res["symbol"]            =(string) trans.symbol;
        res["magic"]             =(long)   HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
        res["deal_reason"]       =(long)   HistoryDealGetInteger(trans.deal, DEAL_REASON);
        res["deal_entry"]        =(long)   HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
        res["deal_ticket"]       =(string) trans.deal;
        res["deal_type"]         =(long)   trans.deal_type;
        res["order_ticket"]      =(string) trans.order;

        res["order_type"]        =(long)   trans.order_type;
        res["order_state"]       =(long)   trans.order_state;
        res["order_time_type"]   =(long)   trans.time_type;
        res["order_expiration"]  =(long)   trans.time_expiration;

        res["price"]             =(string) trans.price;
        res["price_trigger"]     =(string) trans.price_trigger;
        res["stop_loss"]         =(string) trans.price_sl;
        res["take_profit"]       =(string) trans.price_tp;
        res["volume"]            =(string) trans.volume;
        res["position_id"]       =(string) trans.position;
        res["position_by"]       =(string) trans.position_by;

        res["total_profit"]      =(string) CalcProfit(trans.position);

        return res;
   }


//+------------------------------------------------------------------+
//| Compose Request                                                  |
//+------------------------------------------------------------------+
 CJAVal ComposeRequest(const MqlTradeTransaction &trans,
                       const MqlTradeRequest     &request,
                       const MqlTradeResult      &result)
   {
        CJAVal req;

        req["action"]            =(int)    request.action;
        req["magic"]             =(long)   request.magic;
        req["order"]             =(long)   request.order;
        req["symbol"]            =(string) request.symbol;
        req["volume"]            =(double) request.volume;
        req["price"]             =(double) request.price;
        req["stoplimit"]         =(double) request.stoplimit;
        req["stop_loss"]         =(double) request.sl;
        req["take_profit"]       =(double) request.tp;
        req["deviation"]         =(int)    request.deviation;
        req["type"]              =(int)    request.type;
        req["type_filling"]      =(int)    request.type_filling;
        req["type_time"]         =(int)    request.type_time;
        req["expiration"]        =(int)    request.expiration;
        req["comment"]           =(string) request.comment;
        req["position"]          =(long)   request.position;
        req["position_by"]       =(long)   request.position_by;

        return req;
   }

//+------------------------------------------------------------------+
//| Compose Result                                                   |
//+------------------------------------------------------------------+
 CJAVal ComposeResult(const MqlTradeTransaction  &trans,
                      const MqlTradeRequest      &request,
                      const MqlTradeResult       &result)
   {
       CJAVal res;
       res["retcode"]          = (long) result.retcode;
       res["deal"]             = (long) result.deal;
       res["order"]            = (long) result.order;
       res["volume"]           = (double) result.volume;
       res["price"]            = (double) result.price;
       res["bid"]              = (double) result.bid;
       res["ask"]              = (double) result.ask;
       res["comment"]          = (string) result.comment;
       res["request_id"]       = (long) result.request_id;
       res["retcode_external"] = (long) result.retcode_external;

       return res;

   }
//+------------------------------------------------------------------+



