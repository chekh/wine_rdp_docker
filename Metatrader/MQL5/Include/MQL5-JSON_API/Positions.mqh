//+------------------------------------------------------------------+
//|                                                    Positions.mqh |
//|                                  Copyright 2023, RestAdviserLtd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, RestAdviserLtd."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//| Fetch positions information                                      |
//+------------------------------------------------------------------+
bool GetPositionInfo(ulong ticket, CJAVal &position, CJAVal &error)
  {
   if(ticket>0)
     if(PositionSelectByTicket(ticket))
        {
          
         position["identifier"]      = PositionGetInteger(POSITION_IDENTIFIER);
         position["ticket"]          = PositionGetInteger(POSITION_TICKET);
         position["magic"]           = PositionGetInteger(POSITION_MAGIC);
         position["symbol"]          = PositionGetString(POSITION_SYMBOL);
         position["external_id"]     = PositionGetString(POSITION_EXTERNAL_ID);
         position["comment"]         = PositionGetString(POSITION_COMMENT);

         position["reason"]          = PositionGetInteger(POSITION_REASON);
         position["type"]            = PositionGetInteger(POSITION_TYPE);

         position["time"]            = PositionGetInteger(POSITION_TIME);
         position["time_msc"]        = PositionGetInteger(POSITION_TIME_MSC);
         position["time_update"]     = PositionGetInteger(POSITION_TIME_UPDATE);
         position["time_update_msc"] = PositionGetInteger(POSITION_TIME_UPDATE_MSC);

         position["volume"]          = PositionGetDouble(POSITION_VOLUME);
         position["price_open"]      = PositionGetDouble(POSITION_PRICE_OPEN);
         position["sl"]              = PositionGetDouble(POSITION_SL);
         position["tp"]              = PositionGetDouble(POSITION_TP);
         position["price_current"]   = PositionGetDouble(POSITION_PRICE_CURRENT);
         position["swap"]            = PositionGetDouble(POSITION_SWAP);
         position["profit"]          = PositionGetDouble(POSITION_PROFIT);
         return true;
        }
    // Wrong ticker error    
    mControl.mSetUserError(65545, GetErrorID(65545));
    error = CheckError(__FUNCTION__);
    return false;
  }

//+------------------------------------------------------------------+
//| Fetch positions information                                      |
//+------------------------------------------------------------------+
CJAVal GetPositions()
  {
   CPositionInfo myposition;
   CJAVal data, position, error;

// Get positions
   int positionsTotal = PositionsTotal();
   PrintDebug("Positions Total: " + (string)positionsTotal);

   data["positions_total"] = (int) positionsTotal;
// Create empty array if no positions
   if(!positionsTotal)
     {
      data["positions"].Add(position);
      return data;
     }

// Go through positions in a loop
   for(int i=0; i<positionsTotal; i++)
     {
      mControl.mResetLastError();
      ulong ticket = PositionGetTicket(i);

      if(ticket>0)
        {
         PositionSelectByTicket(ticket);

         if(GetPositionInfo(ticket, position, error))
           {
            data["positions"].Add(position);
           }
         else
           {
            return CheckError(__FUNCTION__);
           }
        }
     }

   data["error"]              = (bool) false;
   data["error_description"]  = (string) "No Error.";
   return data;
  }
//+------------------------------------------------------------------+
