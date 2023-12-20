//+------------------------------------------------------------------+
//|                     MyTrailingStopLossExpert.mq5                  |
//|                      Copyright 2021, Your Company Name             |
//|                          https://www.yourcompany.com               |
//+------------------------------------------------------------------+

// Define input parameters
input double TrailingStop = 20.0;     // Trailing stop distance in pips

//+------------------------------------------------------------------+
//| Function to trail stop loss for a position                        |
//+------------------------------------------------------------------+
void TrailStopLoss(int positionId, double stopLossLevel)
{
    // Calculate the current stop loss level
    double currentStopLossLevel = 0.0;

    // Check if the position with the given ID exists
    if (PositionSelectByTicket(positionId))
    {
        // Get the current stop loss level of the position
        currentStopLossLevel = PositionGetDouble(POSITION_SL);

        // Check if the position is a long position
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            // Check if the current stop loss level is lower than the current bid price
            if (currentStopLossLevel < Bid)
            {
                // Update the stop loss level to trail the current bid price by the trailing stop distance
                stopLossLevel = NormalizeDouble(Bid - TrailingStop * Point, Digits);

                // Modify the stop loss level of the position
                PositionModify(POSITION_SL, stopLossLevel);

                // Log the stop loss change
                Print("Stop loss level for position ", positionId, " has been updated to ", stopLossLevel);
            }
        }
        // Check if the position is a short position
        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            // Check if the current stop loss level is higher than the current ask price
            if (currentStopLossLevel > Ask)
            {
                // Update the stop loss level to trail the current ask price by the trailing stop distance
                stopLossLevel = NormalizeDouble(Ask + TrailingStop * Point, Digits);

                // Modify the stop loss level of the position
                PositionModify(POSITION_SL, stopLossLevel);

                // Log the stop loss change
                Print("Stop loss level for position ", positionId, " has been updated to ", stopLossLevel);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // List of position IDs to trail stop loss
    int positionIds[] = {12345, 54321}; // Replace with the actual position IDs

    // Trail stop loss for all positions in the list
    double stopLossLevel = 0.0;
    int totalPositions = ArraySize(positionIds);
    for (int i = 0; i < totalPositions; i++)
    {
        TrailStopLoss(positionIds[i], stopLossLevel);
    }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up any resources here
}

//+------------------------------------------------------------------+