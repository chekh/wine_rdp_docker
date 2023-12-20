   //+------------------------------------------------------------------+
//|                                                       Trader.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Trading module                                                   |
//+------------------------------------------------------------------+
CJAVal Trader(CommandRequest &command)
  {

   mControl.mResetLastError();
   CTrade trade;
   string server        = AccountInfoString(ACCOUNT_SERVER);
   long   account       = AccountInfoInteger(ACCOUNT_LOGIN);
   
   // Do not perform any trade operations if request addressed to wrong account
   if(strict_mode && server != command.server && account != command.account)
     {
       mControl.mSetUserError(65544, GetErrorID(65544));
       return CheckError(__FUNCTION__); 
     }

   SymbolInfoString(command.symbol, SYMBOL_DESCRIPTION);
   CheckError(__FUNCTION__);

   if(command.magic != 0)
     {
      trade.SetExpertMagicNumber(command.magic);
     }

   if(command.deviation != 0)
     {
      trade.SetDeviationInPoints(command.deviation);
     }


   switch(command.trade_action)
     {
      case DEAL                     : return TradeDeal(command, trade);
      case PENDING                  : return TradePending(command, trade);
      case POSITION_CLOSE_BY_ID     : return TradePositionCloseById(command, trade);
      case POSITION_CLOSE_BY_MAGIC  : return TradePositionsCloseByMagic(command, trade);
      case POSITION_CLOSE_BY_SYMBOL : return TradePositionCloseBySymbol(command, trade);
      case POSITION_MODIFY          : return TradePositionModifyById(command, trade);
      case POSITION_MODIFY_BY_MAGIC : return TradePositionModifyByMagic(command, trade);
      case POSITION_REVERSE         : return TradePositionReverse(command, trade);
      case POSITION_CHECK           : return TradePositionCheck(command, trade);
      case ORDER_SEND               : return TradeOrderSend(command, trade);  
      case ORDER_MODIFY             : return TradeOrderModify(command, trade);
      case ORDER_CANCEL             : return TradeOrderCancel(command, trade);
      case PENDING_POSITION_CLOSE   : return TradePendingPositionClose(command, trade);
      
      case UNKNOWN:
      default:
        {
         mControl.mSetUserError(65539, GetErrorID(65539));
         return CheckError(__FUNCTION__);
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate StopLoss and Take Profit values                        |
//+------------------------------------------------------------------+
void CalcSLTP(double price, int sign, double &SL, double &TP, double command_sl, double command_tp, 
              string command_symbol, string sltp_units)
  {

   string symbol = command_symbol;
   double point  = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(sign == 0)
      PrintDebug("Error in " + __FUNCTION__ + "`sign` does not initiated to calculate SL/TP.");
   
   if(sltp_units == "%" || sltp_units == "percent" || sltp_units == "pct")
     {
      SL = (command_sl != 0) ? price - sign * price * NormalizePercentage(command_sl) : 0.0;
      TP = (command_tp != 0) ? price + sign * price * NormalizePercentage(command_tp) : 0.0;
     }
   else
      if(sltp_units == "point" || sltp_units == "points" || sltp_units == "pips")
        {
         SL = (command_sl != 0) ? price - sign * point * command_sl : 0.0;
         TP = (command_tp != 0) ? price + sign * point * command_tp : 0.0;
        }
   else
      if(sltp_units == "absolute" || sltp_units == "abs")
        {
         SL = (command_sl != 0) ? command_sl : 0.0;
         TP = (command_tp != 0) ? command_tp : 0.0;
        }
   else
      if(sltp_units == "relative" || sltp_units == "rel")
        {
         SL = (command_sl != 0) ? price - sign * command_sl : 0.0;
         TP = (command_tp != 0) ? price + sign * command_tp : 0.0;
        }

   SL = NormalizePrice(SL, symbol);
   TP = NormalizePrice(TP, symbol);
  }

//+------------------------------------------------------------------+
//|  Normalization StopLoss / TakeProfit percentage                  |
//+------------------------------------------------------------------+
double NormalizePercentage(double priceValue) {
    if (priceValue < 1)
        return priceValue;
    else
        return priceValue / 100;
}

//+------------------------------------------------------------------+
//|  Normalization Price or StopLoss / TakeProfit level              |
//+------------------------------------------------------------------+
double NormalizePrice(double price, string symbol) {
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);  // Get point of symbol

    return NormalizeDouble(price, SymbolInfoInteger(symbol, SYMBOL_DIGITS));  // Normalize price to digits of symbol
}

//+------------------------------------------------------------------+
//|  Calc price and sign for Buy and Sell Orders                     |
//+------------------------------------------------------------------+
void CalcPriceAndSignByOrderType(ENUM_ORDER_TYPE order_type, double order_price, string order_symbol, double &price, int &sign) {
    if (order_type == ORDER_TYPE_SELL || order_type == ORDER_TYPE_SELL_STOP || order_type == ORDER_TYPE_SELL_LIMIT) {
        sign = -1;
        price = (order_price != 0) ? order_price : SymbolInfoDouble(order_symbol, SYMBOL_BID);
    } else if (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_STOP || order_type == ORDER_TYPE_BUY_LIMIT) {
        sign = 1;
        price = (order_price != 0) ? order_price : SymbolInfoDouble(order_symbol, SYMBOL_ASK);
    }
    else{
        mControl.mSetUserError(65538, GetErrorID(65538));
        CheckError(__FUNCTION__);
    }
}
//+------------------------------------------------------------------+
//|  Market orders for Buy and Sell                                  |
//+------------------------------------------------------------------+
CJAVal TradeDeal(CommandRequest &command, CTrade &trade)
  {

   int      sign;
   double   SL, TP, price;
   string   request_uuid = command.uuid;
   CJAVal   error;


   for(int trying=1; trying <= retryDeal; trying++)
   {
//      switch(command.order_type)
//       {
//         case ORDER_TYPE_SELL:
//           {
//            price = (command.price != 0) ? command.price : SymbolInfoDouble(command.symbol, SYMBOL_BID);
//            sign = -1;
//           }
//         break;
//
//         case ORDER_TYPE_BUY:
//           {
//            price = (command.price != 0) ? command.price : SymbolInfoDouble(command.symbol, SYMBOL_ASK);
//            sign = 1;
//           }
//         break;
//
//         default:
//            mControl.mSetUserError(65538, GetErrorID(65538));
//            return CheckError(__FUNCTION__);
//        }
      CalcPriceAndSignByOrderType(command.order_type, command.price, command.symbol, price, sign);
      CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
      price = NormalizePrice(price, command.symbol);

      if(trade.PositionOpen(command.symbol, command.order_type, command.volume, price, SL, TP, command.comment))
         return OrderDoneOrError(false, __FUNCTION__, trade);
      else
         error = OrderDoneOrError(true, __FUNCTION__, trade);
         if (error["retcode"] == 10004)
         {
            PrintDebug("Retcod: 10004, trying #" + trying );
            continue;
         }
         else
            break;

   }
   return OrderDoneOrError(true, __FUNCTION__, trade);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CJAVal TradePending(CommandRequest &command, CTrade &trade)
  {
// Pending orders execution

   int      sign;
   double   SL, TP, price;
   bool     exec_result  = false;
   string   request_uuid = command.uuid;
   CJAVal   error;
   
   price = NormalizePrice(command.price, command.symbol); // Price + offset
   
   switch(command.order_type)
     {
      case ORDER_TYPE_BUY_LIMIT:
        {
         sign = 1;
         CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
         exec_result = trade.BuyLimit(command.volume, price, command.symbol, SL, TP, command.type_time, command.expiration, command.comment);
        }
      break;

      case ORDER_TYPE_SELL_LIMIT:
        {
         sign = -1;
         CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
         exec_result = trade.SellLimit(command.volume, price, command.symbol, SL, TP, command.type_time, command.expiration, command.comment);
        }
      break;

      case ORDER_TYPE_BUY_STOP:
        {
         sign = 1;
         CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
         exec_result = trade.BuyStop(command.volume, price, command.symbol, SL, TP, command.type_time, command.expiration, command.comment);
        }
      break;

      case ORDER_TYPE_SELL_STOP:
        {
         sign = -1;
         CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
         exec_result = trade.SellStop(command.volume, price, command.symbol, SL, TP, command.type_time, command.expiration, command.comment);
        }
      break;

      default:
         mControl.mSetUserError(65538, GetErrorID(65538));
         return CheckError(__FUNCTION__);
     }

   if(exec_result)
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);

  }
  

//+------------------------------------------------------------------+
//|  Close Position by ticket                                          |
//+------------------------------------------------------------------+
CJAVal TradePositionCloseById(CommandRequest &command, CTrade &trade)
  {
   if(trade.PositionClose(command.position))
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);
  }


//+------------------------------------------------------------------+
//| Closing positions by magic                                       |
//+------------------------------------------------------------------+
CJAVal TradePositionsCloseByMagic(CommandRequest &command, CTrade &trade)
  {
   CJAVal result, data;
   CPositionInfo  m_position;
   int count_total = 0;
   int count_closed = 0;

   for(int i=PositionsTotal()-1; i>=0; i--)

      if(m_position.SelectByIndex(i) && m_position.Magic() == command.magic) // selects the position by index for further access to its properties
        {
         if(command.close_all)
           {
            PrintDebug("Close All type positions");
            count_total++;
            if(trade.PositionClose(m_position.Ticket()))
              {
               data = OrderDoneOrError(false, __FUNCTION__, trade);
               count_closed++;
              }
            else
               data = OrderDoneOrError(true, __FUNCTION__, trade);
           }
         else
            if(!command.close_all && command.order_type!=ORDER_TYPE_SELL && m_position.PositionType()==POSITION_TYPE_BUY)
              {
               PrintDebug("Closing Long Positions...");
               count_total++;
               if(trade.PositionClose(m_position.Ticket()))
                 {
                  data = OrderDoneOrError(false, __FUNCTION__, trade);
                  count_closed++;
                 }
               else
                  data = OrderDoneOrError(true, __FUNCTION__, trade);
              }
            else
               if(!command.close_all && command.order_type!=ORDER_TYPE_BUY && m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  PrintDebug("Closing Shot Positions...");
                  count_total++;
                  if(trade.PositionClose(m_position.Ticket()))
                    {
                     data = OrderDoneOrError(false, __FUNCTION__, trade);
                     count_closed++;
                    }
                  else
                     data = OrderDoneOrError(true, __FUNCTION__, trade);
                 }
        }
        data["position_ticket"] = (long) m_position.Ticket();
        result["positions"].Add(data);


   result["total"]  = count_total;
   result["closed"] = count_closed;
   
   PrintDebug("Positions Total: " + (string) count_total + ", Requests to close: " + (string)  count_closed);
   if(count_closed == count_total)
      result["error"] = false;
   else
      result["error"] = true;
   return result;
  }


//+------------------------------------------------------------------+
//|  Close position by symbol netting mode                           |
//+------------------------------------------------------------------+
CJAVal TradePositionCloseBySymbol(CommandRequest &command, CTrade &trade)
  {
   if(trade.PositionClose(command.symbol))
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CJAVal TradePositionModifyById(CommandRequest &command, CTrade &trade)
  {
// Position modify
   bool exec_result = false;

   exec_result = trade.PositionModify(command.position, command.sl, command.tp);

   if(exec_result)
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CJAVal TradePositionModifyByMagic(CommandRequest &command, CTrade &trade)
  {
// Position modify
   bool exec_result = false;

   CPositionInfo position;
   int count_total = 0;
   int count_changed = 0;
   int sign;
   ulong magicNumber = command.magic;
   double SL, TP, price;
   int positions = PositionsTotal();


   for (int i = 0; i < positions; i++) {
       if (PositionGetInteger(POSITION_MAGIC) == magicNumber) {
           ulong ticket = PositionGetTicket(i);
           PrintDebug("Position with magic: " + magicNumber + " and pos_id: " + ticket + " found");

           double current_SL               = PositionGetDouble(POSITION_SL);
           double current_TP               = PositionGetDouble(POSITION_TP);
           double current_price            = PositionGetDouble(POSITION_PRICE_CURRENT);
           double position_pnl             = PositionGetDouble(POSITION_PROFIT);
           string position_symbol          = PositionGetString(POSITION_SYMBOL);
           ENUM_POSITION_TYPE positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

           switch (positionType) {
               case POSITION_TYPE_BUY:
                   PrintDebug("Position type: Buy");
                   sign = 1;
                   price = SymbolInfoDouble(position_symbol, SYMBOL_BID);
                   CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
                   SL = SL || current_SL;
                   TP = TP || current_TP;
                   exec_result = trade.PositionModify(ticket, SL, TP);
                   break;

               case POSITION_TYPE_SELL:
                   PrintDebug("Position type: Sell");
                   sign = -1;
                   price = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
                   CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
                   SL = SL || current_SL;
                   TP = TP || current_TP;
                   exec_result = trade.PositionModify(ticket, SL, TP);
                   break;

               default:
                   PrintDebug("Unknown position type");
                   break;
           }

           if(exec_result) {
               exec_result = false;
               count_changed++;
           }
       }
   }
   PrintDebug("Magig number: " + (string) magicNumber + " Positions Total: " + (string) positions + ", SL/TP changed: " + (string)  count_changed);
   if (positions == count_changed) {
       return OrderDoneOrError(false, __FUNCTION__, trade);
   } else {
       return OrderDoneOrError(true, __FUNCTION__, trade);
   }

 }

//+------------------------------------------------------------------+
//| Reverse Position if any or open new one                          |
//+------------------------------------------------------------------+
CJAVal TradePositionReverse(CommandRequest &command, CTrade &trade)
  {

   CPositionInfo  m_position;
   CJAVal result, error;

   result["multistage"] = true;

   PrintDebug("Order type: " + (string)command.order_type);
   if(command.order_type!=ORDER_TYPE_BUY && command.order_type!=ORDER_TYPE_SELL)
     {
      mControl.mSetUserError(65543, GetErrorID(65543));
      CheckError(__FUNCTION__);
      return error;
     }

   result["stage_1"].Add(TradePositionsCloseByMagic(command, trade));
   result["stage_2"].Add(TradeDeal(command, trade));
   return result;

  }

//+------------------------------------------------------------------+
//| Check Position                                                   |
//+------------------------------------------------------------------+
CJAVal TradePositionCheck(CommandRequest &command, CTrade &trade)
  {
   CJAVal data, result, error;

   if(GetPositionInfo(command.position, result, error)) 
   {
      data["error"]             = (bool) false;
      data["positions_total"]   = (int) 1;
      data["positions"].Add(result);
      return data;
   }
   else
   {
      data["error"]             = (bool) true;
      data["error_description"].Add(error);;
      return data;
   }

  }

//+------------------------------------------------------------------+
//|  Send any order                                                  |
//+------------------------------------------------------------------+
CJAVal TradeOrderSend(CommandRequest &command, CTrade &trade)
  {
  MqlTradeRequest request;
  MqlTradeResult result;
  
  switch(command.trade_action){
  case DEAL:                  request.action = TRADE_ACTION_DEAL;
  case PENDING:               request.action = TRADE_ACTION_PENDING;
  case POSITION_MODIFY:       request.action = TRADE_ACTION_SLTP;
  case ORDER_MODIFY:          request.action = TRADE_ACTION_MODIFY;
  case ORDER_CANCEL:          request.action = TRADE_ACTION_REMOVE;
  case POSITION_CLOSE_BY_ID:  request.action = TRADE_ACTION_CLOSE_BY;
  }
  
   ;
   request.magic        = command.magic;
   request.order        = command.order_id;
   request.symbol       = command.symbol;
   request.volume       = command.volume;
   request.price        = command.price;
   request.stoplimit    = command.stoplimit;
   request.sl           = command.sl;
   request.tp           = command.tp;
   request.deviation    = command.deviation;
   request.type         = command.order_type;
   request.type_filling = command.type_filling;
   request.type_time    = command.type_time;
   request.expiration   = command.expiration;
   request.comment      = command.comment;
   request.position     = command.position;
   request.position_by  = command.position_by;
  
  if(trade.OrderSend(request, result))
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);
  }
  

//+------------------------------------------------------------------+
//|  Modify opened orders                                            |
//+------------------------------------------------------------------+
CJAVal TradeOrderModify(CommandRequest &command, CTrade &trade)
  {

   int      sign;
   double   SL, TP, price;

   sign = 0;
   
   if (!OrderSelect(command.order_id))
      return OrderDoneOrError(true, __FUNCTION__, trade);

   switch((int)OrderGetInteger(ORDER_TYPE))
     {
      case ORDER_TYPE_SELL:
        {
         price = (command.price != 0) ? command.price : SymbolInfoDouble(command.symbol, SYMBOL_BID);
         sign = -1;
        }
      break;

      case ORDER_TYPE_BUY:
        {
         price = (command.price != 0) ? command.price : SymbolInfoDouble(command.symbol, SYMBOL_ASK);
         sign = 1;
        }
      break;

      default:
         {
            SL = command.sl;
            TP = command.tp;
            break;
         }
     }

   CalcSLTP(price, sign, SL, TP, command.sl, command.tp, command.symbol, command.sltp_units);
   price = NormalizePrice(price, command.symbol);

   if(trade.OrderModify(command.order_id, price, SL, TP, command.type_time, command.expiration))
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);

  }
  
//+------------------------------------------------------------------+
//|  Modify opened orders                                            |
//+------------------------------------------------------------------+
CJAVal TradeOrderCancel(CommandRequest &command, CTrade &trade)
  {
  
  if(trade.OrderDelete(command.order_id))
      return OrderDoneOrError(false, __FUNCTION__, trade);
   else
      return OrderDoneOrError(true, __FUNCTION__, trade);
  }

//+------------------------------------------------------------------+
//| Add magic to pending positions close list                        |
//+------------------------------------------------------------------+
CJAVal TradePendingPositionClose(CommandRequest& command, CTrade& trade) {
    ulong  magicValue    = command.magic;
    int    accountValue  = command.account;
    int    accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);


    if (accountValue == accountNumber) {
        if (!IsMagicInPendigCloseList(magicValue)) {
            int arraySize = ArraySize(magicForPendingClose);
            ArrayResize(magicForPendingClose, arraySize + 1);
            magicForPendingClose[arraySize] = magicValue;
            return ActionDoneOrError(false, __FUNCTION__, "Magic: " + magicValue + " added to pendig close list");
        }
    }
    return ActionDoneOrError(true, __FUNCTION__, "Skipped request. Requested account is not my account: " + accountValue);

}

//+------------------------------------------------------------------+
//|  Check if magic in pendig positions close list                   |
//+------------------------------------------------------------------+
bool IsMagicInPendigCloseList(ulong magicValue) {
    for (int i = 0; i < ArraySize(magicForPendingClose); i++) {
        if (magicForPendingClose[i] == magicValue){
            return true;  // Magic is already in pendig close list
        }
    }
    return false;         // Magic is not in pendig close list
}


//+------------------------------------------------------------------+
//|  Close positions by magic                                        |
//+------------------------------------------------------------------+
bool ClosePositionsByMagic(ulong magicNumber) {
    CTrade trade;
    CPositionInfo position;
    int count_total = 0;
    int count_closed = 0;
    int positions = PositionsTotal();

    PrintDebug("Closing positions by magic: " + magicNumber);

    for (int i = 0; i < positions; i++) {
        if (PositionGetInteger(POSITION_MAGIC) == magicNumber) {
            ulong ticket = PositionGetTicket(i);
            PrintDebug("Position with magic: " + magicNumber + " and pos_id: " + ticket + " found");
            bool result = trade.PositionClose(ticket);

            if (result) {
                count_closed++;
                PrintDebug("Position with magic: " + magicNumber + " and pos_id: " + ticket + " closed");
            } else {
                PrintDebug("Position with magic: " + magicNumber + " and pos_id: " + ticket + " still open");
            }
            count_total++;
        }
    }
    if (count_total == count_closed) {
        return true;
    } else {
        return false;
    }
}

//+------------------------------------------------------------------+
//|  Modify opened orders                                            |
//+------------------------------------------------------------------+
void ClosePositionsByMagicList() {
    CTrade trade;
    CPositionInfo position;
    int positions = PositionsTotal();

    for (int i = 0; i < ArraySize(magicForPendingClose); i++) {
        PrintDebug("Execute magicForPendingClose for magic: " + magicForPendingClose[i]);
        bool result = ClosePositionsByMagic(magicForPendingClose[i]);
        if (result) {
            ArrayRemove(magicForPendingClose,i,1);
        }
    }
}

//+------------------------------------------------------------------+

