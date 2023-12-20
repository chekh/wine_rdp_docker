//+------------------------------------------------------------------+
//|                     MyTrailingStopLossExpert.mq5                  |
//|                      Copyright 2021, Your Company Name             |
//|                          https://www.yourcompany.com               |
//+------------------------------------------------------------------+

// Define input parameters
input double TrailingStop = 20.0;     // Trailing stop distance in pips

//+------------------------------------------------------------------+
//| Function to trail stop loss for long positions                    |
//+------------------------------------------------------------------+
void TrailStopLossLong(int positionId, double stopLossLevel)
{
    // Calculate the current stop loss level
    double currentStopLossLevel = 0.0;

    // Check if a long position with the given ID exists
    if (PositionSelectByTicket(positionId) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
    {
        // Get the current stop loss level of the long position
        currentStopLossLevel = PositionGetDouble(POSITION_SL);

        // Check if the current stop loss level is lower than the current bid price
        if (currentStopLossLevel < Bid)
        {
            // Update the stop loss level to trail the current bid price by the trailing stop distance
            stopLossLevel = NormalizeDouble(Bid - TrailingStop * Point, Digits);

            // Modify the stop loss level of the long position
            PositionModify(POSITION_SL, stopLossLevel);
        }
    }
}

//+------------------------------------------------------------------+
//| Function to trail stop loss for short positions                   |
//+------------------------------------------------------------------+
void TrailStopLossShort(int positionId, double stopLossLevel)
{
    // Calculate the current stop loss level
    double currentStopLossLevel = 0.0;

    // Check if a short position with the given ID exists
    if (PositionSelectByTicket(positionId) && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
    {
        // Get the current stop loss level of the short position
        currentStopLossLevel = PositionGetDouble(POSITION_SL);

        // Check if the current stop loss level is higher than the current ask price
        if (currentStopLossLevel > Ask)
        {
            // Update the stop loss level to trail the current ask price by the trailing stop distance
            stopLossLevel = NormalizeDouble(Ask + TrailingStop * Point, Digits);

            // Modify the stop loss level of the short position
            PositionModify(POSITION_SL, stopLossLevel);
        }
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Trail stop loss for long positions
    int longPositionId = 12345; // Replace with the actual position ID
    double longStopLossLevel = 0.0;
    TrailStopLossLong(longPositionId, longStopLossLevel);

    // Trail stop loss for short positions
    int shortPositionId = 54321; // Replace with the actual position ID
    double shortStopLossLevel = 0.0;
    TrailStopLossShort(shortPositionId, shortStopLossLevel);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Clean up any resources here
}

//+------------------------------------------------------------------+