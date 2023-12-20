void tral(int startTral, int stepTral)
  {
   double points = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   for(int j=PositionsTotal()-1; j>=0; j--)
     {
      if(m_position.SelectByIndex(j))
        {
         ulong tick = m_position.Ticket();
         if(m_position.Magic()==Magic && m_position.Symbol() == _Symbol)// && m_position.Type() == POSITION_TYPE_BUY && m_position.TakeProfit() != NormalizeDouble(take,_Digits))
           {
            if(m_position.PositionType() == POSITION_TYPE_BUY)
              {
               if((m_position.StopLoss() == 0 || m_position.StopLoss() <= m_position.PriceOpen()) && SymbolInfoDouble(_Symbol,SYMBOL_BID)  >= m_position.PriceOpen() + ((stepTral+startTral) * points))
                 {
                  double stl =  m_position.PriceOpen() + stepTral * points;
                  trade.PositionModify(tick,stl,m_position.TakeProfit());
                 }
               if(m_position.StopLoss() > m_position.PriceOpen() &&
                  SymbolInfoDouble(_Symbol,SYMBOL_BID)  >= m_position.StopLoss() + ((stepTral+startTral) * points))
                 {
                  double stl =  m_position.StopLoss() + stepTral * points;
                  stl=NormalizeDouble(stl,_Digits);
                  trade.PositionModify(tick,stl,m_position.TakeProfit());
                 }
              }

            if(m_position.PositionType() == POSITION_TYPE_SELL)
              {
               if((m_position.StopLoss() == 0 || m_position.StopLoss() >= m_position.PriceOpen()) && SymbolInfoDouble(_Symbol,SYMBOL_ASK)  <= m_position.PriceOpen() - ((stepTral+startTral) * points))
                 {
                  Print("2");
                  double stl =  m_position.PriceOpen() - stepTral * points;
                  stl=NormalizeDouble(stl,_Digits);
                  trade.PositionModify(tick,stl,m_position.TakeProfit());
                 }
               if(m_position.StopLoss() < m_position.PriceOpen() &&
                  SymbolInfoDouble(_Symbol,SYMBOL_ASK)  <= m_position.StopLoss() - ((stepTral+startTral) * points))
                 {
                  double stl =  m_position.StopLoss() - stepTral * points;
                  trade.PositionModify(tick,stl,m_position.TakeProfit());
                 }
              }

           }
        }
     }
  }